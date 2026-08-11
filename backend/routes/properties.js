const express = require('express');
const requireAuth = require('../middleware/auth');
const Property = require('../models/Property');
const Enquiry = require('../models/Enquiry');
const User = require('../models/User');
const Tenant = require('../models/Tenant');
const RentPayment = require('../models/RentPayment');
const Unit = require('../models/Unit');
const { notifyOwner } = require('../utils/pushNotify');
const { dueMonths, isCurrentMonth } = require('../utils/rentDues');

const router = express.Router();

router.get('/', requireAuth, async (req, res) => {
  const filter = { active: true };
  if (req.query.type && req.query.type !== 'All') filter.type = req.query.type;
  const properties = await Property.find(filter).sort({ createdAt: -1 });
  res.json({ properties });
});

router.get('/mine', requireAuth, async (req, res) => {
  const properties = await Property.find({ owner: req.user._id }).sort({ createdAt: -1 });
  const unreadCounts = await Enquiry.aggregate([
    { $match: { owner: req.user._id, read: false } },
    { $group: { _id: '$property', count: { $sum: 1 } } },
  ]);
  const countByProperty = Object.fromEntries(unreadCounts.map((c) => [String(c._id), c.count]));
  const withUnread = properties.map((p) => ({ ...p.toObject(), unreadEnquiries: countByProperty[String(p._id)] || 0 }));
  res.json({ properties: withUnread });
});

router.get('/enquiries/unread-count', requireAuth, async (req, res) => {
  const count = await Enquiry.countDocuments({ owner: req.user._id, read: false });
  res.json({ count });
});

router.get('/enquiries/mine', requireAuth, async (req, res) => {
  const enquiries = await Enquiry.find({ owner: req.user._id })
    .populate('property', 'title')
    .sort({ createdAt: -1 });
  await Enquiry.updateMany({ owner: req.user._id, read: false }, { $set: { read: true } });
  res.json({ enquiries });
});

router.get('/:id/enquiries', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const enquiries = await Enquiry.find({ property: property._id })
    .populate('property', 'title')
    .sort({ createdAt: -1 });
  await Enquiry.updateMany({ property: property._id, read: false }, { $set: { read: true } });
  res.json({ enquiries });
});

router.post('/', requireAuth, async (req, res) => {
  if (req.user.role !== 'property_owner') {
    return res.status(403).json({ message: 'Only property owners can add properties' });
  }

  const { type, mode, title, location, price, bhk, sqft, about, contact, active } = req.body;
  if (!Property.TYPES.includes(type)) {
    return res.status(400).json({ message: 'Invalid property type' });
  }
  if (!Property.MODES.includes(mode)) {
    return res.status(400).json({ message: 'Invalid listing mode' });
  }
  if (!Property.BHKS.includes(bhk)) {
    return res.status(400).json({ message: 'Invalid BHK' });
  }
  if (!title || !location || !price || !sqft || !about || !contact) {
    return res.status(400).json({ message: 'All fields are required' });
  }

  const property = await Property.create({
    owner: req.user._id,
    type,
    mode,
    title,
    location,
    price,
    bhk,
    sqft,
    about,
    contact,
    active: active ?? true,
  });
  res.status(201).json({ property });
});

router.patch('/:id', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }

  const { type, mode, title, location, price, bhk, sqft, about, contact, active } = req.body;
  if (type !== undefined) {
    if (!Property.TYPES.includes(type)) return res.status(400).json({ message: 'Invalid property type' });
    property.type = type;
  }
  if (mode !== undefined) {
    if (!Property.MODES.includes(mode)) return res.status(400).json({ message: 'Invalid listing mode' });
    property.mode = mode;
  }
  if (bhk !== undefined) {
    if (!Property.BHKS.includes(bhk)) return res.status(400).json({ message: 'Invalid BHK' });
    property.bhk = bhk;
  }
  if (title !== undefined) property.title = title;
  if (location !== undefined) property.location = location;
  if (price !== undefined) property.price = price;
  if (sqft !== undefined) property.sqft = sqft;
  if (about !== undefined) property.about = about;
  if (contact !== undefined) property.contact = contact;
  if (active !== undefined) property.active = active;

  await property.save();
  res.json({ property });
});

// --- Vacancy management (floors + units) ---

router.post('/:id/floors', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }

  const { floors } = req.body;
  if (!Array.isArray(floors) || floors.length === 0) {
    return res.status(400).json({ message: 'At least one floor is required' });
  }

  const existing = new Set(property.floors);
  for (const floor of floors) {
    if (typeof floor === 'string' && floor.trim() && !existing.has(floor)) {
      property.floors.push(floor);
      existing.add(floor);
    }
  }
  await property.save();
  res.json({ floors: property.floors });
});

