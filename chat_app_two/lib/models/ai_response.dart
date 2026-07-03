class AiResponse {
  const AiResponse({
    required this.action,
    required this.requestId,
    this.content,
    this.suggestions = const [],
    this.timestamp,
  });

  final String action;
  final String requestId;
  final String? content;
  final List<String> suggestions;
  final DateTime? timestamp;

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    final suggestions = <String>[];
    final raw = json['suggestions'];
    if (raw is List) {
      for (final item in raw) {
        final text = item?.toString().trim() ?? '';
        if (text.isNotEmpty) suggestions.add(text);
      }
    }

    return AiResponse(
      action: json['action']?.toString() ?? '',
      requestId: json['requestId']?.toString() ?? '',
      content: json['content']?.toString(),
      suggestions: suggestions,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
    );
  }
}

enum AiAction {
  smartReply('smart_reply', 'Smart replies'),
  rewriteProfessional('rewrite_professional', 'Rewrite professionally'),
  rewriteFriendly('rewrite_friendly', 'Rewrite friendly'),
  makeConcise('make_concise', 'Make concise'),
  summarize('summarize', 'Summarize this chat'),
  ask('ask', 'Ask AI');

  const AiAction(this.wireValue, this.label);
  final String wireValue;
  final String label;
}
