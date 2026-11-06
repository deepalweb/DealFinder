module.exports = {
  VAPID_PUBLIC_KEY: process.env.VAPID_PUBLIC_KEY || '',
  VAPID_PRIVATE_KEY: process.env.VAPID_PRIVATE_KEY || '',
  // Sent to browsers, so restrict this key by website in Google Cloud.
  GOOGLE_MAPS_WEB_API_KEY: process.env.GOOGLE_MAPS_WEB_API_KEY || process.env.GOOGLE_MAPS_API_KEY || '',
  GOOGLE_CLIENT_ID:
    process.env.GOOGLE_CLIENT_ID ||
    '434034339931-01174qocrg92p7f3dck1e46el25nfc56.apps.googleusercontent.com'
};