router.get('/:id/vacancy', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }

  const units = await Unit.find({ property: property._id });
  const byFloor = new Map(property.floors.map((floor) => [floor, { floor, totalUnits: 0, totalBeds: 0, occupiedUnits: 0, vacantUnits: 0 }]));
  for (const unit of units) {
    const entry = byFloor.get(unit.floor) ?? { floor: unit.floor, totalUnits: 0, totalBeds: 0, occupiedUnits: 0, vacantUnits: 0 };
    entry.totalUnits += 1;
    entry.totalBeds += unit.beds;
    if (unit.status === 'occupied') entry.occupiedUnits += 1;
    else entry.vacantUnits += 1;
    byFloor.set(unit.floor, entry);
  }
  const floors = property.floors.map((floor) => byFloor.get(floor));

  const totals = floors.reduce(
    (acc, f) => ({
      totalUnits: acc.totalUnits + f.totalUnits,
      totalBeds: acc.totalBeds + f.totalBeds,
      occupiedUnits: acc.occupiedUnits + f.occupiedUnits,
      vacantUnits: acc.vacantUnits + f.vacantUnits,
    }),
    { totalUnits: 0, totalBeds: 0, occupiedUnits: 0, vacantUnits: 0 }
  );

  res.json({
    floors,
    totalFloors: property.floors.length,
    filledFloors: floors.filter((f) => f.totalUnits > 0).length,
    ...totals,
    vacancyPublishedAt: property.vacancyPublishedAt,
  });
});

router.post('/:id/units', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }

  const { floor, rows } = req.body;
  if (!floor || !property.floors.includes(floor)) {
    return res.status(400).json({ message: 'Floor must be added to the property first' });
  }
  if (!Array.isArray(rows) || rows.length === 0) {
    return res.status(400).json({ message: 'At least one unit row is required' });
  }

  const docs = [];
  for (const row of rows) {
    const { type, label, beds, count } = row;
    if (!Unit.TYPES.includes(type)) return res.status(400).json({ message: `Invalid unit type: ${type}` });
    if (!label || !Number.isInteger(beds) || beds < 1 || !Number.isInteger(count) || count < 1) {
      return res.status(400).json({ message: 'Invalid unit row' });
    }
    for (let i = 0; i < count; i++) {
      docs.push({ property: property._id, floor, type, label, beds });
    }
  }

  const units = await Unit.insertMany(docs);
  res.status(201).json({ units });
});

router.get('/:id/units', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const filter = { property: property._id };
  if (req.query.floor) filter.floor = req.query.floor;
  const units = await Unit.find(filter).sort({ floor: 1, createdAt: 1 });
  res.json({ units });
});

router.patch('/:id/units/:unitId', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const { status } = req.body;
  if (!Unit.STATUSES.includes(status)) {
    return res.status(400).json({ message: 'Invalid status' });
  }
  const unit = await Unit.findOneAndUpdate(
    { _id: req.params.unitId, property: property._id },
    { $set: { status } },
    { new: true }
  );
  if (!unit) {
    return res.status(404).json({ message: 'Unit not found' });
  }
  res.json({ unit });
});

router.post('/:id/publish-vacancy', requireAuth, async (req, res) => {
  const property = await Property.findOneAndUpdate(
    { _id: req.params.id, owner: req.user._id },
    { $set: { vacancyPublishedAt: new Date() } },
    { new: true }
  );
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  res.json({ vacancyPublishedAt: property.vacancyPublishedAt });
});

// --- Tenant management ---

router.get('/:id/tenants', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const tenants = await Tenant.find({ property: property._id }).sort({ createdAt: -1 });
  const payments = await RentPayment.find({ property: property._id });

  // Cheap per-tenant rent status inline, so the Collect Payment list doesn't
  // need a follow-up call per tenant just to show a paid/pending badge.
  const withRentStatus = tenants.map((t) => {
    const tenantPayments = payments.filter((p) => String(p.tenant) === String(t._id));
    const due = dueMonths(t.moveInDate, tenantPayments);
    return { ...t.toObject(), pendingMonths: due.length, pendingAmount: due.length * t.monthlyRent };
  });
  res.json({ tenants: withRentStatus });
});

