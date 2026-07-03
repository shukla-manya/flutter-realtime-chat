const { randomUUID } = require('crypto');
const {
  sanitizeText,
  validateJoin,
  validateMessage,
  validateTyping,
} = require('./validators');

function nowIso() {
  return new Date().toISOString();
}

function sendError(roomManager, ws, code, message) {
  roomManager.send(ws, {
    type: 'error',
    code,
    message,
  });
}

function broadcastPresence(roomManager, roomId) {
  roomManager.broadcast(roomId, {
    type: 'presence',
    roomId,
    onlineCount: roomManager.getOnlineCount(roomId),
  });
}

function handleJoin(roomManager, ws, payload) {
  const username = sanitizeText(payload.username || '');
  const roomId = sanitizeText(payload.roomId || '');
  const error = validateJoin({ username, roomId });

  if (error) {
    sendError(roomManager, ws, 'INVALID_JOIN', error);
    return;
  }

  roomManager.join(ws, username, roomId);

  roomManager.send(ws, {
    type: 'system',
    content: `Joined #${roomId}`,
    timestamp: nowIso(),
  });

  roomManager.broadcast(
    roomId,
    {
      type: 'system',
      content: `${username} joined the room`,
      timestamp: nowIso(),
    },
    { exclude: ws },
  );

  broadcastPresence(roomManager, roomId);
}

function handleLeave(roomManager, ws) {
  const result = roomManager.leave(ws);
  if (!result.roomId || result.silent) return;

  roomManager.broadcast(result.roomId, {
    type: 'system',
    content: `${result.username} left the room`,
    timestamp: nowIso(),
  });
  broadcastPresence(roomManager, result.roomId);
}

function handleChatMessage(roomManager, ws, payload) {
  if (!ws.meta?.roomId) {
    sendError(roomManager, ws, 'NOT_JOINED', 'Join a room before sending messages');
    return;
  }

  const message = {
    type: 'message',
    id: sanitizeText(payload.id || randomUUID()),
    roomId: sanitizeText(payload.roomId || ws.meta.roomId),
    sender: sanitizeText(payload.sender || ws.meta.username || 'Anonymous'),
    content: sanitizeText(payload.content || ''),
    timestamp:
      typeof payload.timestamp === 'string' && payload.timestamp.trim()
        ? payload.timestamp
        : nowIso(),
  };

  const error = validateMessage(message);
  if (error) {
    sendError(roomManager, ws, 'INVALID_MESSAGE', error);
    return;
  }

  if (message.roomId !== ws.meta.roomId) {
    sendError(
      roomManager,
      ws,
      'ROOM_MISMATCH',
      'Message room does not match joined room',
    );
    return;
  }

  if (message.sender !== ws.meta.username) {
    sendError(roomManager, ws, 'SENDER_MISMATCH', 'Sender does not match joined username');
    return;
  }

  roomManager.broadcast(message.roomId, message);
}

function handleTyping(roomManager, ws, payload) {
  if (!ws.meta?.roomId) return;

  const typing = {
    type: 'typing',
    roomId: sanitizeText(payload.roomId || ws.meta.roomId),
    username: sanitizeText(payload.username || ws.meta.username || ''),
    isTyping: Boolean(payload.isTyping),
  };

  const error = validateTyping(typing);
  if (error) {
    sendError(roomManager, ws, 'INVALID_TYPING', error);
    return;
  }

  if (typing.roomId !== ws.meta.roomId) return;
  if (typing.username !== ws.meta.username) return;

  roomManager.broadcast(typing.roomId, typing, { exclude: ws });
}

function handleMessage(roomManager, ws, raw) {
  let payload;

  try {
    payload = JSON.parse(raw);
  } catch (_) {
    sendError(roomManager, ws, 'INVALID_JSON', 'Malformed JSON payload');
    return;
  }

  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    sendError(roomManager, ws, 'INVALID_MESSAGE', 'Message must be a JSON object');
    return;
  }

  if (typeof payload.type !== 'string') {
    sendError(roomManager, ws, 'INVALID_MESSAGE', 'Message type is required');
    return;
  }

  try {
    switch (payload.type) {
      case 'join':
        handleJoin(roomManager, ws, payload);
        break;
      case 'leave':
        handleLeave(roomManager, ws);
        break;
      case 'message':
        handleChatMessage(roomManager, ws, payload);
        break;
      case 'typing':
        handleTyping(roomManager, ws, payload);
        break;
      default:
        sendError(
          roomManager,
          ws,
          'UNKNOWN_TYPE',
          `Unknown message type: ${payload.type}`,
        );
    }
  } catch (_) {
    sendError(roomManager, ws, 'SERVER_ERROR', 'Unable to process message');
  }
}

function handleDisconnect(roomManager, ws) {
  const result = roomManager.leave(ws);
  if (!result.roomId || !result.username) return;

  roomManager.broadcast(result.roomId, {
    type: 'system',
    content: `${result.username} left the room`,
    timestamp: nowIso(),
  });
  broadcastPresence(roomManager, result.roomId);
}

module.exports = {
  handleMessage,
  handleDisconnect,
};
