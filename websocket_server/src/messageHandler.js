const { v4: uuidv4 } = require('uuid');
const {
  sanitizeText,
  validateJoin,
  validateMessage,
  validateTyping,
  validateAiRequest,
} = require('./validators');
const { aiRateLimiter } = require('./rateLimiter');
const { handleAiAction } = require('./groqService');

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
    content: `Welcome to #${roomId}, ${username}!`,
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
  if (!ws.meta.roomId) {
    sendError(roomManager, ws, 'NOT_JOINED', 'Join a room before sending messages');
    return;
  }

  const message = {
    type: 'message',
    id: sanitizeText(payload.id || uuidv4()),
    roomId: sanitizeText(payload.roomId || ws.meta.roomId),
    sender: sanitizeText(payload.sender || ws.meta.username || 'Anonymous'),
    content: sanitizeText(payload.content || ''),
    timestamp: payload.timestamp || nowIso(),
    isAi: false,
  };

  const error = validateMessage(message);
  if (error) {
    sendError(roomManager, ws, 'INVALID_MESSAGE', error);
    return;
  }

  if (message.roomId !== ws.meta.roomId) {
    sendError(roomManager, ws, 'ROOM_MISMATCH', 'Message room does not match joined room');
    return;
  }

  // Detect /ai command and route through AI pipeline while still showing the user question.
  if (message.content.startsWith('/ai ')) {
    const question = sanitizeText(message.content.slice(4));
    roomManager.broadcast(message.roomId, message);

    if (!question) {
      sendError(roomManager, ws, 'INVALID_AI_REQUEST', 'Usage: /ai <question>');
      return;
    }

    processAiRequest(roomManager, ws, {
      type: 'ai_request',
      action: 'ask',
      roomId: message.roomId,
      username: message.sender,
      content: question,
      requestId: uuidv4(),
      broadcastAnswer: true,
    });
    return;
  }

  roomManager.broadcast(message.roomId, message);
}

function handleTyping(roomManager, ws, payload) {
  if (!ws.meta.roomId) return;

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

  roomManager.broadcast(typing.roomId, typing, { exclude: ws });
}

async function processAiRequest(roomManager, ws, payload) {
  const action = payload.action;
  const requestId = sanitizeText(payload.requestId || uuidv4());
  const roomId = sanitizeText(payload.roomId || ws.meta.roomId || '');
  const username = sanitizeText(payload.username || ws.meta.username || '');
  const content = sanitizeText(payload.content || '');
  const messages = Array.isArray(payload.messages)
    ? payload.messages.slice(-40).map((m) => ({
        sender: sanitizeText(m.sender || ''),
        content: sanitizeText(m.content || ''),
      }))
    : [];

  const validationError = validateAiRequest({
    action,
    requestId,
    roomId,
    username,
    content,
    messages,
  });

  if (validationError) {
    sendError(roomManager, ws, 'INVALID_AI_REQUEST', validationError);
    return;
  }

  if (!ws.meta.roomId || ws.meta.roomId !== roomId) {
    sendError(roomManager, ws, 'NOT_JOINED', 'Join a room before using AI features');
    return;
  }

  if (!aiRateLimiter.allow(ws.meta.clientId)) {
    sendError(roomManager, ws, 'AI_RATE_LIMIT', 'Too many AI requests. Please wait a moment.');
    return;
  }

  try {
    const result = await handleAiAction({ action, content, messages });

    if (action === 'ask' && payload.broadcastAnswer) {
      const aiMessage = {
        type: 'message',
        id: uuidv4(),
        roomId,
        sender: 'Nova AI',
        content: result.content,
        timestamp: nowIso(),
        isAi: true,
      };
      roomManager.broadcast(roomId, aiMessage);
    }

    const response = {
      type: 'ai_response',
      action,
      requestId,
      timestamp: nowIso(),
      isAi: true,
    };

    if (action === 'smart_reply') {
      response.suggestions = result.suggestions;
    } else {
      response.content = result.content;
    }

    // Private AI helpers (rewrite/smart_reply/summarize) go only to requester.
    // Broadcast ask answers already went to the room as chat messages.
    roomManager.send(ws, response);
  } catch (err) {
    sendError(
      roomManager,
      ws,
      err.code || 'AI_ERROR',
      err.message || 'AI request failed',
    );
  }
}

function handleMessage(roomManager, ws, raw) {
  let payload;
  try {
    payload = JSON.parse(raw);
  } catch (_) {
    sendError(roomManager, ws, 'INVALID_JSON', 'Malformed JSON payload');
    return;
  }

  if (!payload || typeof payload !== 'object' || typeof payload.type !== 'string') {
    sendError(roomManager, ws, 'INVALID_MESSAGE', 'Message type is required');
    return;
  }

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
    case 'ai_request':
      processAiRequest(roomManager, ws, payload);
      break;
    case 'ping':
      roomManager.send(ws, { type: 'pong', timestamp: nowIso() });
      break;
    default:
      sendError(roomManager, ws, 'UNKNOWN_TYPE', `Unknown message type: ${payload.type}`);
  }
}

function handleDisconnect(roomManager, ws) {
  aiRateLimiter.clear(ws.meta?.clientId);
  const result = roomManager.leave(ws);
  if (!result.roomId) return;

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
