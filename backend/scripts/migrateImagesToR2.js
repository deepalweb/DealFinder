// Copies every blob in the Azure Storage account to R2, then rewrites the image URLs
// stored in MongoDB to point at R2. Safe to re-run: existing R2 objects are skipped and
// already-rewritten URLs no longer match.
//
//   node scripts/migrateImagesToR2.js           report only, changes nothing
//   node scripts/migrateImagesToR2.js --apply   copy blobs + rewrite URLs
//
// Needs in backend/.env: MONGO_URI, AZURE_STORAGE_CONNECTION_STRING,
// R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET, R2_PUBLIC_URL
//
// URL mapping:  https://<acct>.blob.core.windows.net/<container>/<blob>
//            -> <R2_PUBLIC_URL>/<container>/<blob>
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const mongoose = require('mongoose');
const { BlobServiceClient } = require('@azure/storage-blob');
const { S3Client, PutObjectCommand, HeadObjectCommand } = require('@aws-sdk/client-s3');

const APPLY = process.argv.includes('--apply');
const env = process.env;

for (const key of ['MONGO_URI', 'AZURE_STORAGE_CONNECTION_STRING', 'R2_ACCOUNT_ID', 'R2_ACCESS_KEY_ID',
  'R2_SECRET_ACCESS_KEY', 'R2_BUCKET', 'R2_PUBLIC_URL']) {
  if (!env[key]) throw new Error(`${key} is not set`);
}

const azure = BlobServiceClient.fromConnectionString(env.AZURE_STORAGE_CONNECTION_STRING);
const r2 = new S3Client({
  region: 'auto',
  endpoint: `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: { accessKeyId: env.R2_ACCESS_KEY_ID, secretAccessKey: env.R2_SECRET_ACCESS_KEY },
});
const oldPrefix = azure.url.replace(/\/?$/, '/');
const newPrefix = env.R2_PUBLIC_URL.replace(/\/+$/, '') + '/';

async function existsInR2(key) {
  try {
    await r2.send(new HeadObjectCommand({ Bucket: env.R2_BUCKET, Key: key }));
    return true;
  } catch {
    return false;
  }
}

async function copyBlobs() {
  let copied = 0, skipped = 0, total = 0;
  for await (const container of azure.listContainers()) {
    const containerClient = azure.getContainerClient(container.name);
    for await (const blob of containerClient.listBlobsFlat()) {
      total += 1;
      const key = `${container.name}/${blob.name}`;
      if (!APPLY) continue;
      if (await existsInR2(key)) { skipped += 1; continue; }

      const buffer = await containerClient.getBlobClient(blob.name).downloadToBuffer();
      await r2.send(new PutObjectCommand({
        Bucket: env.R2_BUCKET,
        Key: key,
        Body: buffer,
        ContentType: blob.properties.contentType || 'application/octet-stream',
      }));
      copied += 1;
      if (copied % 50 === 0) console.log(`  copied ${copied}...`);
    }
  }
  console.log(`Blobs: ${total} in Azure` + (APPLY ? `, ${copied} copied, ${skipped} already in R2` : ''));
}

// Rewrites matching URL strings anywhere in a document; ObjectIds, Dates etc. pass through untouched.
function rewrite(value, stats) {
  if (typeof value === 'string') {
    if (value.startsWith(oldPrefix)) { stats.changed += 1; return newPrefix + value.slice(oldPrefix.length); }
    if (value.includes('.blob.core.windows.net')) stats.leftover += 1; // embedded in text, or another account
    return value;
  }
  if (Array.isArray(value)) return value.map((item) => rewrite(item, stats));
  if (value && Object.getPrototypeOf(value) === Object.prototype) {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, rewrite(v, stats)]));
  }
  return value;
}

async function rewriteUrls() {
  const db = mongoose.connection.db;
  const collections = await db.listCollections({}, { nameOnly: true }).toArray();
  let leftover = 0;

  for (const { name } of collections) {
    if (name.startsWith('system.')) continue;
    let docs = 0, urls = 0;
    for await (const doc of db.collection(name).find({})) {
      const stats = { changed: 0, leftover: 0 };
      const updated = rewrite(doc, stats);
      leftover += stats.leftover;
      if (!stats.changed) continue;
      docs += 1;
      urls += stats.changed;
      if (APPLY) await db.collection(name).replaceOne({ _id: doc._id }, updated);
    }
    if (docs) console.log(`  ${name}: ${urls} URLs in ${docs} documents`);
  }
  if (leftover) console.log(`  ${leftover} other Azure URLs not rewritten (inside text or a different storage account) - check manually`);
}

(async () => {
  console.log(APPLY ? 'APPLYING changes' : 'DRY RUN (pass --apply to make changes)');
  console.log(`${oldPrefix}  ->  ${newPrefix}`);
  await copyBlobs();

  // Same connection options as server.js (Azure Cosmos DB needs tls + no retryWrites).
  await mongoose.connect(env.MONGO_URI, { tls: true, retryWrites: false, family: 4 });
  console.log('Image URLs in MongoDB:');
  await rewriteUrls();
  await mongoose.disconnect();
})().catch((error) => {
  console.error('Migration failed:', error.message);
  process.exit(1);
});
