const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

// Import models
const User = require('../models/User');
const Merchant = require('../models/Merchant');

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log('Connected to MongoDB for creating demo merchant'))
  .catch((err) => {
    console.error('Error connecting to MongoDB:', err);
    process.exit(1);
  });

// Demo merchant data
const demoMerchantData = {
  name: 'Demo Merchant',
  profile: 'This is a demo merchant account for testing purposes.',
  contactInfo: 'demo@merchant.com'
};

// Demo user data
const demoUserData = {
  name: 'Demo User',
  email: 'demo@merchant.com',
  password: 'demo123',
  role: 'merchant',
  businessName: 'Demo Merchant Shop'
};

// Function to create demo merchant
async function createDemoMerchant() {
  try {
    // Check if merchant already exists by name
    const existingMerchant = await Merchant.findOne({ name: demoMerchantData.name });
    if (existingMerchant) {
      console.log('Demo merchant already exists!');
      process.exit(0);
    }

    // Check if merchant user already exists
    const existingUser = await User.findOne({ email: demoUserData.email });
    if (existingUser) {
      console.log('Demo merchant user already exists!');
      console.log('Login credentials:');
      console.log('Email: demo@merchant.com');
      console.log('Password: demo123');
      process.exit(0);
    }

    // Create merchant
    const merchant = new Merchant(demoMerchantData);
    const savedMerchant = await merchant.save();
    console.log('Created demo merchant:', savedMerchant);

    // Create user and link to merchant
    const user = new User({
      ...demoUserData,
      merchantId: savedMerchant._id
    });
    const savedUser = await user.save();
    console.log('Created demo merchant user:', savedUser);

    console.log('Demo merchant created successfully!');
    console.log('Login credentials:');
    console.log('Email: demo@merchant.com');
    console.log('Password: demo123');
    process.exit(0);
  } catch (error) {
    console.error('Error creating demo merchant:', error);
    process.exit(1);
  }
}

// Run the function
createDemoMerchant();