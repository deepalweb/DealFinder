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
  .then(() => console.log('Connected to MongoDB for creating real merchant'))
  .catch((err) => {
    console.error('Error connecting to MongoDB:', err);
    process.exit(1);
  });

// Real merchant data
const merchantData = {
  name: 'Test Merchant Shop',
  profile: 'This is a test merchant account for the DealFinder app.',
  contactInfo: 'merchant@test.com'
};

// User data for the merchant
const userData = {
  name: 'Test Merchant',
  email: 'merchant@test.com',
  password: 'password123', // In a real app, this would be hashed
  role: 'merchant',
  businessName: 'Test Merchant Shop'
};

// Function to create the merchant
async function setupRealMerchant() {
  try {
    // Check if merchant already exists
    const existingUser = await User.findOne({ email: userData.email });
    if (existingUser) {
      console.log('Merchant user already exists!');
      console.log('Login credentials:');
      console.log('Email: merchant@test.com');
      console.log('Password: password123');
      process.exit(0);
    }

    // Check if merchant already exists by name
    const existingMerchant = await Merchant.findOne({ name: merchantData.name });
    if (existingMerchant) {
      console.log('Merchant already exists!');
      process.exit(0);
    }

    // Create merchant
    const merchant = new Merchant(merchantData);
    const savedMerchant = await merchant.save();
    console.log('Created merchant:', savedMerchant);

    // Create user and link to merchant
    const user = new User({
      ...userData,
      merchantId: savedMerchant._id
    });
    const savedUser = await user.save();
    console.log('Created merchant user:', savedUser);

    console.log('Real merchant setup completed successfully!');
    console.log('Login credentials:');
    console.log('Email: merchant@test.com');
    console.log('Password: password123');
    process.exit(0);
  } catch (error) {
    console.error('Error setting up real merchant:', error);
    process.exit(1);
  }
}

// Run the function
setupRealMerchant();