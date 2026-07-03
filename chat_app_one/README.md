# PulseChat

Beautiful real-time human-to-human chat built with Flutter + WebSocket.

## Features

- Join rooms with a display name
- Real-time messaging
- Typing indicators
- Online/offline connection status
- Automatic reconnection with exponential backoff
- Light / dark theme
- Duplicate message prevention

## Run

1. Start the shared backend:

```bash
cd ../websocket_server
npm install
npm start
```

2. Bootstrap platform folders (first time only):

```bash
cd ../chat_app_one
flutter create . --project-name chat_app_one
flutter pub get
```

3. Run the app:

```bash
# iOS Simulator / desktop / macOS
flutter run

# Android Emulator (default URL is already ws://10.0.2.2:8080)
flutter run

# Physical device — pass your computer's LAN IP
flutter run --dart-define=WS_URL=ws://192.168.1.10:8080
```

## Demo

1. Open PulseChat
2. Enter username `Manya`
3. Join room `general`
4. Open NovaChat AI on another device/emulator
5. Join the same room and chat instantly
