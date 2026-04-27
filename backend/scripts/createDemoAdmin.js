const path = require('path');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

const User = require('../models/User');

const mongoUri = process.env.MONGO_URI;
const demoEmail = process.env.DEMO_ADMIN_EMAIL || 'demo.admin@dealfinder.local';
const demoPassword = process.env.DEMO_ADMIN_PASSWORD || 'DemoAdmin123!';
const demoName = process.env.DEMO_ADMIN_NAME || 'Demo Admin';

if (!mongoUri) {
  console.error('Missing MONGO_URI. Add it to backend/.env or your shell environment and rerun this script.');
  process.exit(1);
}

async function run() {
  try {
    await mongoose.connect(mongoUri, {
      tls: true,
      retryWrites: false,
      serverSelectionTimeoutMS: 10000,
      socketTimeoutMS: 20000,
      family: 4,
    });

    const hashedPassword = await bcrypt.hash(demoPassword, 10);
    const existing = await User.findOne({ email: demoEmail });

    if (existing) {
      existing.name = demoName;
      existing.password = hashedPassword;
      existing.role = 'admin';
      await existing.save();

      console.log('Updated existing demo admin account.');
      console.log(`Email: ${demoEmail}`);
      console.log(`Password: ${demoPassword}`);
      process.exit(0);
    }

    await User.create({
      name: demoName,
      email: demoEmail,
      password: hashedPassword,
      role: 'admin',
    });

    console.log('Created demo admin account.');
    console.log(`Email: ${demoEmail}`);
    console.log(`Password: ${demoPassword}`);
    process.exit(0);
  } catch (error) {
    console.error('Failed to create demo admin:', error.message);
    process.exit(1);
  }
}

run();
