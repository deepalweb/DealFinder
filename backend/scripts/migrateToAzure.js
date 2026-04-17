require('dotenv').config();
const mongoose = require('mongoose');
const azureBlobService = require('../services/azureBlobService');
const Promotion = require('../models/Promotion');
const Merchant = require('../models/Merchant');

async function migrateToAzure() {
  try {
    console.log('Starting migration to Azure Blob Storage...');

    if (!azureBlobService.isConfigured()) {
      console.error('Azure Blob Storage not configured. Check AZURE_STORAGE_CONNECTION_STRING');
      process.exit(1);
    }

    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to MongoDB');

    // Migrate Promotions
    console.log('\n=== Migrating Promotions ===');
    const promotions = await Promotion.find({
      $or: [
        { image: { $regex: '^data:image' } },
        { images: { $elemMatch: { $regex: '^data:image' } } }
      ]
    });

    console.log(`Found ${promotions.length} promotions with base64 images`);

    for (const promo of promotions) {
      console.log(`\nProcessing promotion: ${promo._id}`);
      let updated = false;

      // Migrate main image
      if (promo.image && promo.image.startsWith('data:image')) {
        try {
          const buffer = Buffer.from(promo.image.split(',')[1], 'base64');
          const ext = promo.image.split(';')[0].split('/')[1];
          const imageUrl = await azureBlobService.uploadImage(buffer, `image.${ext}`, 'promotions');
          promo.image = imageUrl;
          updated = true;
          console.log(`  ✓ Main image migrated`);
        } catch (err) {
          console.error(`  ✗ Failed to migrate main image:`, err.message);
        }
      }

      // Migrate images array
      if (promo.images && promo.images.length > 0) {
        const newImages = [];
        for (let i = 0; i < promo.images.length; i++) {
          const img = promo.images[i];
          if (img.startsWith('data:image')) {
            try {
              const buffer = Buffer.from(img.split(',')[1], 'base64');
              const ext = img.split(';')[0].split('/')[1];
              const imageUrl = await azureBlobService.uploadImage(buffer, `image-${i}.${ext}`, 'promotions');
              newImages.push(imageUrl);
              console.log(`  ✓ Image ${i + 1} migrated`);
            } catch (err) {
              console.error(`  ✗ Failed to migrate image ${i + 1}:`, err.message);
              newImages.push(img);
            }
          } else {
            newImages.push(img);
          }
        }
        promo.images = newImages;
        updated = true;
      }

      if (updated) {
        await promo.save();
        console.log(`  ✓ Promotion saved`);
      }
    }

    // Migrate Merchants
    console.log('\n=== Migrating Merchants ===');
    const merchants = await Merchant.find({
      $or: [
        { logo: { $regex: '^data:image' } },
        { banner: { $regex: '^data:image' } }
      ]
    });

    console.log(`Found ${merchants.length} merchants with base64 images`);

    for (const merchant of merchants) {
      console.log(`\nProcessing merchant: ${merchant._id}`);
      let updated = false;

      // Migrate logo
      if (merchant.logo && merchant.logo.startsWith('data:image')) {
        try {
          const buffer = Buffer.from(merchant.logo.split(',')[1], 'base64');
          const ext = merchant.logo.split(';')[0].split('/')[1];
          const imageUrl = await azureBlobService.uploadImage(buffer, `logo.${ext}`, 'merchants');
          merchant.logo = imageUrl;
          updated = true;
          console.log(`  ✓ Logo migrated`);
        } catch (err) {
          console.error(`  ✗ Failed to migrate logo:`, err.message);
        }
      }

      // Migrate banner
      if (merchant.banner && merchant.banner.startsWith('data:image')) {
        try {
          const buffer = Buffer.from(merchant.banner.split(',')[1], 'base64');
          const ext = merchant.banner.split(';')[0].split('/')[1];
          const imageUrl = await azureBlobService.uploadImage(buffer, `banner.${ext}`, 'merchants');
          merchant.banner = imageUrl;
          updated = true;
          console.log(`  ✓ Banner migrated`);
        } catch (err) {
          console.error(`  ✗ Failed to migrate banner:`, err.message);
        }
      }

      if (updated) {
        await merchant.save();
        console.log(`  ✓ Merchant saved`);
      }
    }

    console.log('\n=== Migration Complete ===');
    console.log('All base64 images have been migrated to Azure Blob Storage');

  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

migrateToAzure();
