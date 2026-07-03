# NovaChat AI

Realtime chat by MS with Groq AI tools. Uses the same WebSocket server as PulseChat.

AI requests go through the backend. The Groq API key never ships in the Flutter app.

## Run

```bash
cd ../websocket_server
cp .env.example .env
# set GROQ_API_KEY and GROQ_MODEL
npm start

cd ../chat_app_two
flutter create . --project-name chat_app_two
flutter pub get
flutter run
```

Join room `general` to chat with PulseChat.

## Author

MANYA SHUKLA

2026
