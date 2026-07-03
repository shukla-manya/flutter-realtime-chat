const { randomUUID } = require('crypto');
const {
  sanitizeText,
  validateJoin,
  validateMessage,
  validateTyping,
  validateAiRequest,
} = require('./validators');
const { aiRateLimiter } = require('./rateLimiter');
const { handleAiAction } = require('./groqService');

const AI_DELIVERY = {
  PRIVATE_RESPONSE: 'private_response',
  ROOM_AI_MESSAGE: 'room_ai_message',
};

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

  if (message.content.startsWith('/ai ')) {
    const question = sanitizeText(message.content.slice(4));
    roomManager.broadcast(message.roomId, message);

    if (!question) {
      sendError(roomManager, ws, 'INVALID_AI_REQUEST', 'Usage: /ai <question>');
      return;
    }

    fulfillAiRequest(roomManager, ws, {
      action: 'ask',
      requestId: randomUUID(),
      roomId: message.roomId,
      username: message.sender,
      content: question,
      delivery: AI_DELIVERY.ROOM_AI_MESSAGE,
    });
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

async function fulfillAiRequest(roomManager, ws, options) {
  const action = options.action;
  const requestId = sanitizeText(options.requestId || randomUUID());
  const roomId = sanitizeText(options.roomId || ws.meta?.roomId || '');
  const username = sanitizeText(options.username || ws.meta?.username || '');
  const content = sanitizeText(options.content || '');
  const delivery = options.delivery || AI_DELIVERY.PRIVATE_RESPONSE;
  const messages = Array.isArray(options.messages)
    ? options.messages.slice(-40).map((m) => ({
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

  if (!ws.meta?.roomId || ws.meta.roomId !== roomId) {
    sendError(roomManager, ws, 'NOT_JOINED', 'Join a room before using AI features');
    return;
  }

  if (!aiRateLimiter.allow(ws.meta.clientId)) {
    sendError(roomManager, ws, 'AI_RATE_LIMIT', 'Too many AI requests. Please wait a moment.');
    return;
  }

  try {
    const result = await handleAiAction({ action, content, messages });

    if (delivery === AI_DELIVERY.ROOM_AI_MESSAGE) {
      roomManager.broadcast(roomId, {
        type: 'message',
        id: randomUUID(),
        roomId,
        sender: 'Nova AI',
        content: result.content,
        timestamp: nowIso(),
        isAi: true,
      });
      return;
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

function handleAiRequest(roomManager, ws, payload) {
  fulfillAiRequest(roomManager, ws, {
    action: payload.action,
    requestId: payload.requestId,
    roomId: payload.roomId,
    username: payload.username,
    content: payload.content,
    messages: payload.messages,
    delivery: AI_DELIVERY.PRIVATE_RESPONSE,
  });
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
      case 'ai_request':
        handleAiRequest(roomManager, ws, payload);
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
  aiRateLimiter.clear(ws.meta?.clientId);
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
  AI_DELIVERY,
};
