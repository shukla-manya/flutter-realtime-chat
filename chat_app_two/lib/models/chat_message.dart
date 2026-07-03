enum MessageKind { chat, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isAi = false,
    this.kind = MessageKind.chat,
  });

  final String id;
  final String roomId;
  final String sender;
  final String content;
  final DateTime timestamp;
  final bool isAi;
  final MessageKind kind;

  bool get isSystem => kind == MessageKind.system;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type']?.toString();
    final isSystem = type == 'system';

    return ChatMessage(
      id: json['id']?.toString() ??
          'sys-${json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch}',
      roomId: json['roomId']?.toString() ?? '',
      sender: isSystem ? 'System' : (json['sender']?.toString() ?? 'Unknown'),
      content: json['content']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      isAi: json['isAi'] == true,
      kind: isSystem ? MessageKind.system : MessageKind.chat,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'message',
      'id': id,
      'roomId': roomId,
      'sender': sender,
      'content': content,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'isAi': isAi,
    };
  }
}
