const express = require('express');
const requireAuth = require('../middleware/auth');
const User = require('../models/User');

const router = express.Router();

const ROLES = ['apartment_association', 'pg_owner', 'property_owner', 'tenant', 'service_provider'];

router.get('/me', requireAuth, async (req, res) => {
  const { _id, name, email, phoneNumber, photoURL, role, serviceType } = req.user;
  res.json({ user: { id: _id, name, email, phoneNumber, photoURL, role, serviceType } });
});

router.patch('/role', requireAuth, async (req, res) => {
  const { role } = req.body;
  if (!ROLES.includes(role)) {
    return res.status(400).json({ message: 'Invalid role' });
  }

  const user = await User.findByIdAndUpdate(
    req.user._id,
    { $set: { role }, $unset: { serviceType: 1 } },
    { new: true }
  );
  const { _id, name, email, phoneNumber, photoURL } = user;
  res.json({ user: { id: _id, name, email, phoneNumber, photoURL, role: user.role, serviceType: user.serviceType } });
});

module.exports = router;
