import '../constants/app_constants.dart';

class Validators {
  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Display name is required';
    if (text.length > AppConstants.maxUsernameLength) {
      return 'Max ${AppConstants.maxUsernameLength} characters';
    }
    return null;
  }

  static String? roomId(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Room ID is required';
    if (text.length > AppConstants.maxRoomIdLength) {
      return 'Max ${AppConstants.maxRoomIdLength} characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(text)) {
      return 'Use letters, numbers, _ or -';
    }
    return null;
  }
}
