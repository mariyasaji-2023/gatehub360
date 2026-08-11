const express = require('express');
const requireAuth = require('../middleware/auth');
const Tenant = require('../models/Tenant');
const RentPayment = require('../models/RentPayment');
const Property = require('../models/Property');
const { dueMonths } = require('../utils/rentDues');

const router = express.Router();

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
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ message: 'That month is already marked paid' });
    }
    throw err;
  }
});

module.exports = router;
