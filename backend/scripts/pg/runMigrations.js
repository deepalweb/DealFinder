// Applies any .sql file in backend/db/migrations not yet recorded in schema_migrations, in filename order.
require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
const fs = require('fs');
const path = require('path');
const { getSequelize } = require('../../services/postgres');

const MIGRATIONS_DIR = path.resolve(__dirname, '../../db/migrations');

async function run() {
  const sequelize = getSequelize();
  if (!sequelize) {
    console.error('DATABASE_URL not set. Aborting.');
    process.exit(1);
  }

  await sequelize.authenticate();

  await sequelize.query(`
    CREATE TABLE IF NOT EXISTS schema_migrations (
      filename TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ DEFAULT now()
    );
  `);

  const [appliedRows] = await sequelize.query('SELECT filename FROM schema_migrations;');
  const applied = new Set(appliedRows.map((r) => r.filename));

  const files = fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  for (const file of files) {
    if (applied.has(file)) {
      console.log(`Skipping already-applied migration: ${file}`);
      continue;
    }

    console.log(`Applying migration: ${file}`);
    const sql = fs.readFileSync(path.join(MIGRATIONS_DIR, file), 'utf8');

    const tx = await sequelize.transaction();
    try {
      await sequelize.query(sql, { transaction: tx });
      await sequelize.query(
        'INSERT INTO schema_migrations (filename) VALUES (:filename);',
        { replacements: { filename: file }, transaction: tx }
      );
      await tx.commit();
      console.log(`Applied: ${file}`);
    } catch (err) {
      await tx.rollback();
      console.error(`Failed to apply ${file}:`, err.message);
      process.exit(1);
    }
  }

  console.log('All migrations applied.');
  await sequelize.close();
}

run().catch((err) => {
  console.error('Migration runner failed:', err);
  process.exit(1);
});
