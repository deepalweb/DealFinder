const { S3Client, PutObjectCommand, DeleteObjectCommand } = require('@aws-sdk/client-s3');
const { v4: uuidv4 } = require('uuid');
const { getContentType } = require('./localImageService');

// Cloudflare R2 via its S3-compatible API. Objects are served from R2_PUBLIC_URL
// (the bucket's custom domain or r2.dev URL), e.g. https://images.dealfinderapp.lk
class R2ImageService {
  constructor() {
    const { R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET, R2_PUBLIC_URL } = process.env;
    if (!R2_ACCOUNT_ID || !R2_ACCESS_KEY_ID || !R2_SECRET_ACCESS_KEY || !R2_BUCKET || !R2_PUBLIC_URL) {
      return;
    }

    this.bucket = R2_BUCKET;
    this.publicUrl = R2_PUBLIC_URL.replace(/\/+$/, '');
    this.client = new S3Client({
      region: 'auto',
      endpoint: `https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
      credentials: { accessKeyId: R2_ACCESS_KEY_ID, secretAccessKey: R2_SECRET_ACCESS_KEY },
    });
  }

  isConfigured() {
    return !!this.client;
  }

  async uploadImage(buffer, originalName, folder = 'images') {
    if (!this.client) throw new Error('R2 storage not configured');

    const ext = (originalName.split('.').pop() || 'jpg').toLowerCase();
    const safeFolder = folder.replace(/[^a-zA-Z0-9_-]/g, '') || 'images';
    const key = `${safeFolder}/${uuidv4()}.${ext}`;

    await this.client.send(new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      Body: buffer,
      ContentType: getContentType(ext),
    }));

    return `${this.publicUrl}/${key}`;
  }

  async deleteImage(imageUrl) {
    // Only touch objects in our own bucket; old Azure/local URLs are ignored.
    if (!this.client || !imageUrl || !imageUrl.startsWith(`${this.publicUrl}/`)) return;

    try {
      const key = decodeURIComponent(imageUrl.slice(this.publicUrl.length + 1));
      await this.client.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: key }));
    } catch (error) {
      console.error('Failed to delete R2 image:', error.message);
    }
  }
}

module.exports = new R2ImageService();
