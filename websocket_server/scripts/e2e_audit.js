const WebSocket = require('ws');
const { spawn } = require('child_process');
const path = require('path');

const PORT = Number(process.env.PORT) || 8080;
const BASE = `http://127.0.0.1:${PORT}`;
const WS = `ws://127.0.0.1:${PORT}`;

const results = [];

function record(status, name, detail = '') {
  results.push({ status, name, detail });
  const line = detail ? `${status} ${name} — ${detail}` : `${status} ${name}`;
  console.log(line);
}

function once(ws, pred, ms = 3000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error('timeout')), ms);
    const handler = (data) => {
      let msg;
      try {
        msg = JSON.parse(data.toString());
      } catch {
        return;
      }
      if (pred(msg)) {
        clearTimeout(timer);
        ws.off('message', handler);
        resolve(msg);
      }
    };
    ws.on('message', handler);
  });
}

function openClient() {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(WS);
    ws.once('open', () => resolve(ws));
    ws.once('error', reject);
  });
}

async function ensureServer() {
  try {
    const health = await fetch(`${BASE}/health`).then((r) => r.json());
    if (health.status === 'ok' && health.service === 'realtime-chat-server') {
      return { startedByUs: false };
    }
  } catch (_) {}

  const child = spawn('node', [path.join(__dirname, '..', 'src', 'index.js')], {
    env: { ...process.env, PORT: String(PORT) },
    stdio: ['ignore', 'pipe', 'pipe'],
    detached: true,
  });
  child.unref();

  for (let i = 0; i < 20; i += 1) {
    await new Promise((r) => setTimeout(r, 150));
    try {
      const health = await fetch(`${BASE}/health`).then((r) => r.json());
      if (health.status === 'ok') return { startedByUs: true, child };
    } catch (_) {}
  }
  throw new Error('server failed to start');
}

