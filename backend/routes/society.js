const express = require('express');
const requireAuth = require('../middleware/auth');
const Society = require('../models/Society');
const Notice = require('../models/Notice');
const Complaint = require('../models/Complaint');
const Bill = require('../models/Bill');
const Flat = require('../models/Flat');
const JoinRequest = require('../models/JoinRequest');
const User = require('../models/User');

const router = express.Router();

function requireSociety(req, res, next) {
  if (!req.user.society) {
    return res.status(400).json({ message: 'Join or create a society first' });
  }
  next();
}

function isAssociation(req) {
  return req.user.role === 'apartment_association';
}

router.get('/me', requireAuth, async (req, res) => {
  if (!req.user.society) {
    return res.json({ society: null });
  }
  const society = await Society.findById(req.user.society);
  res.json({ society });
});

// A society is "yours" to manage if you created it or entered it with its invite code.
function managesFilter(userId) {
  return { $or: [{ admins: userId }, { createdBy: userId }] };
}

router.get('/mine', requireAuth, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only an apartment association can manage multiple societies' });
  }
  const societies = await Society.find(managesFilter(req.user._id)).sort({ createdAt: -1 });
  res.json({ societies, activeId: req.user.society });
});

router.post('/switch', requireAuth, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only an apartment association can switch societies' });
  }
  const { societyId } = req.body;
  const society = await Society.findOne({ _id: societyId, ...managesFilter(req.user._id) });
  if (!society) {
    return res.status(404).json({ message: 'Society not found' });
  }
  await User.findByIdAndUpdate(req.user._id, { $set: { society: society._id } });
  res.json({ society });
});

router.post('/', requireAuth, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only an apartment association can create a society' });
  }

  const { name, address, pincode, area, city, state } = req.body;
  if (!name || !address || !pincode || !area || !city || !state) {
    return res.status(400).json({ message: 'Name, address, pincode, area, city and state are all required' });
  }

  const society = await Society.create({
    name,
    address,
    pincode,
    area,
    city,
    state,
    createdBy: req.user._id,
    admins: [req.user._id],
  });
  await User.findByIdAndUpdate(req.user._id, { $set: { society: society._id } });
  res.status(201).json({ society });
});

// Lets an apartment association become a co-manager of a society it didn't create,
// using the same invite code residents use to join.
router.post('/enter', requireAuth, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only an apartment association can enter a society this way' });
  }
  const { code } = req.body;
  if (!code) {
    return res.status(400).json({ message: 'Invite code is required' });
  }

  const society = await Society.findOne({ code: String(code).toUpperCase().trim() });
  if (!society) {
    return res.status(404).json({ message: 'Invalid invite code' });
  }

  if (!society.admins.some((id) => id.equals(req.user._id)) && !society.createdBy.equals(req.user._id)) {
    society.admins.push(req.user._id);
    await society.save();
  }
  await User.findByIdAndUpdate(req.user._id, { $set: { society: society._id } });
  res.json({ society });
});

// Same as /enter, but for a society found via /search (by id, not invite code).
router.post('/enter-by-search', requireAuth, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only an apartment association can enter a society this way' });
  }
  const { societyId } = req.body;
  if (!societyId) {
    return res.status(400).json({ message: 'Society is required' });
  }

  const society = await Society.findById(societyId);
  if (!society) {
    return res.status(404).json({ message: 'Society not found' });
  }

  if (!society.admins.some((id) => id.equals(req.user._id)) && !society.createdBy.equals(req.user._id)) {
    society.admins.push(req.user._id);
    await society.save();
  }
  await User.findByIdAndUpdate(req.user._id, { $set: { society: society._id } });
  res.json({ society });
});

router.post('/join', requireAuth, async (req, res) => {
  if (isAssociation(req) || req.user.role === 'service_provider') {
    return res.status(403).json({ message: 'This role cannot join a society' });
  }
  if (req.user.society) {
    return res.status(400).json({ message: 'You already belong to a society' });
  }

  const { code, flatId } = req.body;
  if (!code || !flatId) {
    return res.status(400).json({ message: 'Invite code and flat are required' });
  }

  const society = await Society.findOne({ code: String(code).toUpperCase().trim() });
  if (!society) {
    return res.status(404).json({ message: 'Invalid invite code' });
  }

  const flat = await Flat.findOneAndUpdate(
    { _id: flatId, society: society._id, status: 'vacant' },
    { $set: { status: 'occupied', resident: req.user._id } },
    { new: true }
  );
  if (!flat) {
    return res.status(409).json({ message: 'That flat is no longer available. Please pick another.' });
  }

  try {
    await User.findByIdAndUpdate(req.user._id, { $set: { society: society._id, flatNumber: flat.flatNumber } });
  } catch (err) {
    await Flat.findByIdAndUpdate(flat._id, { $set: { status: 'vacant' }, $unset: { resident: '' } });
    throw err;
  }
  // A search-based request made before this instant code-join is now stale.
  await JoinRequest.deleteMany({ requester: req.user._id, status: 'pending' });
  res.json({ society });
});

