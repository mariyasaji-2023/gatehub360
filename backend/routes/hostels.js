const express = require('express');
const requireAuth = require('../middleware/auth');
const Hostel = require('../models/Hostel');
const HostelEnquiry = require('../models/HostelEnquiry');
const User = require('../models/User');
const { notifyOwner } = require('../utils/pushNotify');

const router = express.Router();

function validRooms(rooms) {
  return (
    Array.isArray(rooms) &&
    rooms.length > 0 &&
    rooms.every(
      (r) =>
        r &&
        typeof r.name === 'string' &&
        r.name.trim() &&
        Number.isFinite(Number(r.price)) &&
        Number(r.price) >= 0 &&
        Number.isFinite(Number(r.available)) &&
        Number(r.available) >= 0
    )
  );
}

router.get('/', requireAuth, async (req, res) => {
  const filter = { active: true };
  if (req.query.type && req.query.type !== 'All') filter.type = req.query.type;
  if (req.query.gender && req.query.gender !== 'All') filter.gender = req.query.gender;
  const hostels = await Hostel.find(filter).sort({ createdAt: -1 });
  res.json({ hostels });
});

router.get('/mine', requireAuth, async (req, res) => {
  const hostels = await Hostel.find({ owner: req.user._id }).sort({ createdAt: -1 });
  const unreadCounts = await HostelEnquiry.aggregate([
    { $match: { owner: req.user._id, read: false } },
    { $group: { _id: '$hostel', count: { $sum: 1 } } },
  ]);
  const countByHostel = Object.fromEntries(unreadCounts.map((c) => [String(c._id), c.count]));
  const withUnread = hostels.map((h) => ({ ...h.toObject(), unreadEnquiries: countByHostel[String(h._id)] || 0 }));
  res.json({ hostels: withUnread });
});

router.get('/enquiries/unread-count', requireAuth, async (req, res) => {
  const count = await HostelEnquiry.countDocuments({ owner: req.user._id, read: false });
  res.json({ count });
});

router.get('/enquiries/mine', requireAuth, async (req, res) => {
  const enquiries = await HostelEnquiry.find({ owner: req.user._id })
    .populate('hostel', 'title')
    .sort({ createdAt: -1 });
  await HostelEnquiry.updateMany({ owner: req.user._id, read: false }, { $set: { read: true } });
  res.json({ enquiries });
});

router.get('/:id/enquiries', requireAuth, async (req, res) => {
  const hostel = await Hostel.findOne({ _id: req.params.id, owner: req.user._id });
  if (!hostel) {
    return res.status(404).json({ message: 'Listing not found' });
  }
  const enquiries = await HostelEnquiry.find({ hostel: hostel._id })
    .populate('hostel', 'title')
    .sort({ createdAt: -1 });
  await HostelEnquiry.updateMany({ hostel: hostel._id, read: false }, { $set: { read: true } });
  res.json({ enquiries });
});

router.post('/', requireAuth, async (req, res) => {
  if (req.user.role !== 'pg_owner') {
    return res.status(403).json({ message: 'Only PG/hostel owners can add listings' });
  }

  const { type, gender, title, location, about, contact, amenities, rooms, active } = req.body;
  if (!Hostel.TYPES.includes(type)) {
    return res.status(400).json({ message: 'Invalid listing type' });
  }
  if (!Hostel.GENDERS.includes(gender)) {
    return res.status(400).json({ message: 'Invalid gender option' });
  }
  if (!title || !location || !about || !contact) {
    return res.status(400).json({ message: 'Title, location, about and contact are required' });
  }
  if (!validRooms(rooms)) {
    return res.status(400).json({ message: 'At least one valid room option is required' });
  }

  const hostel = await Hostel.create({
    owner: req.user._id,
    type,
    gender,
    title,
    location,
    about,
    contact,
    amenities: Array.isArray(amenities) ? amenities.filter((a) => typeof a === 'string' && a.trim()) : [],
    rooms,
    active: active ?? true,
  });
  res.status(201).json({ hostel });
});

router.patch('/:id', requireAuth, async (req, res) => {
  const hostel = await Hostel.findOne({ _id: req.params.id, owner: req.user._id });
  if (!hostel) {
    return res.status(404).json({ message: 'Listing not found' });
  }

  const { type, gender, title, location, about, contact, amenities, rooms, active } = req.body;
  if (type !== undefined) {
    if (!Hostel.TYPES.includes(type)) return res.status(400).json({ message: 'Invalid listing type' });
    hostel.type = type;
  }
  if (gender !== undefined) {
    if (!Hostel.GENDERS.includes(gender)) return res.status(400).json({ message: 'Invalid gender option' });
    hostel.gender = gender;
  }
  if (rooms !== undefined) {
    if (!validRooms(rooms)) return res.status(400).json({ message: 'At least one valid room option is required' });
    hostel.rooms = rooms;
  }
  if (title !== undefined) hostel.title = title;
  if (location !== undefined) hostel.location = location;
  if (about !== undefined) hostel.about = about;
  if (contact !== undefined) hostel.contact = contact;
  if (amenities !== undefined) {
    hostel.amenities = Array.isArray(amenities) ? amenities.filter((a) => typeof a === 'string' && a.trim()) : [];
  }
  if (active !== undefined) hostel.active = active;

  await hostel.save();
  res.json({ hostel });
});

router.post('/:id/enquire', requireAuth, async (req, res) => {
  const { phone } = req.body;
  if (!phone) {
    return res.status(400).json({ message: 'Phone number is required' });
  }

  const hostel = await Hostel.findById(req.params.id);
  if (!hostel) {
    return res.status(404).json({ message: 'Listing not found' });
  }

  const owner = await User.findById(hostel.owner);
  if (!owner) {
    return res.status(404).json({ message: 'Listing owner not found' });
  }

  const enquiry = await HostelEnquiry.create({
    hostel: hostel._id,
    owner: owner._id,
    client: req.user._id,
    clientPhone: phone,
  });

  try {
    await notifyOwner(owner, {
      title: 'New PG/Hostel enquiry',
      body: `Someone is interested in "${hostel.title}". Contact: ${phone}`,
      data: { type: 'hostel_enquiry', hostelId: String(hostel._id) },
    });
  } catch (err) {
    console.error('Failed to send enquiry push notification:', err.message);
  }

  res.status(201).json({ enquiry });
});

router.delete('/:id', requireAuth, async (req, res) => {
  const result = await Hostel.deleteOne({ _id: req.params.id, owner: req.user._id });
  if (result.deletedCount === 0) {
    return res.status(404).json({ message: 'Listing not found' });
  }
  res.json({ success: true });
});

module.exports = router;
