const path = require('path');
const { initializeApp, cert, getApps } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

if (!getApps().length) {
  const serviceAccountPath = path.resolve(process.cwd(), process.env.FIREBASE_SERVICE_ACCOUNT_PATH);
  initializeApp({
    credential: cert(require(serviceAccountPath)),
  });
}

module.exports = { getAuth };
