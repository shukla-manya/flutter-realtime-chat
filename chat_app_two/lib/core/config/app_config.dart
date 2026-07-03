import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _envUrl = String.fromEnvironment('WS_URL');

  static String get websocketUrl {
    if (_envUrl.isNotEmpty) return _envUrl;

    if (kIsWeb) return 'ws://localhost:8080';

    if (!kIsWeb && Platform.isAndroid) {
      return 'ws://10.0.2.2:8080';
    }

    return 'ws://127.0.0.1:8080';
  }
}
