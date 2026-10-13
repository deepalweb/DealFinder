// Copies only map keys into ignored platform config; never prints credentials.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const env = Object.fromEntries(fs.readFileSync(path.join(root, 'backend/.env'), 'utf8')
  .split(/\r?\n/).filter(line => /^GOOGLE_MAPS_\w+=/.test(line.trim()))
  .map(line => { const index = line.indexOf('='); return [line.slice(0, index).trim(), line.slice(index + 1).trim().replace(/^(['"])(.*)\1$/, '$2')]; }));
function key(platform) {
  const value = process.env[`GOOGLE_MAPS_${platform}_API_KEY`] || env[`GOOGLE_MAPS_${platform}_API_KEY`] || env.GOOGLE_MAPS_API_KEY;
  if (!value || !/^[A-Za-z0-9_-]+$/.test(value)) throw new Error(`Missing or invalid Google Maps ${platform} key`);
  return value;
}
const secretsPath = path.join(root, 'mobile_app/android/secrets.properties');
let properties = fs.existsSync(secretsPath) ? fs.readFileSync(secretsPath, 'utf8') : '';
properties = properties.replace(/^GOOGLE_MAPS_API_KEY=.*(?:\r?\n|$)/gm, '');
fs.writeFileSync(secretsPath, `${properties.trimEnd()}\nGOOGLE_MAPS_API_KEY=${key('ANDROID')}\n`);
fs.writeFileSync(path.join(root, 'mobile_app/ios/Flutter/MapsConfig.xcconfig'), `GOOGLE_MAPS_API_KEY = ${key('IOS')}\n`);
const webPath = path.join(root, 'frontend-next/.env.local');
let webEnv = fs.existsSync(webPath) ? fs.readFileSync(webPath, 'utf8') : '';
webEnv = webEnv.replace(/^NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=.*(?:\r?\n|$)/gm, '');
fs.writeFileSync(webPath, `${webEnv.trimEnd()}\nNEXT_PUBLIC_GOOGLE_MAPS_API_KEY=${key('WEB')}\n`);
console.log('Google Maps keys configured in ignored Android, iOS, and web files.');