// Lets a resident find a society by name/address instead of needing the invite code.
// Only exposes name/address - the invite code stays private to the code-based join/enter flows.
router.get('/search', requireAuth, async (req, res) => {
  const q = String(req.query.q || '').trim();
  if (!q) {
    const societies = await Society.find().select('name address area city state').sort({ name: 1 }).limit(50);
    return res.json({ societies });
  }
  const regex = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
  const societies = await Society.find({ $or: [{ name: regex }, { address: regex }, { area: regex }, { city: regex }] })
    .select('name address area city state')
    .limit(20);
  res.json({ societies });
});

// Join Requests
//
// Search-based joins go through an approval step (unlike code-based /join,
// which is instant since having the code already implies the association
// shared it directly). The flat stays vacant while a request is pending, so
// several people can request a popular flat and the association picks one -
// the actual claim only happens atomically at approval time.

router.post('/join-requests', requireAuth, async (req, res) => {
  if (isAssociation(req) || req.user.role === 'service_provider') {
    return res.status(403).json({ message: 'This role cannot join a society' });
  }
  if (req.user.society) {
    return res.status(400).json({ message: 'You already belong to a society' });
  }

  const { societyId } = req.body;
  if (!societyId) {
    return res.status(400).json({ message: 'Society is required' });
  }
  const society = await Society.findById(societyId);
  if (!society) {
    return res.status(404).json({ message: 'Society not found' });
  }

  const existingPending = await JoinRequest.findOne({ requester: req.user._id, status: 'pending' });
  if (existingPending) {
    return res.status(400).json({ message: 'You already have a pending request' });
  }

  const joinRequest = await JoinRequest.create({ society: society._id, requester: req.user._id });
  res.status(201).json({ joinRequest });
});

router.get('/join-requests', requireAuth, requireSociety, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only the apartment association can view join requests' });
  }
  const joinRequests = await JoinRequest.find({ society: req.user.society, status: 'pending' })
    .populate('requester', 'name phoneNumber')
    .populate('flat', 'flatNumber')
    .sort({ createdAt: 1 });
  res.json({ joinRequests });
});

// The current user's most recent join request (any status), so the join
// screen can show "pending"/"declined" instead of the join form again.
router.get('/join-requests/mine', requireAuth, async (req, res) => {
  const joinRequest = await JoinRequest.findOne({ requester: req.user._id })
    .sort({ createdAt: -1 })
    .populate('flat', 'flatNumber')
    .populate('society', 'name');
  res.json({ joinRequest });
});

router.patch('/join-requests/:id', requireAuth, requireSociety, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only the apartment association can respond to join requests' });
  }
  const joinRequest = await JoinRequest.findOne({ _id: req.params.id, society: req.user.society });
  if (!joinRequest || joinRequest.status !== 'pending') {
    return res.status(404).json({ message: 'Join request not found' });
  }

  const { status } = req.body;
  if (!['approved', 'rejected'].includes(status)) {
    return res.status(400).json({ message: 'Invalid status' });
  }

  if (status === 'rejected') {
    joinRequest.status = 'rejected';
    await joinRequest.save();
    return res.json({ joinRequest });
  }

  await User.findByIdAndUpdate(joinRequest.requester, { $set: { society: req.user.society } });
  joinRequest.status = 'approved';
  await joinRequest.save();
  res.json({ joinRequest });
});

router.post('/leave', requireAuth, requireSociety, async (req, res) => {
  if (isAssociation(req)) {
    return res.status(403).json({ message: 'Use switch to move between societies you manage' });
  }
  await Flat.updateOne(
    { society: req.user.society, resident: req.user._id },
    { $set: { status: 'vacant' }, $unset: { resident: '' } }
  );
  // Any other request they'd made elsewhere before joining this society is
  // now stale - clear it so the join screen doesn't resurface it as still
  // "pending" once they're back to browsing/joining.
  await JoinRequest.deleteMany({ requester: req.user._id, status: 'pending' });
  await User.findByIdAndUpdate(req.user._id, { $unset: { society: '', flatNumber: '' } });
  res.json({ success: true });
});

