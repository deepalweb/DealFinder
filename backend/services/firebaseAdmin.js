const admin = require('firebase-admin');

let attemptedInitialization = false;

function buildCredential() {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (!projectId || !clientEmail || !privateKey) {
    return null;
  }

  return admin.credential.cert({
    projectId,
    clientEmail,
    privateKey: privateKey.replace(/\\n/g, '\n'),
  });
}

function ensureFirebaseAdminInitialized() {
  if (admin.apps.length > 0) {
    return true;
  }

  if (attemptedInitialization) {
    return false;
  }

  attemptedInitialization = true;

  try {
    const credential = buildCredential();
    if (!credential) {
      console.warn('Firebase Admin: Missing credentials. Push delivery will be unavailable until credentials are configured.');
      return false;
    }

    admin.initializeApp({ credential });
    console.log('Firebase Admin initialized successfully.');
    return true;
  } catch (error) {
    console.warn('Firebase Admin init failed:', error.message);
    return false;
  }
}

module.exports = {
  admin,
  ensureFirebaseAdminInitialized,
};