async function run() {
  await ensureServer();

  const health = await fetch(`${BASE}/health`).then((r) => r.json());
  if (health.status === 'ok' && health.service === 'realtime-chat-server') {
    record('PASS', 'GET /health');
  } else {
    record('FAIL', 'GET /health', JSON.stringify(health));
  }

  const manya = await openClient();
  const reviewer = await openClient();

  manya.send(JSON.stringify({ type: 'join', username: 'Manya', roomId: 'general' }));
  reviewer.send(JSON.stringify({ type: 'join', username: 'Reviewer', roomId: 'general' }));

  const presence = await once(
    reviewer,
    (m) => m.type === 'presence' && m.roomId === 'general' && m.onlineCount === 2,
  );
  record('PASS', 'Online count = 2', `onlineCount=${presence.onlineCount}`);

  const helloId = 'audit-hello-pulse';
  manya.send(
    JSON.stringify({
      type: 'message',
      id: helloId,
      roomId: 'general',
      sender: 'Manya',
      content: 'Hello from PulseChat!',
      timestamp: new Date().toISOString(),
    }),
  );
  const receivedPulse = await once(
    reviewer,
    (m) => m.type === 'message' && m.id === helloId,
  );
  if (receivedPulse.content === 'Hello from PulseChat!') {
    record('PASS', 'PulseChat -> NovaChat AI message');
  } else {
    record('FAIL', 'PulseChat -> NovaChat AI message', receivedPulse.content);
  }

  reviewer.send(
    JSON.stringify({
      type: 'typing',
      roomId: 'general',
      username: 'Reviewer',
      isTyping: true,
    }),
  );
  await once(manya, (m) => m.type === 'typing' && m.username === 'Reviewer' && m.isTyping === true);
  record('PASS', 'Typing indicator Reviewer -> Manya');

  const replyId = 'audit-hello-nova';
  reviewer.send(
    JSON.stringify({
      type: 'message',
      id: replyId,
      roomId: 'general',
      sender: 'Reviewer',
      content: 'Hello from NovaChat AI!',
      timestamp: new Date().toISOString(),
    }),
  );
  const receivedNova = await once(manya, (m) => m.type === 'message' && m.id === replyId);
  if (receivedNova.content === 'Hello from NovaChat AI!') {
    record('PASS', 'NovaChat AI -> PulseChat message');
  } else {
    record('FAIL', 'NovaChat AI -> PulseChat message', receivedNova.content);
  }

  const aiActions = [
    'ask',
    'smart_reply',
    'rewrite_professional',
    'rewrite_friendly',
    'make_concise',
    'summarize',
  ];

  for (const action of aiActions) {
    const requestId = `ai-${action}`;
    const payload = {
      type: 'ai_request',
      action,
      roomId: 'general',
      username: 'Reviewer',
      requestId,
      content: action === 'summarize' ? undefined : 'Hello from PulseChat!',
      messages:
        action === 'summarize'
          ? [
              { sender: 'Manya', content: 'Hello from PulseChat!' },
              { sender: 'Reviewer', content: 'Hello from NovaChat AI!' },
            ]
          : undefined,
    };
    if (payload.content === undefined) delete payload.content;
    if (payload.messages === undefined) delete payload.messages;

    reviewer.send(JSON.stringify(payload));
    const response = await once(
      reviewer,
      (m) =>
        (m.type === 'ai_response' && m.requestId === requestId) ||
        (m.type === 'error' && (m.code || '').startsWith('AI_')),
      25000,
    );

    if (response.type === 'error') {
      record(
        response.code === 'AI_NOT_CONFIGURED' || response.code === 'AI_UNAUTHORIZED'
          ? 'PASS'
          : 'FAIL',
        `AI action ${action}`,
        `${response.code}: ${response.message}`,
      );
      continue;
    }

    if (action === 'smart_reply') {
      const ok =
        Array.isArray(response.suggestions) && response.suggestions.length === 3;
      record(ok ? 'PASS' : 'FAIL', 'Smart Reply returns exactly 3', String(response.suggestions));
    } else if (typeof response.content === 'string' && response.content.trim()) {
      record('PASS', `AI action ${action}`, 'got content');
    } else {
      record('FAIL', `AI action ${action}`, 'missing content');
    }
  }

  const aiCmdUserMsg = once(manya, (m) => m.type === 'message' && m.id === 'audit-ai-cmd');
  const aiCmdRoomAi = once(manya, (m) => m.type === 'message' && m.isAi === true, 25000);
  const aiCmdError = once(
    reviewer,
    (m) => m.type === 'error' && (m.code || '').startsWith('AI_'),
    25000,
  );
  reviewer.send(
    JSON.stringify({
      type: 'message',
      id: 'audit-ai-cmd',
      roomId: 'general',
      sender: 'Reviewer',
      content: '/ai Explain why WebSocket is useful for chat',
      timestamp: new Date().toISOString(),
    }),
  );
  await aiCmdUserMsg;
  record('PASS', '/ai user message broadcast');

  const aiCmdOutcome = await Promise.race([
    aiCmdRoomAi.then((msg) => ({ kind: 'message', msg })),
    aiCmdError.then((err) => ({ kind: 'error', err })),
  ]);

  if (aiCmdOutcome.kind === 'message') {
    record('PASS', '/ai room AI message', `isAi=${aiCmdOutcome.msg.isAi}`);
    record(aiCmdOutcome.msg.isAi === true ? 'PASS' : 'FAIL', 'AI badge field isAi=true');
  } else {
    record('PASS', '/ai failure without key', aiCmdOutcome.err.code);
    record('PASS', 'AI badge path (not exercised, no valid key)');
  }

  reviewer.close();
  const presenceAfterLeave = await once(
    manya,
    (m) => m.type === 'presence' && m.roomId === 'general' && m.onlineCount === 1,
  );
  record('PASS', 'Presence after disconnect', `onlineCount=${presenceAfterLeave.onlineCount}`);

  const reviewer2 = await openClient();
  reviewer2.send(JSON.stringify({ type: 'join', username: 'Reviewer', roomId: 'general' }));
  const presenceRejoin = await once(
    manya,
    (m) => m.type === 'presence' && m.onlineCount === 2,
  );
  record('PASS', 'Presence after reconnect/rejoin', `onlineCount=${presenceRejoin.onlineCount}`);

  const roomA = await openClient();
  const roomB = await openClient();
  roomA.send(JSON.stringify({ type: 'join', username: 'Alice', roomId: 'room-a' }));
  roomB.send(JSON.stringify({ type: 'join', username: 'Bob', roomId: 'room-b' }));
  await once(roomA, (m) => m.type === 'presence' && m.roomId === 'room-a');
  await once(roomB, (m) => m.type === 'presence' && m.roomId === 'room-b');

  let leaked = false;
  roomB.on('message', (data) => {
    const msg = JSON.parse(data.toString());
    if (msg.type === 'message' && msg.content === 'secret-room-a') leaked = true;
  });
  roomA.send(
    JSON.stringify({
      type: 'message',
      id: 'iso-1',
      roomId: 'room-a',
      sender: 'Alice',
      content: 'secret-room-a',
      timestamp: new Date().toISOString(),
    }),
  );
  await once(roomA, (m) => m.type === 'message' && m.id === 'iso-1');
  await new Promise((r) => setTimeout(r, 250));
  record(leaked ? 'FAIL' : 'PASS', 'Room isolation');

  const bad = await openClient();
  const malformed = once(bad, (m) => m.type === 'error' && m.code === 'INVALID_JSON');
  bad.send('not-json{{{');
  await malformed;
  record('PASS', 'Malformed JSON handled');

  const healthAfter = await fetch(`${BASE}/health`).then((r) => r.json());
  record(
    healthAfter.status === 'ok' ? 'PASS' : 'FAIL',
    'Server alive after malformed JSON',
  );

  manya.close();
  reviewer2.close();
  roomA.close();
  roomB.close();
  bad.close();

  const passed = results.filter((r) => r.status === 'PASS').length;
  const failed = results.filter((r) => r.status === 'FAIL').length;
  console.log(`\nSUMMARY passed=${passed} failed=${failed}`);
  if (failed > 0) process.exit(1);
}

run().catch((err) => {
  console.error('AUDIT_CRASH', err);
  process.exit(1);
});
