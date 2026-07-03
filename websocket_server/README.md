# Realtime Chat WebSocket Server

Shared Node.js backend for **PulseChat** and **NovaChat AI**.

## Features

- WebSocket rooms with in-memory presence
- Chat message broadcast
- Typing indicators
- System join/leave events
- Groq-powered AI actions (server-side only)
- Health check endpoint

## Setup

```bash
cd websocket_server
cp .env.example .env
# Edit .env and set GROQ_API_KEY + GROQ_MODEL
npm install
npm start
```

Server starts on `http://localhost:8080` and `ws://localhost:8080`.

## Environment

| Variable | Description |
|---|---|
| `PORT` | HTTP/WebSocket port (default `8080`) |
| `GROQ_API_KEY` | Groq API key (never commit) |
| `GROQ_MODEL` | Configurable Groq model id |
| `GROQ_TIMEOUT_MS` | Upstream timeout (default `20000`) |

## Endpoints

- `GET /health` → `{ "status": "ok", "service": "realtime-chat-server" }`
- `ws://localhost:8080` → WebSocket protocol

## AI actions

`ask`, `smart_reply`, `rewrite_professional`, `rewrite_friendly`, `make_concise`, `summarize`

AI requests arrive as WebSocket `ai_request` messages. The API key never leaves this server.