router.get('/residents', requireAuth, requireSociety, async (req, res) => {
  const residents = await User.find({ society: req.user.society })
    .select('name phoneNumber flatNumber role')
    .sort({ flatNumber: 1 });
  res.json({ residents });
});

// Flats

router.get('/flats', requireAuth, requireSociety, async (req, res) => {
  const flats = await Flat.find({ society: req.user.society })
    .populate('resident', 'name')
    .populate('interestedBy', 'name')
    .sort({ flatNumber: 1 });
  const withInterest = flats.map((f) => ({
    ...f.toObject(),
    interestedNames: f.interestedBy.map((u) => u.name),
    amInterested: f.interestedBy.some((u) => u._id.equals(req.user._id)),
  }));
  res.json({ flats: withInterest });
});

// Lets a prospective resident browse a society's flats before joining, via
// either its invite code or its id (from /search). Deliberately excludes
// resident identity - only occupied/vacant status is exposed publicly.
router.get('/flats/public', requireAuth, async (req, res) => {
  const { code, societyId } = req.query;
  let society;
  if (code) {
    society = await Society.findOne({ code: String(code).toUpperCase().trim() });
  } else if (societyId) {
    society = await Society.findById(societyId);
  }
  if (!society) {
    return res.status(404).json({ message: 'Society not found' });
  }
  const flats = await Flat.find({ society: society._id }).select('flatNumber status').sort({ flatNumber: 1 });
  res.json({ society: { id: society._id, name: society.name }, flats });
});

// A resident flagging interest in a vacant flat within their own society -
// just a note for the association to see and follow up on manually, not a
// formal request/approval flow.
router.post('/flats/:id/interest', requireAuth, requireSociety, async (req, res) => {
  if (isAssociation(req)) {
    return res.status(403).json({ message: 'Only residents can express interest in a flat' });
  }
  const flat = await Flat.findOne({ _id: req.params.id, society: req.user.society });
  if (!flat || flat.status !== 'vacant') {
    return res.status(400).json({ message: 'That flat is not available' });
  }
  await Flat.updateOne({ _id: flat._id }, { $addToSet: { interestedBy: req.user._id } });
  res.json({ success: true });
});

router.post('/flats', requireAuth, requireSociety, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only the apartment association can add flats' });
  }
  const { flatNumber } = req.body;
  if (!flatNumber) {
    return res.status(400).json({ message: 'Flat number is required' });
  }
  try {
    const flat = await Flat.create({ society: req.user.society, flatNumber });
    res.status(201).json({ flat });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({ message: 'That flat number already exists' });
    }
    throw err;
  }
});

router.post('/flats/bulk', requireAuth, requireSociety, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only the apartment association can add flats' });
  }
  const { flatNumbers } = req.body;
  if (!Array.isArray(flatNumbers) || flatNumbers.length === 0) {
    return res.status(400).json({ message: 'At least one flat number is required' });
  }

  const cleaned = [...new Set(flatNumbers.map((n) => String(n).trim()).filter(Boolean))];
  const existing = await Flat.find({ society: req.user.society, flatNumber: { $in: cleaned } }).select('flatNumber');
  const existingSet = new Set(existing.map((f) => f.flatNumber));
  const toCreate = cleaned.filter((n) => !existingSet.has(n)).map((flatNumber) => ({ society: req.user.society, flatNumber }));

  const flats = toCreate.length > 0 ? await Flat.insertMany(toCreate) : [];
  res.status(201).json({ flats, created: flats.length, skipped: cleaned.length - flats.length });
});

router.patch('/flats/:id', requireAuth, requireSociety, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only the apartment association can update flats' });
  }
  const flat = await Flat.findOne({ _id: req.params.id, society: req.user.society });
  if (!flat) {
    return res.status(404).json({ message: 'Flat not found' });
  }

  const { status } = req.body;
  if (!Flat.STATUSES.includes(status)) {
    return res.status(400).json({ message: 'Invalid status' });
  }

  if (status === 'vacant' && flat.resident) {
    await User.findByIdAndUpdate(flat.resident, { $unset: { society: '', flatNumber: '' } });
    flat.resident = null;
  }
  flat.status = status;
  await flat.save();
  res.json({ flat });
});

router.delete('/flats/:id', requireAuth, requireSociety, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only the apartment association can delete flats' });
  }
  const flat = await Flat.findOne({ _id: req.params.id, society: req.user.society });
  if (!flat) {
    return res.status(404).json({ message: 'Flat not found' });
  }
  if (flat.status === 'occupied') {
    return res.status(400).json({ message: 'Free the flat before deleting it' });
  }
  await flat.deleteOne();
  res.json({ success: true });
});

// Notices

