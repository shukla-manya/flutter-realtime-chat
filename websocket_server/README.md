# Realtime Chat WebSocket Server

Shared backend for PulseChat and NovaChat AI.

## Setup

```bash
cd websocket_server
cp .env.example .env
npm install
npm start
```

- HTTP: `http://localhost:8080`
- WebSocket: `ws://localhost:8080`
- Health: `GET /health`

## Protocol

`join`, `message`, `typing`, `presence`, `system`, `error`, `leave`

## Author

MANYA SHUKLA

2026
