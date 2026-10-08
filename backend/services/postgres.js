const { Sequelize } = require('sequelize');

let sequelize = null;

function getSequelize() {
  if (sequelize) {
    return sequelize;
  }

  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    return null;
  }

  sequelize = new Sequelize(databaseUrl, {
    dialect: 'postgres',
    dialectOptions: {
      ssl: { require: true, rejectUnauthorized: false },
    },
    logging: false,
  });

  return sequelize;
}

async function ensurePostgresConnected() {
  const instance = getSequelize();
  if (!instance) {
    console.warn('Postgres: DATABASE_URL not set. Supabase connection will be unavailable.');
    return false;
  }

  try {
    await instance.authenticate();
    console.log('Connected to Postgres (Supabase)');
    return true;
  } catch (error) {
    console.error('Error connecting to Postgres (Supabase):', error.message);
    return false;
  }
}

module.exports = {
  getSequelize,
  ensurePostgresConnected,
};
