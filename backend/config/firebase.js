const path = require('path');
const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getMessaging } = require('firebase-admin/messaging');

if (!getApps().length) {
  // On hosts like Render the credentials file isn't deployed (it's gitignored),
  // so prefer the JSON pasted directly into an env var; fall back to a file on
  // disk for local dev.
  const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_JSON
    ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)
    : require(path.resolve(process.cwd(), process.env.FIREBASE_SERVICE_ACCOUNT_PATH));
  initializeApp({
    credential: cert(serviceAccount),
  });
}

module.exports = { getAuth, getMessaging };
