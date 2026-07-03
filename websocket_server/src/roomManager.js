const { randomUUID } = require('crypto');

class RoomManager {
  constructor() {
    this.rooms = new Map();
  }

  createClientMeta() {
    return {
      clientId: randomUUID(),
      username: null,
      roomId: null,
      joinedAt: null,
    };
  }

  join(ws, username, roomId) {
    this.leave(ws, { silent: true });

    if (!this.rooms.has(roomId)) {
      this.rooms.set(roomId, new Set());
    }

    this.rooms.get(roomId).add(ws);
    ws.meta.username = username;
    ws.meta.roomId = roomId;
    ws.meta.joinedAt = new Date().toISOString();

    return this.getOnlineCount(roomId);
  }

  leave(ws, { silent = false } = {}) {
    const { roomId, username } = ws.meta || {};

    if (!roomId || !this.rooms.has(roomId)) {
      if (ws.meta) {
        ws.meta.username = null;
        ws.meta.roomId = null;
        ws.meta.joinedAt = null;
      }
      return { roomId: null, username: null, onlineCount: 0, silent };
    }

    const room = this.rooms.get(roomId);
    room.delete(ws);

    if (room.size === 0) {
      this.rooms.delete(roomId);
    }

    ws.meta.username = null;
    ws.meta.roomId = null;
    ws.meta.joinedAt = null;

    return {
      roomId,
      username,
      onlineCount: this.getOnlineCount(roomId),
      silent,
    };
  }

  getOnlineCount(roomId) {
    return this.rooms.get(roomId)?.size || 0;
  }

  broadcast(roomId, payload, { exclude } = {}) {
    const room = this.rooms.get(roomId);
    if (!room) return;

    const data = JSON.stringify(payload);
    for (const client of room) {
      if (client !== exclude && client.readyState === 1) {
        client.send(data);
      }
    }
  }

  send(ws, payload) {
    if (ws.readyState === 1) {
      ws.send(JSON.stringify(payload));
    }
  }
}

module.exports = { RoomManager };
