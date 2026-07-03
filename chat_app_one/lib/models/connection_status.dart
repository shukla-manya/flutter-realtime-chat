enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

extension ConnectionStatusX on ConnectionStatus {
  String get label {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'Offline';
      case ConnectionStatus.connecting:
        return 'Connecting';
      case ConnectionStatus.connected:
        return 'Online';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting';
      case ConnectionStatus.error:
        return 'Connection error';
    }
  }

  bool get isOnline => this == ConnectionStatus.connected;
}
