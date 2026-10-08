require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const bcrypt = require('bcryptjs');
const pg = require('../../models-pg');

const DEMO_EMAIL = 'admin@dealfinderapp.lk';
const DEMO_PASSWORD = process.env.DEMO_PASSWORD || require('crypto').randomBytes(12).toString('base64url'); // never hardcode: admin

async function run() {
  await pg.sequelize.authenticate();

  const hashedPassword = await bcrypt.hash(DEMO_PASSWORD, 10);

  await pg.User.upsert({
    id: 'seed-demo-admin-user',
    name: 'Demo Admin',
    email: DEMO_EMAIL,
    password: hashedPassword,
    role: 'admin',
  });

  console.log('Demo admin user ready:');
  console.log('  email:   ', DEMO_EMAIL);
  console.log('  password:', DEMO_PASSWORD);

  await pg.sequelize.close();
}

run().catch((err) => {
  console.error('Failed to create demo admin user:', err);
  process.exit(1);
});
