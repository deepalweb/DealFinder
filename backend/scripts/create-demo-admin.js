// create-demo-admin.js
// This script creates a new demo admin user.

require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../models/User'); // Adjust path as necessary

const DEMO_ADMIN_NAME = 'Demo Admin';
const DEMO_ADMIN_EMAIL = 'admin@demo.com';
const DEMO_ADMIN_PASSWORD = 'demoadmin123'; // This will be hashed

async function createDemoAdminUser() {
  if (!process.env.MONGO_URI) {
    console.error('Error: MONGO_URI is not defined in your .env file.');
    process.exit(1);
  }

  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Successfully connected to MongoDB.');

    console.log(`Checking if user with email "${DEMO_ADMIN_EMAIL}" already exists...`);
    const existingUser = await User.findOne({ email: DEMO_ADMIN_EMAIL });

    if (existingUser) {
      console.warn(`Warning: User with email "${DEMO_ADMIN_EMAIL}" already exists.`);
      console.log(`Name: ${existingUser.name}, Role: ${existingUser.role}`);
      if (existingUser.role === 'admin') {
        console.log('This user is already an admin. No action taken.');
      } else {
        console.log('This user is NOT an admin. If you want to make them an admin, run the make-admin.js script or update manually.');
      }
      await mongoose.disconnect();
      process.exit(0); // Exit gracefully as user exists
    }

    console.log('User does not exist. Creating new demo admin user...');

    console.log(`Hashing password for "${DEMO_ADMIN_EMAIL}"...`);
    const hashedPassword = await bcrypt.hash(DEMO_ADMIN_PASSWORD, 10);
    console.log('Password hashed.');

    const newUser = new User({
      name: DEMO_ADMIN_NAME,
      email: DEMO_ADMIN_EMAIL,
      password: hashedPassword,
      role: 'admin',
      // You can add other default fields if necessary, e.g., businessName
    });

    await newUser.save();
    console.log('--------------------------------------------------');
    console.log('🎉 Demo Admin User Created Successfully! 🎉');
    console.log('--------------------------------------------------');
    console.log(`Name: ${DEMO_ADMIN_NAME}`);
    console.log(`Email: ${DEMO_ADMIN_EMAIL}`);
    console.log(`Password: ${DEMO_ADMIN_PASSWORD} (Use this to log in)`);
    console.log('Role: admin');
    console.log('--------------------------------------------------');
    console.log('You can now log in with these credentials.');
    console.log('IMPORTANT: Consider changing the password after first login for security if this is a shared environment.');


    await mongoose.disconnect();
    console.log('Disconnected from MongoDB.');
    process.exit(0);

  } catch (error) {
    console.error('An error occurred during demo admin creation:', error);
    if (mongoose.connection.readyState === 1) { // 1 === connected
      await mongoose.disconnect();
      console.log('Disconnected from MongoDB due to error.');
    }
    process.exit(1);
  }
}

createDemoAdminUser();
