const express = require('express');
const requireAuth = require('../middleware/auth');
const Property = require('../models/Property');
const Enquiry = require('../models/Enquiry');
const User = require('../models/User');
const { notifyOwner } = require('../utils/pushNotify');

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
