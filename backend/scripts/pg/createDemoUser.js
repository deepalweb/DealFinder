require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const bcrypt = require('bcryptjs');
const pg = require('../../models-pg');

const DEMO_EMAIL = 'demo@dealfinderapp.lk';
const DEMO_PASSWORD = 'DealFinderDemo123!'; // public: shown on the web login page

async function run() {
  await pg.sequelize.authenticate();

  const hashedPassword = await bcrypt.hash(DEMO_PASSWORD, 10);

  await pg.User.upsert({
    id: 'seed-demo-user',
    name: 'Demo User',
    email: DEMO_EMAIL,
    password: hashedPassword,
    role: 'user',
  });

  console.log('Demo user ready:');
  console.log('  email:   ', DEMO_EMAIL);
  console.log('  password:', DEMO_PASSWORD);

  await pg.sequelize.close();
}

run().catch((err) => {
  console.error('Failed to create demo user:', err);
  process.exit(1);
});