router.post('/:id/tenants', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }

  const { name, phone, email, roomNumber, moveInDate, monthlyRent } = req.body;
  if (!name || !phone || !moveInDate || !monthlyRent) {
    return res.status(400).json({ message: 'Name, phone, move-in date, and monthly rent are required' });
  }
  const parsedMoveIn = new Date(moveInDate);
  if (Number.isNaN(parsedMoveIn.getTime())) {
    return res.status(400).json({ message: 'Invalid move-in date' });
  }
  if (typeof monthlyRent !== 'number' || monthlyRent <= 0) {
    return res.status(400).json({ message: 'Invalid monthly rent' });
  }

  const tenantData = {
    property: property._id,
    owner: req.user._id,
    name,
    phone,
    email: email || undefined,
    roomNumber: roomNumber || undefined,
    moveInDate: parsedMoveIn,
    monthlyRent,
  };

  // joinCode collisions are rare (6 chars, 32-char alphabet) but the unique
  // index can still reject one - regenerate and retry rather than fail the
  // whole request.
  let tenant;
  for (let attempt = 0; attempt < 5 && !tenant; attempt += 1) {
    try {
      tenant = await Tenant.create(tenantData);
    } catch (err) {
      if (err.code === 11000 && attempt < 4) continue;
      throw err;
    }
  }
  res.status(201).json({ tenant });
});

// --- Rent collection (owner side) ---

// One tenant's full rent picture: which months are still due, and their
// paid history - powers the tenant detail view under "Collect Payment".
router.get('/:id/tenants/:tenantId/rent', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const tenant = await Tenant.findOne({ _id: req.params.tenantId, property: property._id });
  if (!tenant) {
    return res.status(404).json({ message: 'Tenant not found' });
  }

  const payments = await RentPayment.find({ tenant: tenant._id }).sort({ year: -1, month: -1 });
  const due = dueMonths(tenant.moveInDate, payments).map((m) => ({ ...m, amount: tenant.monthlyRent }));

  res.json({ tenant, due, payments });
});

// Owner records rent they collected themselves (cash/UPI/bank transfer
// arranged outside the app) for one month.
router.patch('/:id/tenants/:tenantId/rent', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const tenant = await Tenant.findOne({ _id: req.params.tenantId, property: property._id });
  if (!tenant) {
    return res.status(404).json({ message: 'Tenant not found' });
  }

  const { month, year, method } = req.body;
  if (!month || !year) {
    return res.status(400).json({ message: 'Month and year are required' });
  }
  if (!['cash', 'upi', 'bank_transfer'].includes(method)) {
    return res.status(400).json({ message: 'Invalid collection method' });
  }

  try {
    const payment = await RentPayment.create({
      tenant: tenant._id,
      property: property._id,
      owner: req.user._id,
      month,
      year,
      amount: tenant.monthlyRent,
      method,
    });
    res.status(201).json({ payment });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ message: 'That month is already marked paid' });
    }
    throw err;
  }
});

// Dashboard aggregate across every active tenant of this property.
router.get('/:id/rent-summary', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }

  const tenants = await Tenant.find({ property: property._id, status: 'active' });
  const payments = await RentPayment.find({ property: property._id });

  let thisMonthCollection = 0;
  let todayCollection = 0;
  let thisMonthDues = 0;
  let allTimeDues = 0;

  const todayKey = new Date().toDateString();
  for (const payment of payments) {
    if (isCurrentMonth(payment.month, payment.year)) thisMonthCollection += payment.amount;
    if (payment.paidAt && payment.paidAt.toDateString() === todayKey) todayCollection += payment.amount;
  }

  for (const tenant of tenants) {
    const tenantPayments = payments.filter((p) => String(p.tenant) === String(tenant._id));
    const due = dueMonths(tenant.moveInDate, tenantPayments);
    allTimeDues += due.length * tenant.monthlyRent;
    if (due.some((d) => isCurrentMonth(d.month, d.year))) thisMonthDues += tenant.monthlyRent;
  }

  res.json({ todayCollection, thisMonthCollection, thisMonthDues, allTimeDues, activeTenants: tenants.length });
});

router.post('/:id/enquire', requireAuth, async (req, res) => {
  const { phone } = req.body;
  if (!phone) {
    return res.status(400).json({ message: 'Phone number is required' });
  }

  const property = await Property.findById(req.params.id);
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }

  const owner = await User.findById(property.owner);
  if (!owner) {
    return res.status(404).json({ message: 'Property owner not found' });
  }

  const enquiry = await Enquiry.create({
    property: property._id,
    owner: owner._id,
    client: req.user._id,
    clientPhone: phone,
  });

  try {
    await notifyOwner(owner, {
      title: 'New property enquiry',
      body: `Someone is interested in "${property.title}". Contact: ${phone}`,
      data: { type: 'property_enquiry', propertyId: String(property._id) },
    });
  } catch (err) {
    console.error('Failed to send enquiry push notification:', err.message);
  }

  res.status(201).json({ enquiry });
});

router.delete('/:id', requireAuth, async (req, res) => {
  const result = await Property.deleteOne({ _id: req.params.id, owner: req.user._id });
  if (result.deletedCount === 0) {
    return res.status(404).json({ message: 'Property not found' });
  }
  res.json({ success: true });
});

module.exports = router;
