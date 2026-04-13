require('dotenv').config();
const mongoose = require('mongoose');

const OLD_DB_URI = process.env.OLD_MONGO_URI || process.env.MONGO_URI;
const NEW_DB_URI = process.env.NEW_MONGO_URI;

const collections = ['users', 'merchants', 'promotions', 'notifications', 'notificationlogs', 'notificationpreferences', 'promotionclicks'];

async function verifyMigration() {
  let oldConn, newConn;

  try {
    console.log('Connecting to databases...\n');
    
    oldConn = await mongoose.createConnection(OLD_DB_URI, {
      tls: true,
      retryWrites: false,
      serverSelectionTimeoutMS: 30000,
    }).asPromise();

    newConn = await mongoose.createConnection(NEW_DB_URI, {
      tls: true,
      retryWrites: false,
      serverSelectionTimeoutMS: 30000,
    }).asPromise();

    console.log('✓ Connected to both databases\n');
    console.log('Collection Comparison:');
    console.log('─'.repeat(60));
    console.log('Collection'.padEnd(25) + 'Old DB'.padEnd(15) + 'New DB'.padEnd(15) + 'Status');
    console.log('─'.repeat(60));

    let allMatch = true;

    for (const collectionName of collections) {
      const oldCount = await oldConn.collection(collectionName).countDocuments();
      const newCount = await newConn.collection(collectionName).countDocuments();
      
      const status = oldCount === newCount ? '✓ Match' : '✗ Mismatch';
      if (oldCount !== newCount) allMatch = false;

      console.log(
        collectionName.padEnd(25) + 
        oldCount.toString().padEnd(15) + 
        newCount.toString().padEnd(15) + 
        status
      );
    }

    console.log('─'.repeat(60));
    
    if (allMatch) {
      console.log('\n✓ All collections match! Migration successful.');
    } else {
      console.log('\n⚠ Some collections have different counts. Review migration.');
    }

    // Check indexes
    console.log('\n\nIndex Verification:');
    console.log('─'.repeat(60));
    
    const merchantIndexes = await newConn.collection('merchants').indexes();
    const has2dsphere = merchantIndexes.some(idx => idx.key && idx.key.location === '2dsphere');
    console.log(`Merchants 2dsphere index: ${has2dsphere ? '✓ Exists' : '✗ Missing'}`);

    const promotionIndexes = await newConn.collection('promotions').indexes();
    console.log(`Promotions indexes: ${promotionIndexes.length} total`);

  } catch (err) {
    console.error('Verification failed:', err.message);
  } finally {
    if (oldConn) await oldConn.close();
    if (newConn) await newConn.close();
    process.exit(0);
  }
}

verifyMigration();
