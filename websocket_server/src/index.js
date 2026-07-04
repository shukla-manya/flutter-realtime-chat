const http = require('http');
const express = require('express');
const cors = require('cors');
const { WebSocketServer } = require('ws');
const { config } = require('./config');
const { RoomManager } = require('./roomManager');
const { handleMessage, handleDisconnect } = require('./messageHandler');
const { isKeyConfigured } = require('./groqService');

const app = express();
app.use(cors());
app.use(express.json({ limit: '32kb' }));

app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'realtime-chat-server',
  });
});

app.get('/', (_req, res) => {
  res.type('html').send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Realtime Chat Server | MS</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: "Segoe UI", system-ui, -apple-system, sans-serif;
      background: linear-gradient(145deg, #0B1020 0%, #151B2E 50%, #1a1040 100%);
      color: #F8FAFC;
      padding: 24px;
    }
    .card {
      width: min(440px, 100%);
      text-align: center;
      padding: 40px 28px;
      border-radius: 24px;
      background: rgba(23, 29, 46, 0.9);
      border: 1px solid rgba(168, 85, 247, 0.25);
      box-shadow: 0 20px 50px rgba(0, 0, 0, 0.35);
    }
    .mark {
      width: 64px;
      height: 64px;
      margin: 0 auto 20px;
      border-radius: 18px;
      display: grid;
      place-items: center;
      font-weight: 800;
      font-size: 22px;
      letter-spacing: 1px;
      color: #fff;
      background: linear-gradient(135deg, #5B5FEF, #8B5CF6, #06B6D4);
    }
    h1 {
      font-size: 1.4rem;
      font-weight: 700;
      margin-bottom: 8px;
    }
    p {
      color: #94A3B8;
      font-size: 0.95rem;
      line-height: 1.5;
      margin-bottom: 20px;
    }
    .love {
      font-size: 0.95rem;
      color: #E2E8F0;
      font-weight: 500;
    }
    .love span { color: #F472B6; }
    .meta {
      margin-top: 18px;
      font-size: 0.8rem;
      color: #64748B;
    }
  </style>
</head>
<body>
  <main class="card">
    <div class="mark">MS</div>
    <h1>Realtime Chat Server</h1>
    <p>Shared WebSocket backend for PulseChat and NovaChat AI.</p>
    <p class="love">Made with <span>♥</span> by Manya Shukla</p>
    <p class="meta">by MANYA SHUKLA 2026</p>
  </main>
</body>
</html>`);
});


const server = http.createServer(app);
const wss = new WebSocketServer({ server });
const roomManager = new RoomManager();

wss.on('connection', (ws) => {
  ws.meta = roomManager.createClientMeta();
  ws.isAlive = true;

  ws.on('pong', () => {
    ws.isAlive = true;
  });

  ws.on('message', (data) => {
    try {
      handleMessage(roomManager, ws, data.toString());
    } catch (_) {
      roomManager.send(ws, {
        type: 'error',
        code: 'SERVER_ERROR',
        message: 'Unable to process message',
      });
    }
  });

  ws.on('close', () => {
    handleDisconnect(roomManager, ws);
  });

  ws.on('error', () => {
    handleDisconnect(roomManager, ws);
  });
});

const heartbeat = setInterval(() => {
  for (const client of wss.clients) {
    if (!client.isAlive) {
      client.terminate();
      continue;
    }
    client.isAlive = false;
    client.ping();
  }
}, 30000);

wss.on('close', () => {
  clearInterval(heartbeat);
});

server.listen(config.port, () => {
  console.log(`Realtime chat server listening on http://localhost:${config.port}`);
  console.log(`WebSocket endpoint: ws://localhost:${config.port}`);
  console.log(`Groq model: ${config.groqModel}`);
  console.log(
    isKeyConfigured()
      ? 'Groq API key: configured'
      : 'Groq API key: missing (AI features return AI_NOT_CONFIGURED)',
  );
});
