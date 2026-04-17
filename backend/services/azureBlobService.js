const { BlobServiceClient } = require('@azure/storage-blob');
const { v4: uuidv4 } = require('uuid');

class AzureBlobService {
  constructor() {
    this.connectionString = process.env.AZURE_STORAGE_CONNECTION_STRING;
    this.containerName = process.env.AZURE_STORAGE_CONTAINER_NAME || 'dealfinder-images';
    
    if (!this.connectionString) {
      console.warn('Azure Storage connection string not configured');
      return;
    }

    this.blobServiceClient = BlobServiceClient.fromConnectionString(this.connectionString);
    this.containerClient = this.blobServiceClient.getContainerClient(this.containerName);
    this.initializeContainer();
  }

  async initializeContainer() {
    try {
      await this.containerClient.createIfNotExists({
        access: 'blob' // Public read access for blobs
      });
      console.log(`Azure Blob container "${this.containerName}" ready`);
    } catch (error) {
      console.error('Failed to initialize Azure Blob container:', error.message);
    }
  }

  async uploadImage(buffer, originalName, folder = 'images') {
    if (!this.blobServiceClient) {
      throw new Error('Azure Blob Storage not configured');
    }

    const ext = originalName.split('.').pop();
    const blobName = `${folder}/${uuidv4()}.${ext}`;
    const blockBlobClient = this.containerClient.getBlockBlobClient(blobName);

    const contentType = this.getContentType(ext);
    await blockBlobClient.upload(buffer, buffer.length, {
      blobHTTPHeaders: { blobContentType: contentType }
    });

    return blockBlobClient.url;
  }

  async deleteImage(imageUrl) {
    if (!this.blobServiceClient || !imageUrl) return;

    try {
      const blobName = this.getBlobNameFromUrl(imageUrl);
      const blockBlobClient = this.containerClient.getBlockBlobClient(blobName);
      await blockBlobClient.deleteIfExists();
    } catch (error) {
      console.error('Failed to delete image:', error.message);
    }
  }

  getBlobNameFromUrl(url) {
    const urlObj = new URL(url);
    return urlObj.pathname.split('/').slice(2).join('/');
  }

  getContentType(ext) {
    const types = {
      jpg: 'image/jpeg',
      jpeg: 'image/jpeg',
      png: 'image/png',
      gif: 'image/gif',
      webp: 'image/webp'
    };
    return types[ext.toLowerCase()] || 'application/octet-stream';
  }

  isConfigured() {
    return !!this.blobServiceClient;
  }
}

module.exports = new AzureBlobService();
