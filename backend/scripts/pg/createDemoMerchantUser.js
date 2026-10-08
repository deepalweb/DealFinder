require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const bcrypt = require('bcryptjs');
const pg = require('../../models-pg');

const DEMO_EMAIL = 'merchant@dealfinderapp.lk';
const DEMO_PASSWORD = 'DealFinderMerchant123!'; // public: shown on the web login page
const MERCHANT_ID = 'seed-merchant-1'; // Colombo Coffee Co., from seedSampleDeals.js

async function run() {
  await pg.sequelize.authenticate();

  const merchant = await pg.Merchant.findByPk(MERCHANT_ID);
  if (!merchant) {
    throw new Error(`Merchant ${MERCHANT_ID} not found — run seedSampleDeals.js first.`);
  }

  const hashedPassword = await bcrypt.hash(DEMO_PASSWORD, 10);

  await pg.User.upsert({
    id: 'seed-demo-merchant-user',
    name: 'Demo Merchant',
    email: DEMO_EMAIL,
    password: hashedPassword,
    role: 'merchant',
    merchantId: MERCHANT_ID,
    businessName: merchant.name,
  });

  console.log('Demo merchant user ready:');
  console.log('  email:      ', DEMO_EMAIL);
  console.log('  password:   ', DEMO_PASSWORD);
  console.log('  merchant:   ', merchant.name, `(${MERCHANT_ID})`);

  await pg.sequelize.close();
}

run().catch((err) => {
  console.error('Failed to create demo merchant user:', err);
  process.exit(1);
});
