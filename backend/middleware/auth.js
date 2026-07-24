const { getAuth } = require('../config/firebase');
const User = require('../models/User');

async function requireAuth(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'No token provided' });
  }

  const idToken = header.split(' ')[1];
  let decoded;
  try {
    decoded = await getAuth().verifyIdToken(idToken);
  } catch (err) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }

  const fields = {
    name: decoded.name,
    email: decoded.email,
    phoneNumber: decoded.phone_number,
    photoURL: decoded.picture,
  };
  const set = Object.fromEntries(Object.entries(fields).filter(([, v]) => v !== undefined));

  const user = await User.findOneAndUpdate(
    { firebaseUid: decoded.uid },
    { $set: set, $setOnInsert: { firebaseUid: decoded.uid } },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );

  req.user = user;
  next();
}

module.exports = requireAuth;
