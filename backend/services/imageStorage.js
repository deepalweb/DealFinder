// The active image store, picked by IMAGE_STORAGE_PROVIDER (r2 | azure | local).
// Defaults to local disk for dev; production on Cloudflare uses r2.
const providers = {
  r2: () => require('./r2ImageService'),
  azure: () => require('./azureBlobService'),
  local: () => require('./localImageService'),
};

module.exports = (providers[process.env.IMAGE_STORAGE_PROVIDER] || providers.local)();
