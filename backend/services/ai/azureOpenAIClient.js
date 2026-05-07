const fetch = (...args) => import('node-fetch').then(({ default: importedFetch }) => importedFetch(...args));
const { getAiConfig, isAzureOpenAIConfigured } = require('./config');

function buildResponsesUrl() {
  const config = getAiConfig();

  if (config.responsesUrl) {
    return config.responsesUrl;
  }

  const endpoint = config.endpoint.replace(/\/+$/, '');
  return `${endpoint}/openai/responses?api-version=${encodeURIComponent(config.apiVersion)}`;
}

function extractOutputText(payload) {
  if (!payload || typeof payload !== 'object') return '';
  if (typeof payload.output_text === 'string' && payload.output_text.trim()) {
    return payload.output_text.trim();
  }

  const outputs = Array.isArray(payload.output) ? payload.output : [];
  const textParts = [];

  for (const item of outputs) {
    const content = Array.isArray(item.content) ? item.content : [];
    for (const block of content) {
      if (typeof block.text === 'string' && block.text.trim()) {
        textParts.push(block.text.trim());
      }
    }
  }

  return textParts.join('\n').trim();
}

async function createResponse({
  input,
  instructions,
  model,
  temperature = 0.1,
  maxOutputTokens = 500,
  metadata,
}) {
  if (!isAzureOpenAIConfigured()) {
    throw new Error('Azure OpenAI is not configured.');
  }

  const config = getAiConfig();
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10000);

  try {
    const response = await fetch(buildResponsesUrl(), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'api-key': config.apiKey,
      },
      body: JSON.stringify({
        model: model || config.model,
        instructions,
        input,
        temperature,
        max_output_tokens: maxOutputTokens,
        metadata,
      }),
      signal: controller.signal,
    });

    const text = await response.text();
    const payload = text ? JSON.parse(text) : {};

    if (!response.ok) {
      const message = payload?.error?.message || `Azure OpenAI request failed with ${response.status}`;
      throw new Error(message);
    }

    return {
      raw: payload,
      outputText: extractOutputText(payload),
    };
  } finally {
    clearTimeout(timeout);
  }
}

module.exports = {
  buildResponsesUrl,
  createResponse,
  extractOutputText,
};
