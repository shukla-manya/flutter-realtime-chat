require('dotenv').config();

const config = {
  port: Number(process.env.PORT) || 8080,
  groqApiKey: process.env.GROQ_API_KEY || '',
  groqModel: process.env.GROQ_MODEL || 'llama-3.3-70b-versatile',
  groqTimeoutMs: Number(process.env.GROQ_TIMEOUT_MS) || 20000,
  limits: {
    usernameMax: 24,
    roomIdMax: 32,
    messageMax: 1000,
    messageIdMax: 80,
    aiContentMax: 2000,
    summaryMessagesMax: 40,
  },
  rateLimit: {
    aiWindowMs: 60_000,
    aiMaxRequests: 12,
  },
};

module.exports = { config };
