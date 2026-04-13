require('dotenv').config();
const mongoose = require('mongoose');

// Old database connection string (your current one)
const OLD_DB_URI = process.env.OLD_MONGO_URI || process.env.MONGO_URI;

// New Azure Cosmos DB connection string
const NEW_DB_URI = process.env.NEW_MONGO_URI;

if (!NEW_DB_URI) {
  console.error('Error: NEW_MONGO_URI not set in .env file');
  process.exit(1);
}

const collections = ['users', 'merchants', 'promotions', 'notifications', 'notificationlogs', 'notificationpreferences', 'promotionclicks'];

async function migrateData() {
  let oldConn, newConn;

  try {
    console.log('Connecting to old database...');
    oldConn = await mongoose.createConnection(OLD_DB_URI, {
      tls: true,
      retryWrites: false,
      serverSelectionTimeoutMS: 30000,
    }).asPromise();
    console.log('✓ Connected to old database');

    console.log('Connecting to new Azure Cosmos DB...');
    newConn = await mongoose.createConnection(NEW_DB_URI, {
      tls: true,
      retryWrites: false,
      serverSelectionTimeoutMS: 30000,
    }).asPromise();
    console.log('✓ Connected to new database');

    for (const collectionName of collections) {
      try {
        console.log(`\nMigrating ${collectionName}...`);
        
        const oldCollection = oldConn.collection(collectionName);
        const count = await oldCollection.countDocuments();
        
        if (count === 0) {
          console.log(`  ⊘ ${collectionName} is empty, skipping`);
          continue;
        }

        console.log(`  Found ${count} documents`);
        
        const documents = await oldCollection.find({}).toArray();
        
        if (documents.length > 0) {
          const newCollection = newConn.collection(collectionName);
          await newCollection.insertMany(documents, { ordered: false });
          console.log(`  ✓ Migrated ${documents.length} documents to ${collectionName}`);
        }
      } catch (err) {
        if (err.code === 11000) {
          console.log(`  ⚠ Some documents already exist in ${collectionName}, skipping duplicates`);
        } else {
          console.error(`  ✗ Error migrating ${collectionName}:`, err.message);
        }
      }
    }

    console.log('\n--- Creating indexes on new database ---');
    
    // Merchants 2dsphere index
    try {
      await newConn.collection('merchants').createIndex({ location: '2dsphere' });
      console.log('✓ Created 2dsphere index on merchants.location');
    } catch (err) {
      console.log('⚠ 2dsphere index:', err.message);
    }

    // Promotion indexes
    try {
      await newConn.collection('promotions').createIndex({ status: 1, endDate: 1, startDate: 1 });
      await newConn.collection('promotions').createIndex({ merchant: 1, status: 1 });
      await newConn.collection('promotions').createIndex({ featured: 1, status: 1 });
      console.log('✓ Created compound indexes on promotions');
    } catch (err) {
      console.log('⚠ Promotion indexes:', err.message);
    }

    console.log('\n✓ Migration completed successfully!');
    console.log('\nNext steps:');
    console.log('1. Update MONGO_URI in .env to your NEW_MONGO_URI value');
    console.log('2. Restart your application');
    console.log('3. Test the application thoroughly');
    console.log('4. Keep old database as backup for a few days');

  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  } finally {
    if (oldConn) await oldConn.close();
    if (newConn) await newConn.close();
    process.exit(0);
  }
}

migrateData();
