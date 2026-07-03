# PulseChat

Realtime chat app by MS. Connects to the shared WebSocket server in `../websocket_server`.

## Run

```bash
cd ../websocket_server && npm start

cd ../chat_app_one
flutter create . --project-name chat_app_one
flutter pub get
flutter run
```

## WebSocket URL

| Target | URL |
|---|---|
| Android Emulator | `ws://10.0.2.2:8080` |
| iOS Simulator | `ws://127.0.0.1:8080` |
| Flutter Web | `ws://localhost:8080` |
| Physical device | `ws://YOUR_COMPUTER_LOCAL_IP:8080` |

```bash
flutter run --dart-define=WS_URL=ws://192.168.1.10:8080
```

## Author

MANYA SHUKLA

2026
