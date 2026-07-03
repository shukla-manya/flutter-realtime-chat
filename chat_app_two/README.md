# NovaChat AI

Realtime chat with AI tools, by MS.

Normal chat still uses WebSocket. AI features go through the shared backend so the Groq API key never ships in the Flutter app.

## AI features

- Smart replies
- Rewrite professionally / friendly / concise
- Summarize conversation
- `/ai <question>` command
- Distinct AI message bubbles

## Run

1. Start the shared backend and configure Groq:

```bash
cd ../websocket_server
cp .env.example .env
npm install
npm start
```

2. Bootstrap platform folders (first time only):

```bash
cd ../chat_app_two
flutter create . --project-name chat_app_two
flutter pub get
```

3. Run:

```bash
flutter run

flutter run --dart-define=WS_URL=ws://192.168.1.10:8080
```

## Demo tips

- Join room `general` to talk with PulseChat
- Tap the sparkle button for AI tools
- Send `/ai Explain WebSocket in one sentence`
