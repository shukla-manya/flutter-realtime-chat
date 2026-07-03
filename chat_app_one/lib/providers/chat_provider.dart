import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
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

  Future<bool> join({
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

    await _savePrefs();

    try {
      await _service.connect(username: this.username, roomId: this.roomId);
      isJoining = false;
      notifyListeners();
      return connectionStatus == ConnectionStatus.connected ||
          connectionStatus == ConnectionStatus.connecting ||
          connectionStatus == ConnectionStatus.reconnecting;
    } catch (_) {
      errorMessage = 'Could not connect';
      isJoining = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> leaveRoom() async {
    _typingStopTimer?.cancel();
    if (username.isNotEmpty && roomId.isNotEmpty) {
      _service.sendTyping(
        roomId: roomId,
        username: username,
        isTyping: false,
      );
    }
    await _service.disconnect();
    messages.clear();
    typingUsers.clear();
    onlineCount = 0;
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
    if (username.isEmpty || roomId.isEmpty) return;
    _service.sendTyping(
      roomId: roomId,
      username: username,
      isTyping: false,
    );
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
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
      case 'error':
        errorMessage = event['message']?.toString() ?? 'Something went wrong';
        notifyListeners();
        break;
    }
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
    _eventSub?.cancel();
    _statusSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
