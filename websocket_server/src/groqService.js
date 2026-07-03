const { config } = require('./config');

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions';

async function callGroq({ system, user, temperature = 0.4 }) {
  if (!config.groqApiKey || config.groqApiKey === 'your_groq_api_key_here') {
    const error = new Error('Groq API key is not configured on the server');
    error.code = 'AI_NOT_CONFIGURED';
    throw error;
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), config.groqTimeoutMs);

  try {
    const response = await fetch(GROQ_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.groqApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: config.groqModel,
        temperature,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: user },
        ],
      }),
      signal: controller.signal,
    });

    if (response.status === 401) {
      const error = new Error('Invalid Groq API key');
      error.code = 'AI_UNAUTHORIZED';
      throw error;
    }

    if (response.status === 429) {
      const error = new Error('Groq rate limit reached. Please try again shortly.');
      error.code = 'AI_RATE_LIMIT';
      throw error;
    }

    if (!response.ok) {
      const error = new Error(`Groq request failed (${response.status})`);
      error.code = 'AI_UPSTREAM_ERROR';
      throw error;
    }

    const data = await response.json();
    const content = data?.choices?.[0]?.message?.content?.trim();

    if (!content) {
      const error = new Error('Empty response from Groq');
      error.code = 'AI_EMPTY_RESPONSE';
      throw error;
    }

    return content;
  } catch (err) {
    if (err.name === 'AbortError') {
      const error = new Error('Groq request timed out');
      error.code = 'AI_TIMEOUT';
      throw error;
    }
    throw err;
  } finally {
    clearTimeout(timeout);
  }
}

function parseSmartReplies(raw) {
  try {
    const jsonMatch = raw.match(/\[[\s\S]*\]/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      if (Array.isArray(parsed)) {
        return parsed
          .map((item) => String(item).trim())
          .filter(Boolean)
          .slice(0, 3);
      }
    }
  } catch (_) {
    // Fall through to line parsing.
  }

  const lines = raw
    .split('\n')
    .map((line) => line.replace(/^[-*\d.)\s]+/, '').replace(/^"|"$/g, '').trim())
    .filter(Boolean);

  return lines.slice(0, 3);
}

async function handleAiAction({ action, content, messages }) {
  switch (action) {
    case 'ask': {
      const answer = await callGroq({
        system:
          'You are a helpful assistant inside a realtime chat app. Answer clearly and concisely in 1–3 sentences unless more detail is requested.',
        user: content,
      });
      return { content: answer };
    }

    case 'smart_reply': {
      const answer = await callGroq({
        system:
          'Generate exactly 3 short chat reply suggestions. Return ONLY a JSON array of 3 strings. No markdown.',
        user: `Suggest 3 natural replies to this message:\n${content}`,
        temperature: 0.7,
      });
      let suggestions = parseSmartReplies(answer);
      while (suggestions.length < 3) {
        suggestions.push('Sounds good!');
      }
      return { suggestions: suggestions.slice(0, 3) };
    }

    case 'rewrite_professional': {
      const answer = await callGroq({
        system: 'Rewrite the user message in a professional, polished tone. Return only the rewritten text.',
        user: content,
      });
      return { content: answer };
    }

    case 'rewrite_friendly': {
      const answer = await callGroq({
        system: 'Rewrite the user message in a warm, friendly tone. Return only the rewritten text.',
        user: content,
      });
      return { content: answer };
    }

    case 'make_concise': {
      const answer = await callGroq({
        system: 'Make the user message concise while preserving meaning. Return only the rewritten text.',
        user: content,
      });
      return { content: answer };
    }

    case 'summarize': {
      const transcript = (messages || [])
        .slice(-40)
        .map((m) => `${m.sender || 'User'}: ${m.content || ''}`)
        .join('\n');

      const answer = await callGroq({
        system:
          'Summarize this chat conversation in 2–4 concise bullet-like sentences. Focus on key points and decisions.',
        user: transcript,
      });
      return { content: answer };
    }

    default: {
      const error = new Error('Unsupported AI action');
      error.code = 'INVALID_AI_ACTION';
      throw error;
    }
  }
}

module.exports = { handleAiAction };
