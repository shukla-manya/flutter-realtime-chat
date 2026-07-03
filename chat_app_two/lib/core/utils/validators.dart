class Validators {
  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Display name is required';
    if (text.length > 24) return 'Max 24 characters';
    return null;
  }

  static String? roomId(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Room ID is required';
    if (text.length > 32) return 'Max 32 characters';
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(text)) {
      return 'Use letters, numbers, _ or -';
    }
    return null;
  }
}
