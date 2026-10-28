const path = require('path');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const User = require('../models/User');
const Merchant = require('../models/Merchant');

async function run() {
  await mongoose.connect(process.env.MONGO_URI, {
    tls: true,
    retryWrites: false,
    serverSelectionTimeoutMS: 10000,
    family: 4,
  });
  console.log('Connected to database:', mongoose.connection.name);

  // --- Regular User ---
  const userPass = await bcrypt.hash('password123', 10);
  const existingUser = await User.findByEmail('john@example.com');
  if (existingUser) {
    existingUser.password = userPass;
    existingUser.backendPassword = true;
    await existingUser.save();
    console.log('Updated user:     john@example.com / password123');
  } else {
    await User.create({
      name: 'John Doe',
      email: 'john@example.com',
      password: userPass,
      role: 'user',
      backendPassword: true,
      favorites: [],
    });
    console.log('Created user:     john@example.com / password123');
  }

  // --- Merchant profile ---
  let merchant = await Merchant.findOne({ name: "Jane's Electronics" });
  if (!merchant) {
    merchant = await Merchant.create({
      name: "Jane's Electronics",
      profile: 'Leading electronics retailer.',
      contactInfo: 'jane@example.com',
      category: 'electronics',
      currency: 'LKR',
      status: 'active',
      promotions: [],
    });
    console.log('Created merchant: Jane\'s Electronics');
  } else {
    console.log('Merchant exists:  Jane\'s Electronics');
  }

  // --- Merchant User ---
  const merchantPass = await bcrypt.hash('password123', 10);
  const existingMerchantUser = await User.findByEmail('jane@example.com');
  if (existingMerchantUser) {
    existingMerchantUser.password = merchantPass;
    existingMerchantUser.backendPassword = true;
    existingMerchantUser.merchantId = merchant._id;
    await existingMerchantUser.save();
    console.log('Updated merchant: jane@example.com / password123');
  } else {
    await User.create({
      name: 'Jane Smith',
      email: 'jane@example.com',
      password: merchantPass,
      role: 'merchant',
      businessName: "Jane's Electronics",
      merchantId: merchant._id,
      backendPassword: true,
    });
    console.log('Created merchant: jane@example.com / password123');
  }

  console.log('\nAll demo accounts ready.');
  process.exit(0);
}

run().catch((e) => {
  console.error('Failed:', e.message);
  process.exit(1);
});
