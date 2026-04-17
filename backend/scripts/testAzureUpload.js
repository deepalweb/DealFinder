require('dotenv').config();
const azureBlobService = require('../services/azureBlobService');
const fs = require('fs');
const path = require('path');

async function testAzureUpload() {
  try {
    console.log('Testing Azure Blob Storage upload...\n');

    if (!azureBlobService.isConfigured()) {
      console.error('❌ Azure Blob Storage is NOT configured');
      console.error('Check AZURE_STORAGE_CONNECTION_STRING in .env file');
      return;
    }

    console.log('✅ Azure Blob Storage is configured');
    console.log(`Container: ${process.env.AZURE_STORAGE_CONTAINER_NAME}\n`);

    // Create a test text file to upload
    const testContent = `Test upload at ${new Date().toISOString()}`;
    const testBuffer = Buffer.from(testContent);

    console.log('Uploading test file...');
    const imageUrl = await azureBlobService.uploadImage(
      testBuffer,
      'test.txt',
      'test'
    );

    console.log('✅ Upload successful!');
    console.log(`Image URL: ${imageUrl}\n`);

    console.log('You can now:');
    console.log('1. Go to Azure Portal: https://portal.azure.com');
    console.log('2. Navigate to Storage Account: dealfinderimages');
    console.log('3. Click Containers → deals');
    console.log('4. You should see: test/[uuid].txt\n');

    console.log('🎉 Azure Blob Storage is working correctly!');

  } catch (error) {
    console.error('❌ Upload failed:', error.message);
    console.error('\nTroubleshooting:');
    console.error('1. Check Azure connection string is correct');
    console.error('2. Verify storage account exists in Azure Portal');
    console.error('3. Check container name matches');
  }
}

testAzureUpload();