router.get('/notices', requireAuth, requireSociety, async (req, res) => {
  const notices = await Notice.find({ society: req.user.society }).sort({ createdAt: -1 });
  res.json({ notices });
});

router.post('/notices', requireAuth, requireSociety, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only the apartment association can post notices' });
  }
  const { title, message } = req.body;
  if (!title || !message) {
    return res.status(400).json({ message: 'Title and message are required' });
  }
  const notice = await Notice.create({ society: req.user.society, title, message, createdBy: req.user._id });
  res.status(201).json({ notice });
});

router.delete('/notices/:id', requireAuth, requireSociety, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only the apartment association can delete notices' });
  }
  const result = await Notice.deleteOne({ _id: req.params.id, society: req.user.society });
  if (result.deletedCount === 0) {
    return res.status(404).json({ message: 'Notice not found' });
  }
  res.json({ success: true });
});

// Complaints

router.get('/complaints', requireAuth, requireSociety, async (req, res) => {
  const filter = { society: req.user.society };
  if (!isAssociation(req)) filter.raisedBy = req.user._id;
  const complaints = await Complaint.find(filter).sort({ createdAt: -1 });
  res.json({ complaints });
});

router.post('/complaints', requireAuth, requireSociety, async (req, res) => {
  const { title, description, category, priority } = req.body;
  if (!title || !description || !category) {
    return res.status(400).json({ message: 'Title, description and category are required' });
  }
  if (!Complaint.CATEGORIES.includes(category)) {
    return res.status(400).json({ message: 'Invalid category' });
  }

  const complaint = await Complaint.create({
    society: req.user.society,
    raisedBy: req.user._id,
    flatNumber: req.user.flatNumber,
    title,
    description,
    category,
    priority: Complaint.PRIORITIES.includes(priority) ? priority : 'normal',
  });
  res.status(201).json({ complaint });
});

router.patch('/complaints/:id', requireAuth, requireSociety, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only the apartment association can update complaints' });
  }
  const complaint = await Complaint.findOne({ _id: req.params.id, society: req.user.society });
  if (!complaint) {
    return res.status(404).json({ message: 'Complaint not found' });
  }

  const { status, priority } = req.body;
  if (status !== undefined) {
    if (!Complaint.STATUSES.includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }
    complaint.status = status;
  }
  if (priority !== undefined) {
    if (!Complaint.PRIORITIES.includes(priority)) {
      return res.status(400).json({ message: 'Invalid priority' });
    }
    complaint.priority = priority;
  }
  await complaint.save();
  res.json({ complaint });
});

// Bills

router.get('/bills', requireAuth, requireSociety, async (req, res) => {
  const filter = { society: req.user.society };
  if (!isAssociation(req)) filter.resident = req.user._id;
  const bills = await Bill.find(filter).sort({ year: -1, month: -1 });
  res.json({ bills });
});

router.post('/bills/generate', requireAuth, requireSociety, async (req, res) => {
  if (!isAssociation(req)) {
    return res.status(403).json({ message: 'Only the apartment association can generate bills' });
  }
  const { month, year, amount } = req.body;
  if (!month || !year || !amount) {
    return res.status(400).json({ message: 'Month, year and amount are required' });
  }

  const residents = await User.find({ society: req.user.society, role: { $ne: 'apartment_association' } });
  const existing = await Bill.find({ society: req.user.society, month, year }).select('resident');
  const alreadyBilled = new Set(existing.map((b) => b.resident.toString()));

  const toCreate = residents
    .filter((r) => !alreadyBilled.has(r._id.toString()))
    .map((r) => ({
      society: req.user.society,
      resident: r._id,
      flatNumber: r.flatNumber,
      month,
      year,
      amount,
    }));

  const bills = toCreate.length > 0 ? await Bill.insertMany(toCreate) : [];
  res.status(201).json({ bills, created: bills.length, skipped: residents.length - bills.length });
});

router.patch('/bills/:id/paid', requireAuth, requireSociety, async (req, res) => {
  const filter = { _id: req.params.id, society: req.user.society };
  if (!isAssociation(req)) filter.resident = req.user._id;

  const bill = await Bill.findOne(filter);
  if (!bill) {
    return res.status(404).json({ message: 'Bill not found' });
  }

  const { status, paymentId } = req.body;
  if (status !== undefined) {
    if (!['paid', 'unpaid'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }
    bill.status = status;
    bill.paidAt = status === 'paid' ? new Date() : undefined;
  } else {
    bill.status = 'paid';
    bill.paidAt = new Date();
  }
  if (paymentId) bill.razorpayPaymentId = paymentId;
  await bill.save();
  res.json({ bill });
});

module.exports = router;
