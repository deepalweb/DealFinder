require('dotenv').config();
const mongoose = require('mongoose');
const Promotion = require('../models/Promotion');
const Merchant = require('../models/Merchant');

async function verifyMigration() {
  try {
    console.log('Verifying Azure Blob Storage migration...\n');

    await mongoose.connect(process.env.MONGO_URI);

    // Check Promotions
    const totalPromotions = await Promotion.countDocuments();
    const base64Promotions = await Promotion.countDocuments({
      $or: [
        { image: { $regex: '^data:image' } },
        { images: { $elemMatch: { $regex: '^data:image' } } }
      ]
    });
    const azurePromotions = totalPromotions - base64Promotions;

    console.log('=== Promotions ===');
    console.log(`Total: ${totalPromotions}`);
    console.log(`Migrated to Azure: ${azurePromotions} (${((azurePromotions/totalPromotions)*100).toFixed(1)}%)`);
    console.log(`Still base64: ${base64Promotions}`);

    // Check Merchants
    const totalMerchants = await Merchant.countDocuments();
    const base64Merchants = await Merchant.countDocuments({
      $or: [
        { logo: { $regex: '^data:image' } },
        { banner: { $regex: '^data:image' } }
      ]
    });
    const azureMerchants = totalMerchants - base64Merchants;

    console.log('\n=== Merchants ===');
    console.log(`Total: ${totalMerchants}`);
    console.log(`Migrated to Azure: ${azureMerchants} (${((azureMerchants/totalMerchants)*100).toFixed(1)}%)`);
    console.log(`Still base64: ${base64Merchants}`);

    if (base64Promotions === 0 && base64Merchants === 0) {
      console.log('\n✓ Migration complete! All images are now on Azure Blob Storage');
    } else {
      console.log('\n⚠ Migration incomplete. Run migration script again.');
    }

  } catch (error) {
    console.error('Verification failed:', error);
  } finally {
    await mongoose.disconnect();
  }
}

verifyMigration();
