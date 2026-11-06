// Defaults to local disk for development; Cloudflare production uses R2.
const providers = {
  r2: () => require('./r2ImageService'),
  local: () => require('./localImageService'),
};

module.exports = (providers[process.env.IMAGE_STORAGE_PROVIDER] || providers.local)();
