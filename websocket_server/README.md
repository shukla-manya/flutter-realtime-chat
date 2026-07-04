# Realtime Chat WebSocket Server

Shared backend for PulseChat and NovaChat AI.

## Setup

```bash

npm install
npm start
```

```env
PORT=8080
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL=your_supported_groq_model_here
```

Never put `GROQ_API_KEY` in Flutter.

## Docs

- Landing: `/`
- Swagger UI: `/docs` (also `/swagger`)
- OpenAPI JSON: `/openapi.json`

Production:

- https://flutter-realtime-chat.onrender.com/
- https://flutter-realtime-chat.onrender.com/docs
- https://flutter-realtime-chat.onrender.com/openapi.json

## Checks

```bash
curl http://localhost:8080/health
curl http://localhost:8080/openapi.json
npm run audit
```


## Author

MANYA SHUKLA

2026
