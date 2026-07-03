# Realtime Chat WebSocket Server

Shared backend for PulseChat and NovaChat AI.

## Setup

```bash
cd websocket_server
cp .env.example .env
npm install
npm start
```

Configure Groq in `.env` only:

```env
PORT=8080
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL=your_supported_groq_model_here
```

Never put `GROQ_API_KEY` in Flutter apps.

## Protocol

Chat: `join`, `message`, `typing`, `presence`, `system`, `error`, `leave`

AI: `ai_request` → private `ai_response` (or room `message` with `isAi: true` for `/ai` commands)

`/ai <question>` broadcasts the user message, then one room AI message (`isAi: true`). No private `ai_response` for that path, so clients do not render the answer twice.

## Author

MANYA SHUKLA

2026
