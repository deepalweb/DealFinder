const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const UPLOADS_ROOT = path.join(__dirname, '..', 'uploads');

const CONTENT_TYPES = {
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  png: 'image/png',
  gif: 'image/gif',
  webp: 'image/webp',
  heic: 'image/heic',
  heif: 'image/heif',
};

class LocalImageService {
  isConfigured() {
    return true;
  }

  // baseUrl e.g. "http://localhost:8082", derived per-request from the caller
  // since this is local dev storage with no fixed public origin.
  async uploadImage(buffer, originalName, folder = 'images', baseUrl = '') {
    const ext = (originalName.split('.').pop() || 'jpg').toLowerCase();
    const safeFolder = folder.replace(/[^a-zA-Z0-9_-]/g, '') || 'images';
    const dir = path.join(UPLOADS_ROOT, safeFolder);
    await fs.promises.mkdir(dir, { recursive: true });

    const filename = `${uuidv4()}.${ext}`;
    await fs.promises.writeFile(path.join(dir, filename), buffer);

    return `${baseUrl}/uploads/${safeFolder}/${filename}`;
  }

  async deleteImage(imageUrl) {
    if (!imageUrl) return;
    try {
      const pathname = imageUrl.startsWith('http') ? new URL(imageUrl).pathname : imageUrl;
      const relative = pathname.replace(/^\/uploads\//, '');
      const filePath = path.join(UPLOADS_ROOT, relative);

      // Guard against path traversal outside the uploads root
      if (!filePath.startsWith(UPLOADS_ROOT)) return;

      await fs.promises.unlink(filePath).catch(() => {});
    } catch (error) {
      console.error('Failed to delete local image:', error.message);
    }
  }

  getContentType(ext) {
    return CONTENT_TYPES[ext.toLowerCase()] || 'application/octet-stream';
  }
}

module.exports = new LocalImageService();
