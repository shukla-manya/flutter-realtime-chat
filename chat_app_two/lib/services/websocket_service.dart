import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/connection_status.dart';

typedef JsonMap = Map<String, dynamic>;

class WebSocketService {
  WebSocketService({required this.url});

  final String url;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  final _eventController = StreamController<JsonMap>.broadcast();
  final _statusController =
      StreamController<ConnectionStatus>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  bool _disposed = false;
  bool _manualDisconnect = false;
  bool _connecting = false;
  int _reconnectAttempt = 0;

  String? _pendingUsername;
  String? _pendingRoomId;

  Stream<JsonMap> get events => _eventController.stream;
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  ConnectionStatus get status => _status;
  bool get isConnected => _status == ConnectionStatus.connected;

  Future<void> connect({
    required String username,
    required String roomId,
  }) async {
    if (_disposed) return;

    _pendingUsername = username;
    _pendingRoomId = roomId;
    _manualDisconnect = false;
    await _openSocket(isReconnect: false);
  }

  Future<void> _openSocket({required bool isReconnect}) async {
    if (_disposed || _connecting) return;
    _connecting = true;

    _setStatus(
      isReconnect
          ? ConnectionStatus.reconnecting
          : ConnectionStatus.connecting,
    );

    await _cleanupSocket(resetStatus: false);

    try {
      final uri = Uri.parse(url);
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;

      await channel.ready.timeout(const Duration(seconds: 8));

      if (_disposed || _manualDisconnect) {
        await channel.sink.close(ws_status.normalClosure);
        return;
      }

      _subscription = channel.stream.listen(
        _onData,
        onError: (_) => _onUnexpectedClose(),
        onDone: _onUnexpectedClose,
        cancelOnError: true,
      );

      _reconnectAttempt = 0;
      _setStatus(ConnectionStatus.connected);

      if (_pendingUsername != null && _pendingRoomId != null) {
        joinRoom(
          username: _pendingUsername!,
          roomId: _pendingRoomId!,
        );
      }
    } catch (_) {
      _setStatus(ConnectionStatus.error);
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _onData(dynamic data) {
    try {
      final decoded = jsonDecode(data.toString());
      if (decoded is Map<String, dynamic>) {
        _eventController.add(decoded);
      } else if (decoded is Map) {
        _eventController.add(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  void _onUnexpectedClose() {
    if (_disposed || _manualDisconnect) return;
    _setStatus(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _manualDisconnect) return;
    if (_reconnectAttempt >= 6) {
      _setStatus(ConnectionStatus.error);
      return;
    }

    _reconnectTimer?.cancel();
    final delayMs = (500 * (1 << _reconnectAttempt)).clamp(500, 8000);
    _reconnectAttempt += 1;
    _setStatus(ConnectionStatus.reconnecting);

    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
      _openSocket(isReconnect: true);
    });
  }

  void joinRoom({required String username, required String roomId}) {
    _pendingUsername = username;
    _pendingRoomId = roomId;
    sendJson({
      'type': 'join',
      'username': username,
      'roomId': roomId,
    });
  }

  void leaveRoom() {
    sendJson({'type': 'leave'});
  }

  void sendMessage({
    required String id,
    required String roomId,
    required String sender,
    required String content,
    required String timestamp,
  }) {
    sendJson({
      'type': 'message',
      'id': id,
      'roomId': roomId,
      'sender': sender,
      'content': content,
      'timestamp': timestamp,
    });
  }

  void sendTyping({
    required String roomId,
    required String username,
    required bool isTyping,
  }) {
    sendJson({
      'type': 'typing',
      'roomId': roomId,
      'username': username,
      'isTyping': isTyping,
    });
  }

  void requestAi({
    required String action,
    required String requestId,
    required String roomId,
    required String username,
    String? content,
    List<Map<String, String>>? messages,
  }) {
    final payload = <String, dynamic>{
      'type': 'ai_request',
      'action': action,
      'requestId': requestId,
      'roomId': roomId,
      'username': username,
    };

    if (content != null) payload['content'] = content;
    if (messages != null) payload['messages'] = messages;

    sendJson(payload);
  }

  void sendJson(JsonMap payload) {
    if (_disposed || !isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    leaveRoom();
    await _cleanupSocket(resetStatus: true);
  }

  Future<void> _cleanupSocket({required bool resetStatus}) async {
    await _subscription?.cancel();
    _subscription = null;

    try {
      await _channel?.sink.close(ws_status.normalClosure);
    } catch (_) {}
    _channel = null;

    if (resetStatus) {
      _setStatus(ConnectionStatus.disconnected);
    }
  }

  void _setStatus(ConnectionStatus status) {
    if (_status == status) return;
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    await _cleanupSocket(resetStatus: true);
    await _eventController.close();
    await _statusController.close();
  }
}
