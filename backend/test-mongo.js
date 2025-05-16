const mongoose = require('mongoose');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables
dotenv.config({ path: path.resolve(__dirname, '.env') });

// Mask the MongoDB URI for security in logs
const maskUri = (uri) => {
  if (!uri) return 'Not provided';
  const atIndex = uri.indexOf('@');
  if (atIndex === -1) return '***[URI with no @ symbol]';
  
  // Get everything after the @ symbol
  const visiblePart = uri.substring(atIndex);
  return '***' + visiblePart;
};

console.log('MongoDB URI:', maskUri(process.env.MONGO_URI));
console.log('\nNode.js version:', process.version);
console.log('Testing MongoDB connection...\n');

// Set connection options with timeout
const connectionOptions = {
  useNewUrlParser: true,
  useUnifiedTopology: true,
  serverSelectionTimeoutMS: 5000, // 5 second timeout
  connectTimeoutMS: 10000, // 10 second timeout
};

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, connectionOptions)
  .then(async () => {
    console.log('✅ Successfully connected to MongoDB\n');
    
    // Test the Promotion model
    try {
      // Import the models
      const Merchant = require('./models/Merchant');
      const Promotion = require('./models/Promotion');
      
      console.log('Testing Promotion model query...\n');
      const now = new Date();
      
      // First check if there are any merchants
      const merchantCount = await Merchant.countDocuments();
      console.log(`Found ${merchantCount} merchants in the database`);
      
      // Check if there are any promotions
      const promotionCount = await Promotion.countDocuments();
      console.log(`Found ${promotionCount} total promotions in the database`);
      
      // This is the same query used in the promotionRoutes.js file
      const promotions = await Promotion.find({
        startDate: { $lte: now },
        endDate: { $gte: now }
      }).populate('merchant');
      
      console.log(`✅ Successfully queried promotions. Found ${promotions.length} active promotions.\n`);
      
      // Display a sample of the data (first promotion only, if any)
      if (promotions.length > 0) {
        const sample = promotions[0];
        console.log('Sample promotion:');
        console.log({
          id: sample._id,
          title: sample.title,
          merchant: sample.merchant ? sample.merchant.name || 'Unknown' : 'Unknown',
          startDate: sample.startDate,
          endDate: sample.endDate,
          status: sample.status
        });
      } else {
        console.log('No active promotions found. This could be why your frontend is not displaying any data.');
        
        // Check if there are any promotions at all, regardless of date
        const allPromotions = await Promotion.find({}).populate('merchant');
        console.log(`Total promotions in database (including inactive): ${allPromotions.length}`);
        
        if (allPromotions.length > 0) {
          console.log('\nSample of an inactive promotion:');
          const sample = allPromotions[0];
          console.log({
            id: sample._id,
            title: sample.title,
            merchant: sample.merchant ? sample.merchant.name || 'Unknown' : 'Unknown',
            startDate: sample.startDate,
            endDate: sample.endDate,
            status: sample.status
          });
        }
      }
    } catch (modelError) {
      console.error('❌ Error testing Promotion model:', modelError);
    }
    
    // Close the connection when done
    await mongoose.connection.close();
    console.log('\nConnection closed.');
  })
  .catch((err) => {
    console.error('❌ Error connecting to MongoDB:', err);
    
    // Provide more specific error diagnostics
    if (err.name === 'MongoServerSelectionError') {
      console.error('Could not connect to any MongoDB server. Possible causes:');
      console.error('- Network connectivity issues');
      console.error('- MongoDB Atlas IP whitelist restrictions');
      console.error('- Incorrect connection string');
    }
    
    if (err.name === 'MongoParseError') {
      console.error('Invalid MongoDB connection string format.');
    }
    
    if (err.message && err.message.includes('Authentication failed')) {
      console.error('Authentication failed. Check username and password in connection string.');
    }
  });