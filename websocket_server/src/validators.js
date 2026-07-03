const { config } = require('./config');

const ROOM_ID_PATTERN = /^[a-zA-Z0-9_-]+$/;

function isNonEmptyString(value, maxLength) {
  return (
    typeof value === 'string' &&
    value.trim().length > 0 &&
    value.trim().length <= maxLength
  );
}

function sanitizeText(value) {
  return String(value)
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, '')
    .trim();
}

function validateJoin(payload) {
  if (!isNonEmptyString(payload.username, config.limits.usernameMax)) {
    return 'Username is required and must be 1–24 characters';
  }
  if (!isNonEmptyString(payload.roomId, config.limits.roomIdMax)) {
    return 'Room ID is required and must be 1–32 characters';
  }
  if (!ROOM_ID_PATTERN.test(payload.roomId)) {
    return 'Room ID may only contain letters, numbers, _ or -';
  }
  return null;
}

function validateMessage(payload) {
  if (!isNonEmptyString(payload.id, config.limits.messageIdMax)) {
    return 'Message id is required';
  }
  if (!isNonEmptyString(payload.roomId, config.limits.roomIdMax)) {
    return 'Room ID is required';
  }
  if (!ROOM_ID_PATTERN.test(payload.roomId)) {
    return 'Room ID may only contain letters, numbers, _ or -';
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
  if (!ROOM_ID_PATTERN.test(payload.roomId)) {
    return 'Room ID may only contain letters, numbers, _ or -';
  }
  if (!isNonEmptyString(payload.username, config.limits.usernameMax)) {
    return 'Username is required';
  }
  if (typeof payload.isTyping !== 'boolean') {
    return 'isTyping must be a boolean';
  }
  return null;
}

module.exports = {
  sanitizeText,
  validateJoin,
  validateMessage,
  validateTyping,
};
