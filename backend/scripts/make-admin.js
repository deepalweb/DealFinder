// make-admin.js
// This script updates an existing user to have the 'admin' role.

require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const mongoose = require('mongoose');
const User = require('../models/User'); // Adjust path as necessary

const USER_EMAIL_TO_MAKE_ADMIN = 'drstoreslk@gmail.com';

async function makeUserAdmin() {
  if (!process.env.MONGO_URI) {
    console.error('Error: MONGO_URI is not defined in your .env file.');
    process.exit(1);
  }

  if (!USER_EMAIL_TO_MAKE_ADMIN) {
    console.error('Error: No email address provided for the user to update.');
    process.exit(1);
  }

  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Successfully connected to MongoDB.');

    console.log(`Searching for user with email: ${USER_EMAIL_TO_MAKE_ADMIN}...`);
    const user = await User.findOne({ email: USER_EMAIL_TO_MAKE_ADMIN });

    if (!user) {
      console.error(`Error: User with email "${USER_EMAIL_TO_MAKE_ADMIN}" not found.`);
      await mongoose.disconnect();
      process.exit(1);
    }

    console.log(`User found: ${user.name} (Role: ${user.role})`);

    if (user.role === 'admin') {
      console.log(`User "${USER_EMAIL_TO_MAKE_ADMIN}" is already an admin.`);
    } else {
      user.role = 'admin';
      await user.save();
      console.log(`Successfully updated user "${USER_EMAIL_TO_MAKE_ADMIN}" to role "admin".`);
    }

    await mongoose.disconnect();
    console.log('Disconnected from MongoDB.');
    process.exit(0);

  } catch (error) {
    console.error('An error occurred:', error);
    if (mongoose.connection.readyState === 1) { // 1 === connected
      await mongoose.disconnect();
      console.log('Disconnected from MongoDB due to error.');
    }
    process.exit(1);
  }
}

makeUserAdmin();
