// Copies externally hosted image URLs into R2 and rewrites matching MongoDB values.
// Safe to re-run: existing R2 objects are skipped and rewritten URLs no longer match.
//
//   node scripts/migrateLegacyImagesToR2.js           report only
//   node scripts/migrateLegacyImagesToR2.js --apply   copy objects + rewrite URLs
//
// Required in backend/.env: MONGO_URI and LEGACY_IMAGE_HOST_SUFFIX (old image host).
// --apply also needs the R2 keys,
// R2_BUCKET, and R2_PUBLIC_URL used by the app.

require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const mongoose = require('mongoose');
const { S3Client, PutObjectCommand, HeadObjectCommand } = require('@aws-sdk/client-s3');

const APPLY = process.argv.includes('--apply');
const env = process.env;
const hostSuffix = (env.LEGACY_IMAGE_HOST_SUFFIX || '')
  .trim()
  .replace(/^\.+/, '')
  .toLowerCase();

if (!env.MONGO_URI) throw new Error('MONGO_URI is not set');
if (!hostSuffix) throw new Error('LEGACY_IMAGE_HOST_SUFFIX is not set');
if (APPLY) {
  for (const key of ['R2_ACCOUNT_ID', 'R2_ACCESS_KEY_ID', 'R2_SECRET_ACCESS_KEY', 'R2_BUCKET', 'R2_PUBLIC_URL']) {
    if (!env[key]) throw new Error(`${key} is not set`);
  }
}

const r2 = APPLY ? new S3Client({
  region: 'auto',
  endpoint: `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: { accessKeyId: env.R2_ACCESS_KEY_ID, secretAccessKey: env.R2_SECRET_ACCESS_KEY },
}) : null;
const publicPrefix = env.R2_PUBLIC_URL?.replace(/\/+$/, '') || '';

function getObjectKey(value) {
  if (typeof value !== 'string') return null;
  try {
    const url = new URL(value);
    if (!url.hostname.toLowerCase().endsWith(`.${hostSuffix}`)) return null;
    return decodeURIComponent(url.pathname.replace(/^\/+/, ''));
  } catch {
    return null;
  }
}

function publicUrl(key) {
  const encodedKey = key.split('/').map(encodeURIComponent).join('/');
  return `${publicPrefix}/${encodedKey}`;
}

function rewrite(value, stats) {
  if (typeof value === 'string') {
    const key = getObjectKey(value);
    if (!key) return value;
    stats.changed += 1;
    return publicUrl(key);
  }
  if (Array.isArray(value)) return value.map((item) => rewrite(item, stats));
  if (value && Object.getPrototypeOf(value) === Object.prototype) {
    return Object.fromEntries(Object.entries(value).map(([key, child]) => [key, rewrite(child, stats)]));
  }
  return value;
}

async function forEachCollection(callback) {
  const db = mongoose.connection.db;
  const collections = await db.listCollections({}, { nameOnly: true }).toArray();
  for (const { name } of collections) {
    if (name.startsWith('system.')) continue;
    await callback(db.collection(name), name);
  }
}

async function collectLegacyObjects() {
  const objects = new Map();
  let references = 0;
  await forEachCollection(async (collection) => {
    for await (const document of collection.find({})) {
      const scan = (value) => {
        if (typeof value === 'string') {
          const key = getObjectKey(value);
          if (key) {
            references += 1;
            objects.set(key, value);
          }
        } else if (Array.isArray(value)) {
          value.forEach(scan);
        } else if (value && Object.getPrototypeOf(value) === Object.prototype) {
          Object.values(value).forEach(scan);
        }
      };
      scan(document);
    }
  });
  return { objects, references };
}

async function copyObjects(objects) {
  let copied = 0;
  let skipped = 0;
  for (const [key, sourceUrl] of objects) {
    try {
      await r2.send(new HeadObjectCommand({ Bucket: env.R2_BUCKET, Key: key }));
      skipped += 1;
      continue;
    } catch (error) {
      if (!['NotFound', 'NoSuchKey', 'NotFoundException', '404'].includes(error.name) && error.$metadata?.httpStatusCode !== 404) {
        throw error;
      }
    }

    const response = await fetch(sourceUrl);
    if (!response.ok) throw new Error(`Could not download a source image (HTTP ${response.status})`);
    const body = Buffer.from(await response.arrayBuffer());
    await r2.send(new PutObjectCommand({
      Bucket: env.R2_BUCKET,
      Key: key,
      Body: body,
      ContentType: response.headers.get('content-type') || 'application/octet-stream',
    }));
    copied += 1;
    if (copied % 50 === 0) console.log(`  copied ${copied} objects...`);
  }
  console.log(`R2 objects: ${copied} copied, ${skipped} already present`);
}

async function rewriteDatabaseUrls() {
  await forEachCollection(async (collection, name) => {
    let changedDocuments = 0;
    let changedUrls = 0;
    for await (const document of collection.find({})) {
      const stats = { changed: 0 };
      const updated = rewrite(document, stats);
      if (!stats.changed) continue;
      changedDocuments += 1;
      changedUrls += stats.changed;
      if (APPLY) await collection.replaceOne({ _id: document._id }, updated);
    }
    if (changedDocuments) console.log(`${name}: ${changedUrls} URLs in ${changedDocuments} documents`);
  });
}

(async () => {
  console.log(APPLY ? 'APPLYING image migration' : 'DRY RUN (pass --apply to make changes)');
  await mongoose.connect(env.MONGO_URI, { tls: true, retryWrites: false, family: 4 });
  try {
    const { objects, references } = await collectLegacyObjects();
    console.log(`Found ${references} image URL references to ${objects.size} source objects.`);
    if (!APPLY) return;
    await copyObjects(objects);
    console.log('Rewriting database URLs:');
    await rewriteDatabaseUrls();
  } finally {
    await mongoose.disconnect();
  }
})().catch((error) => {
  console.error('Image migration failed:', error.message);
  process.exit(1);
});
