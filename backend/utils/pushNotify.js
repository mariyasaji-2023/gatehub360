const { getMessaging } = require('../config/firebase');
const User = require('../models/User');

// Sends a push notification to an owner's registered devices, and prunes
// any tokens FCM reports as no longer valid.
async function notifyOwner(owner, { title, body, data }) {
  if (!owner.fcmTokens?.length) return;

  const response = await getMessaging().sendEachForMulticast({
    tokens: owner.fcmTokens,
    notification: { title, body },
    data,
  });

  const staleTokens = response.responses
    .map((r, i) => (r.success ? null : owner.fcmTokens[i]))
    .filter((t) => t !== null);
  if (staleTokens.length) {
    await User.findByIdAndUpdate(owner._id, { $pullAll: { fcmTokens: staleTokens } });
  }
}

module.exports = { notifyOwner };
