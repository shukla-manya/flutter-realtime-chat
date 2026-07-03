const http = require('http');
const express = require('express');
const cors = require('cors');
const { WebSocketServer } = require('ws');
const { config } = require('./config');
const { RoomManager } = require('./roomManager');
const { handleMessage, handleDisconnect } = require('./messageHandler');

const app = express();
app.use(cors());
app.use(express.json({ limit: '32kb' }));

app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'realtime-chat-server',
  });
});

const server = http.createServer(app);
const wss = new WebSocketServer({ server });
const roomManager = new RoomManager();

wss.on('connection', (ws) => {
  ws.meta = roomManager.createClientMeta();
  ws.isAlive = true;

  roomManager.send(ws, {
    type: 'system',
    content: 'Connected',
    timestamp: new Date().toISOString(),
  });

  ws.on('pong', () => {
    ws.isAlive = true;
  });

  ws.on('message', (data) => {
    handleMessage(roomManager, ws, data.toString());
  });

  ws.on('close', () => {
    handleDisconnect(roomManager, ws);
  });

  ws.on('error', () => {
    handleDisconnect(roomManager, ws);
  });
});

const heartbeat = setInterval(() => {
  for (const ws of wss.clients) {
    if (!ws.isAlive) {
      ws.terminate();
      continue;
    }
    ws.isAlive = false;
    ws.ping();
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
    config.groqApiKey && config.groqApiKey !== 'your_groq_api_key_here'
      ? 'Groq API key: configured'
      : 'Groq API key: missing (AI features disabled until set in .env)',
  );
});
