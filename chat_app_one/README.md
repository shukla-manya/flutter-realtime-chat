# PulseChat

Realtime chat app by MS.

## Features

- Join rooms with a display name
- Real-time messaging
- Typing indicators
- Online / offline connection status
- Automatic reconnection
- Light / dark theme

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
flutter run

flutter run --dart-define=WS_URL=ws://192.168.1.10:8080
```

## Demo

1. Open PulseChat
2. Enter username `Manya`
3. Join room `general`
4. Open NovaChat AI on another device/emulator
5. Join the same room and chat
