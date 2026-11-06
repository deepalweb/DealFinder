function parseBoolean(value, defaultValue = false) {
  if (value === undefined || value === null || value === '') return defaultValue;
  return ['1', 'true', 'yes', 'on'].includes(String(value).trim().toLowerCase());
}

function getAiConfig() {
  return {
    aiSearchEnabled: parseBoolean(process.env.AI_SEARCH_ENABLED, true),
    personalizationEnabled: parseBoolean(process.env.AI_PERSONALIZATION_ENABLED, true),
  };
}

module.exports = {
  getAiConfig,
  parseBoolean,
};
