require('dotenv').config();

const config = {
  port: Number(process.env.PORT) || 8080,
  limits: {
    usernameMax: 24,
    roomIdMax: 32,
    messageMax: 1000,
    messageIdMax: 80,
  },
};

module.exports = { config };
