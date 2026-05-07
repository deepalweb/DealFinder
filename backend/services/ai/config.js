function parseBoolean(value, defaultValue = false) {
  if (value === undefined || value === null || value === '') return defaultValue;
  return ['1', 'true', 'yes', 'on'].includes(String(value).trim().toLowerCase());
}

function getAiConfig() {
  return {
    responsesUrl: process.env.AZURE_OPENAI_RESPONSES_URL || '',
    endpoint: process.env.AZURE_OPENAI_ENDPOINT || '',
    apiKey: process.env.AZURE_OPENAI_API_KEY || '',
    apiVersion: process.env.AZURE_OPENAI_API_VERSION || '2025-04-01-preview',
    model: process.env.AZURE_OPENAI_MODEL || 'gpt-5',
    aiSearchEnabled: parseBoolean(process.env.AI_SEARCH_ENABLED, true),
    personalizationEnabled: parseBoolean(process.env.AI_PERSONALIZATION_ENABLED, true),
  };
}

function isAzureOpenAIConfigured() {
  const config = getAiConfig();
  return Boolean(config.apiKey && (config.responsesUrl || config.endpoint));
}

module.exports = {
  getAiConfig,
  isAzureOpenAIConfigured,
  parseBoolean,
};
