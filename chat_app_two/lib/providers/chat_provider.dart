import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../models/ai_response.dart';
import '../models/chat_message.dart';
import '../models/connection_status.dart';
import '../services/websocket_service.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({WebSocketService? service})
      : _service = service ?? WebSocketService(url: AppConfig.websocketUrl) {
    _eventSub = _service.events.listen(_onEvent);
    _statusSub = _service.statusStream.listen((status) {
      connectionStatus = status;
      notifyListeners();
    });
    _loadPrefs();
  }

  final WebSocketService _service;
  final _uuid = const Uuid();

  StreamSubscription? _eventSub;
  StreamSubscription? _statusSub;
  Timer? _typingStopTimer;
  Timer? _aiTimeoutTimer;
  Completer<AiResponse>? _aiCompleter;
  String? _pendingAiRequestId;

  final List<ChatMessage> messages = [];
  final Set<String> _seenMessageIds = {};
  final Set<String> typingUsers = {};

  ConnectionStatus connectionStatus = ConnectionStatus.disconnected;
  String username = '';
  String roomId = AppConstants.defaultRoomId;
  int onlineCount = 0;
  bool isJoining = false;
  bool isSending = false;
  String? errorMessage;

  bool isAiLoading = false;
  AiAction? activeAiAction;
  List<String> smartReplies = [];
  String? summaryResult;
  String? rewriteResult;
  String? aiError;

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username') ?? '';
    roomId = prefs.getString('roomId') ?? AppConstants.defaultRoomId;
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('roomId', roomId);
  }

  Future<void> join({
    required String username,
    required String roomId,
  }) async {
    errorMessage = null;
    isJoining = true;
    notifyListeners();

    this.username = username.trim();
    this.roomId = roomId.trim();
    messages.clear();
    _seenMessageIds.clear();
    typingUsers.clear();
    onlineCount = 0;
    _resetAiState();

    await _savePrefs();

    try {
      await _service.connect(username: this.username, roomId: this.roomId);
    } catch (_) {
      errorMessage = 'Unable to connect to chat server';
    } finally {
      isJoining = false;
      notifyListeners();
    }
  }

  Future<void> leaveRoom() async {
    _typingStopTimer?.cancel();
    _aiTimeoutTimer?.cancel();
    _service.sendTyping(
      roomId: roomId,
      username: username,
      isTyping: false,
    );
    await _service.disconnect();
    messages.clear();
    typingUsers.clear();
    onlineCount = 0;
    _resetAiState();
    notifyListeners();
  }

  void sendMessage(String content) {
    final text = content.trim();
    if (text.isEmpty || !connectionStatus.isOnline) return;

    isSending = true;
    notifyListeners();

    final message = ChatMessage(
      id: _uuid.v4(),
      roomId: roomId,
      sender: username,
      content: text,
      timestamp: DateTime.now().toUtc(),
    );

    _addMessage(message);
    _service.sendMessage(
      id: message.id,
      roomId: message.roomId,
      sender: message.sender,
      content: message.content,
      timestamp: message.timestamp.toIso8601String(),
    );

    stopTyping();
    isSending = false;
    notifyListeners();
  }

  void onComposerChanged(String value) {
    if (!connectionStatus.isOnline || username.isEmpty) return;

    if (value.trim().isEmpty) {
      stopTyping();
      return;
    }

    _service.sendTyping(
      roomId: roomId,
      username: username,
      isTyping: true,
    );

    _typingStopTimer?.cancel();
    _typingStopTimer = Timer(
      const Duration(milliseconds: AppConstants.typingIdleMs),
      stopTyping,
    );
  }

  void stopTyping() {
    _typingStopTimer?.cancel();
    if (username.isEmpty) return;
    _service.sendTyping(
      roomId: roomId,
      username: username,
      isTyping: false,
    );
  }

  Future<AiResponse?> requestAiAction({
    required AiAction action,
    String? content,
  }) async {
    if (!connectionStatus.isOnline) {
      aiError = 'Connect to chat before using AI features';
      notifyListeners();
      return null;
    }

    if (action == AiAction.summarize && messages.where((m) => !m.isSystem).isEmpty) {
      aiError = 'No messages to summarize yet';
      notifyListeners();
      return null;
    }

    if (action != AiAction.summarize &&
        action != AiAction.smartReply &&
        (content == null || content.trim().isEmpty)) {
      aiError = 'Write a message first';
      notifyListeners();
      return null;
    }

    if (action == AiAction.smartReply) {
      ChatMessage? latestOther;
      ChatMessage? latestAny;
      for (final message in messages.reversed) {
        if (message.isSystem) continue;
        latestAny ??= message;
        if (message.sender != username) {
          latestOther = message;
          break;
        }
      }
      final source = latestOther ?? latestAny;
      if (source == null || source.content.isEmpty) {
        aiError = 'Need at least one message for smart replies';
        notifyListeners();
        return null;
      }
      content = source.content;
    }

    isAiLoading = true;
    activeAiAction = action;
    aiError = null;
    if (action == AiAction.smartReply) smartReplies = [];
    if (action == AiAction.summarize) summaryResult = null;
    if (action == AiAction.rewriteProfessional ||
        action == AiAction.rewriteFriendly ||
        action == AiAction.makeConcise) {
      rewriteResult = null;
    }
    notifyListeners();

    final requestId = _uuid.v4();
    _pendingAiRequestId = requestId;
    _aiCompleter = Completer<AiResponse>();

    final recentMessages = messages
        .where((m) => !m.isSystem)
        .map((m) => {'sender': m.sender, 'content': m.content})
        .toList();

    _service.requestAi(
      action: action.wireValue,
      requestId: requestId,
      roomId: roomId,
      username: username,
      content: content,
      messages: action == AiAction.summarize ? recentMessages : null,
    );

    _aiTimeoutTimer?.cancel();
    _aiTimeoutTimer = Timer(AppConstants.aiTimeout, () {
      if (_aiCompleter != null && !(_aiCompleter!.isCompleted)) {
        aiError = 'AI request timed out';
        isAiLoading = false;
        activeAiAction = null;
        notifyListeners();
        _aiCompleter!.completeError(TimeoutException('AI timeout'));
      }
    });

    try {
      final response = await _aiCompleter!.future;
      return response;
    } catch (_) {
      return null;
    } finally {
      _aiTimeoutTimer?.cancel();
      isAiLoading = false;
      activeAiAction = null;
      _pendingAiRequestId = null;
      _aiCompleter = null;
      notifyListeners();
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  void clearAiError() {
    aiError = null;
    notifyListeners();
  }

  void _resetAiState() {
    isAiLoading = false;
    activeAiAction = null;
    smartReplies = [];
    summaryResult = null;
    rewriteResult = null;
    aiError = null;
    _aiTimeoutTimer?.cancel();
    if (_aiCompleter != null && !_aiCompleter!.isCompleted) {
      _aiCompleter!.completeError(StateError('cancelled'));
    }
    _aiCompleter = null;
    _pendingAiRequestId = null;
  }

  void _onEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString();

    switch (type) {
      case 'message':
      case 'system':
        _addMessage(ChatMessage.fromJson(event));
        break;
      case 'typing':
        final user = event['username']?.toString() ?? '';
        final isTyping = event['isTyping'] == true;
        if (user.isEmpty || user == username) return;
        if (isTyping) {
          typingUsers.add(user);
        } else {
          typingUsers.remove(user);
        }
        notifyListeners();
        break;
      case 'presence':
        onlineCount = (event['onlineCount'] as num?)?.toInt() ?? onlineCount;
        notifyListeners();
        break;
      case 'ai_response':
        _handleAiResponse(AiResponse.fromJson(event));
        break;
      case 'error':
        final code = event['code']?.toString() ?? '';
        final message = event['message']?.toString() ?? 'Something went wrong';
        if (code.startsWith('AI_') || code == 'INVALID_AI_REQUEST') {
          aiError = message;
          if (_aiCompleter != null && !_aiCompleter!.isCompleted) {
            _aiCompleter!.completeError(Exception(message));
          }
        } else {
          errorMessage = message;
        }
        notifyListeners();
        break;
    }
  }

  void _handleAiResponse(AiResponse response) {
    if (_pendingAiRequestId != null &&
        response.requestId != _pendingAiRequestId) {
      return;
    }

    switch (response.action) {
      case 'smart_reply':
        smartReplies = response.suggestions;
        break;
      case 'summarize':
        summaryResult = response.content;
        break;
      case 'rewrite_professional':
      case 'rewrite_friendly':
      case 'make_concise':
        rewriteResult = response.content;
        break;
    }

    if (_aiCompleter != null && !_aiCompleter!.isCompleted) {
      _aiCompleter!.complete(response);
    }
    notifyListeners();
  }

  void _addMessage(ChatMessage message) {
    if (_seenMessageIds.contains(message.id)) return;
    _seenMessageIds.add(message.id);
    messages.add(message);
    notifyListeners();
  }

  String get typingLabel {
    if (typingUsers.isEmpty) return '';
    final names = typingUsers.toList();
    if (names.length == 1) return '${names.first} is typing…';
    if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing…';
    }
    return '${names.length} people are typing…';
  }

  @override
  void dispose() {
    _typingStopTimer?.cancel();
    _aiTimeoutTimer?.cancel();
    _eventSub?.cancel();
    _statusSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
