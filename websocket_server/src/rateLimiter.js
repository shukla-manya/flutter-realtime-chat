const { config } = require('./config');

class RateLimiter {
  constructor({ windowMs, maxRequests }) {
    this.windowMs = windowMs;
    this.maxRequests = maxRequests;
    this.buckets = new Map();
  }

  allow(key) {
    const now = Date.now();
    const bucket = this.buckets.get(key) || [];
    const recent = bucket.filter((ts) => now - ts < this.windowMs);

    if (recent.length >= this.maxRequests) {
      this.buckets.set(key, recent);
      return false;
    }

    recent.push(now);
    this.buckets.set(key, recent);
    return true;
  }

  clear(key) {
    this.buckets.delete(key);
  }
}

const aiRateLimiter = new RateLimiter({
  windowMs: config.rateLimit.aiWindowMs,
  maxRequests: config.rateLimit.aiMaxRequests,
});

module.exports = { aiRateLimiter };
