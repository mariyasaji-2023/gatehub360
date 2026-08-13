const express = require('express');
const requireAuth = require('../middleware/auth');
const Tenant = require('../models/Tenant');
const RentPayment = require('../models/RentPayment');
const Property = require('../models/Property');
const Announcement = require('../models/Announcement');
const User = require('../models/User');
const { dueMonths } = require('../utils/rentDues');
const { notifyOwner } = require('../utils/pushNotify');

const router = express.Router();

const MONTH_NAMES = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

// A tenant only becomes payable-by-them once they enter the join code the
// owner shared with them (see POST /join below), which sets `linkedUser` -
// that's the authorization boundary for everything in this file. Replaces
// the old auto-match-by-phone-number, which could silently surface a
// stranger's rent data if the owner mistyped a number that happened to
// match someone else's verified login.
async function findMyTenantRecords(req) {
  return Tenant.find({ linkedUser: req.user._id, status: 'active' }).populate('property', 'title location');
}

router.get('/', requireAuth, async (req, res) => {
  const tenants = await findMyTenantRecords(req);
  const results = await Promise.all(
    tenants.map(async (tenant) => {
      const payments = await RentPayment.find({ tenant: tenant._id }).sort({ year: -1, month: -1 });
      const due = dueMonths(tenant.moveInDate, payments).map((m) => ({ ...m, amount: tenant.monthlyRent }));
      return {
        tenantId: tenant._id,
        property: tenant.property,
        roomNumber: tenant.roomNumber,
        monthlyRent: tenant.monthlyRent,
        moveInDate: tenant.moveInDate,
        due,
        payments,
      };
    })
  );
  res.json({ rentals: results });
});

// Announcements posted by owners for properties this tenant has actually
// joined (linked their account to via join code) - the same authorization
// boundary as findMyTenantRecords, so a tenant never sees announcements for
// a property they haven't linked to.
router.get('/announcements', requireAuth, async (req, res) => {
  const tenants = await findMyTenantRecords(req);
  const propertyIds = tenants.map((t) => t.property._id);
  const announcements = await Announcement.find({ property: { $in: propertyIds } })
    .populate('property', 'title')
    .sort({ createdAt: -1 });
  res.json({ announcements });
});

// Tenant enters the code shown on the owner's tenant list to link their
// signed-in account to that tenant record - from the detail page of the
// specific property they found by browsing, so `propertyId` (when sent) is
// checked to make sure the code actually belongs to that property, not
// just accepted blind. Idempotent for the same user so re-entering the
// same code (e.g. after reinstalling) doesn't error.
router.post('/join', requireAuth, async (req, res) => {
  const { code, propertyId } = req.body;
  if (!code) {
    return res.status(400).json({ message: 'Join code is required' });
  }

  const tenant = await Tenant.findOne({ joinCode: String(code).toUpperCase().trim() });
  if (!tenant) {
    return res.status(404).json({ message: 'Invalid join code' });
  }
  if (propertyId && String(tenant.property) !== String(propertyId)) {
    return res.status(400).json({ message: 'This code is for a different property' });
  }
  if (tenant.linkedUser && String(tenant.linkedUser) !== String(req.user._id)) {
    return res.status(409).json({ message: 'This code has already been used by another account' });
  }
  if (!tenant.linkedUser) {
    tenant.linkedUser = req.user._id;
    await tenant.save();
  }

  const property = await Property.findById(tenant.property);
  res.json({ tenantId: tenant._id, propertyTitle: property?.title });
});

// Called after the client has already run the Razorpay checkout + signature
// verification via POST /api/payments/order and /api/payments/verify - this
// just records the now-verified payment against the right tenant/month.
router.post('/:tenantId/pay', requireAuth, async (req, res) => {
  const tenant = await Tenant.findOne({ _id: req.params.tenantId, linkedUser: req.user._id, status: 'active' });
  if (!tenant) {
    return res.status(404).json({ message: 'Tenant record not found for your account' });
  }

  const { month, year, paymentId } = req.body;
  if (!month || !year || !paymentId) {
    return res.status(400).json({ message: 'Month, year, and paymentId are required' });
  }

  const property = await Property.findById(tenant.property);

  try {
    const payment = await RentPayment.create({
      tenant: tenant._id,
      property: tenant.property,
      owner: tenant.owner,
      month,
      year,
      amount: tenant.monthlyRent,
      method: 'online',
      razorpayPaymentId: paymentId,
    });
    res.status(201).json({ payment, propertyTitle: property?.title });

    // Owner sees the payment either way next time they open the app (both
    // sides read the same RentPayment records) - this push just means they
    // don't have to go looking for it. Sent after responding to the tenant
    // so a slow/failed notification never delays or breaks their checkout.
    try {
      const owner = await User.findById(tenant.owner);
      if (owner) {
        await notifyOwner(owner, {
          title: 'Rent received',
          body: `${tenant.name} paid ₹${tenant.monthlyRent} for ${MONTH_NAMES[month - 1]} ${year} (${property?.title ?? 'your property'})`,
          data: { type: 'rent_paid', propertyId: String(tenant.property), tenantId: String(tenant._id) },
        });
      }
    } catch (notifyErr) {
      console.error('Failed to send rent payment push notification:', notifyErr.message);
    }
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ message: 'That month is already marked paid' });
    }
    throw err;
  }
});

module.exports = router;
