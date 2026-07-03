const { config } = require('./config');

function isNonEmptyString(value, maxLength) {
  return typeof value === 'string' && value.trim().length > 0 && value.trim().length <= maxLength;
}

function sanitizeText(value) {
  return String(value).replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, '').trim();
}

function validateJoin(payload) {
  if (!isNonEmptyString(payload.username, config.limits.usernameMax)) {
    return 'Username is required and must be 1–24 characters';
  }
  if (!isNonEmptyString(payload.roomId, config.limits.roomIdMax)) {
    return 'Room ID is required and must be 1–32 characters';
  }
  return null;
}

function validateMessage(payload) {
  if (!isNonEmptyString(payload.id, 80)) {
    return 'Message id is required';
  }
  if (!isNonEmptyString(payload.roomId, config.limits.roomIdMax)) {
    return 'Room ID is required';
  }
  if (!isNonEmptyString(payload.sender, config.limits.usernameMax)) {
    return 'Sender is required';
  }
  if (!isNonEmptyString(payload.content, config.limits.messageMax)) {
    return 'Message content is required and must be 1–1000 characters';
  }
  return null;
}

function validateTyping(payload) {
  if (!isNonEmptyString(payload.roomId, config.limits.roomIdMax)) {
    return 'Room ID is required';
  }
  if (!isNonEmptyString(payload.username, config.limits.usernameMax)) {
    return 'Username is required';
  }
  if (typeof payload.isTyping !== 'boolean') {
    return 'isTyping must be a boolean';
  }
  return null;
}

const AI_ACTIONS = new Set([
  'ask',
  'smart_reply',
  'rewrite_professional',
  'rewrite_friendly',
  'make_concise',
  'summarize',
]);

function validateAiRequest(payload) {
  if (!AI_ACTIONS.has(payload.action)) {
    return 'Unsupported AI action';
  }
  if (!isNonEmptyString(payload.requestId, 80)) {
    return 'requestId is required';
  }
  if (!isNonEmptyString(payload.roomId, config.limits.roomIdMax)) {
    return 'Room ID is required';
  }
  if (!isNonEmptyString(payload.username, config.limits.usernameMax)) {
    return 'Username is required';
  }

  if (payload.action === 'summarize') {
    if (!Array.isArray(payload.messages)) {
      return 'messages array is required for summarize';
    }
    if (payload.messages.length === 0) {
      return 'At least one message is required to summarize';
    }
    return null;
  }

  if (!isNonEmptyString(payload.content, config.limits.aiContentMax)) {
    return 'AI content is required and must be 1–2000 characters';
  }
  return null;
}

module.exports = {
  sanitizeText,
  validateJoin,
  validateMessage,
  validateTyping,
  validateAiRequest,
  AI_ACTIONS,
};
