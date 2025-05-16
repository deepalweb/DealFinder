const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });

// Import models
const User = require('../models/User');
const Merchant = require('../models/Merchant');
const Promotion = require('../models/Promotion');
const Notification = require('../models/Notification');

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log('Connected to MongoDB for seeding'))
  .catch((err) => {
    console.error('Error connecting to MongoDB:', err);
    process.exit(1);
  });

// Sample data
const users = [
  {
    name: 'John Doe',
    email: 'john@example.com',
    password: 'password123',
    role: 'user',
    favorites: []
  },
  {
    name: 'Jane Smith',
    email: 'jane@example.com',
    password: 'password123',
    role: 'merchant',
    businessName: 'Jane\'s Electronics'
  },
  {
    name: 'Admin User',
    email: 'admin@example.com',
    password: 'admin123',
    role: 'admin'
  }
];

const merchants = [
  {
    name: 'Jane\'s Electronics',
    profile: 'Leading electronics retailer with the best deals on the latest gadgets.',
    contactInfo: 'jane@example.com'
  },
  {
    name: 'Fashion Forward',
    profile: 'Trendy fashion items at affordable prices.',
    contactInfo: 'contact@fashionforward.com'
  },
  {
    name: 'Home Essentials',
    profile: 'Everything you need for your home.',
    contactInfo: 'info@homeessentials.com'
  }
];

// Function to seed the database
async function seedDatabase() {
  try {
    // Clear existing data
    await User.deleteMany({});
    await Merchant.deleteMany({});
    await Promotion.deleteMany({});
    await Notification.deleteMany({});
    
    console.log('Cleared existing data');
    
    // Create merchants
    const createdMerchants = await Merchant.insertMany(merchants);
    console.log(`Created ${createdMerchants.length} merchants`);
    
    // Create users and link merchants
    const createdUsers = [];
    
    for (const user of users) {
      if (user.role === 'merchant') {
        // Find the merchant with the matching name
        const merchant = createdMerchants.find(m => m.name === user.businessName);
        
        if (merchant) {
          user.merchantId = merchant._id;
        }
      }
      
      const newUser = await User.create(user);
      createdUsers.push(newUser);
    }
    
    console.log(`Created ${createdUsers.length} users`);
    
    // Create promotions
    const promotions = [
      {
        title: 'Summer Sale - 30% Off All Electronics',
        description: 'Take advantage of our biggest summer sale yet! 30% off all items, including new arrivals.',
        discount: '30%',
        code: 'SUMMER30',
        category: 'electronics',
        merchant: createdMerchants[0]._id, // Jane's Electronics
        startDate: new Date('2023-06-15'),
        endDate: new Date('2023-12-31'),
        status: 'active',
        image: 'https://images.unsplash.com/photo-1498049794561-7780e7231661?q=80&w=2670&auto=format&fit=crop'
      },
      {
        title: 'Flash Sale - Buy One Get One Free',
        description: 'Limited time offer! Buy any item and get another of equal or lesser value for free.',
        discount: 'BOGO',
        code: 'FLASH2023',
        category: 'electronics',
        merchant: createdMerchants[0]._id, // Jane's Electronics
        startDate: new Date('2023-07-01'),
        endDate: new Date('2023-07-07'),
        status: 'expired',
        image: 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?q=80&w=2670&auto=format&fit=crop'
      },
      {
        title: 'Holiday Special - 25% Off Smart Home Products',
        description: 'Get ready for the holidays with our smart home collection. Everything you need for a connected home experience.',
        discount: '25%',
        code: 'SMART25',
        category: 'electronics',
        merchant: createdMerchants[0]._id, // Jane's Electronics
        startDate: new Date('2023-11-15'),
        endDate: new Date('2023-12-31'),
        status: 'active',
        image: 'https://images.unsplash.com/photo-1558346490-a72e53ae2d4f?q=80&w=2670&auto=format&fit=crop'
      },
      {
        title: 'Spring Fashion Sale - 40% Off',
        description: 'Refresh your wardrobe with our spring collection. 40% off selected items.',
        discount: '40%',
        code: 'SPRING40',
        category: 'fashion',
        merchant: createdMerchants[1]._id, // Fashion Forward
        startDate: new Date('2023-03-01'),
        endDate: new Date('2023-04-15'),
        status: 'expired',
        image: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?q=80&w=2670&auto=format&fit=crop'
      },
      {
        title: 'Home Decor Sale - 20% Off',
        description: 'Transform your living space with our home decor collection. 20% off all items.',
        discount: '20%',
        code: 'HOME20',
        category: 'home',
        merchant: createdMerchants[2]._id, // Home Essentials
        startDate: new Date('2023-09-01'),
        endDate: new Date('2023-10-31'),
        status: 'active',
        image: 'https://images.unsplash.com/photo-1513694203232-719a280e022f?q=80&w=2669&auto=format&fit=crop'
      }
    ];
    
    const createdPromotions = await Promotion.insertMany(promotions);
    console.log(`Created ${createdPromotions.length} promotions`);
    
    // Update merchants with promotions
    for (const promotion of createdPromotions) {
      await Merchant.findByIdAndUpdate(
        promotion.merchant,
        { $push: { promotions: promotion._id } }
      );
    }
    
    console.log('Updated merchants with promotions');
    
    // Add some favorites for the regular user
    const regularUser = createdUsers.find(u => u.role === 'user');
    if (regularUser) {
      regularUser.favorites = [createdPromotions[0]._id, createdPromotions[4]._id];
      await regularUser.save();
      console.log('Added favorites to regular user');
    }
    
    console.log('Database seeded successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding database:', error);
    process.exit(1);
  }
}

// Run the seed function
seedDatabase();