const express = require('express');
const requireAuth = require('../middleware/auth');
const Property = require('../models/Property');
const Enquiry = require('../models/Enquiry');
const User = require('../models/User');
const Tenant = require('../models/Tenant');
const RentPayment = require('../models/RentPayment');
const Unit = require('../models/Unit');
const Announcement = require('../models/Announcement');
const PropertyJoinRequest = require('../models/PropertyJoinRequest');
const PropertyComplaint = require('../models/PropertyComplaint');
const { notifyOwner } = require('../utils/pushNotify');
const { dueMonths, isCurrentMonth } = require('../utils/rentDues');

const router = express.Router();

// Property photos are stored inline as base64 strings (see models/Property.js)
// rather than in external file storage, so cap how many/how large to keep
// documents and request payloads reasonable.
const MAX_IMAGES = 6;
const MAX_IMAGE_LENGTH = 2_000_000; // ~1.5MB decoded, base64-encoded

function validateImages(images) {
  if (images === undefined) return { valid: true, images: undefined };
  if (!Array.isArray(images)) return { valid: false, message: 'Images must be a list' };
  if (images.length > MAX_IMAGES) return { valid: false, message: `You can add up to ${MAX_IMAGES} photos` };
  for (const img of images) {
    if (typeof img !== 'string' || !img) return { valid: false, message: 'Invalid photo data' };
    if (img.length > MAX_IMAGE_LENGTH) return { valid: false, message: 'One of the photos is too large' };
  }
  return { valid: true, images };
}

// The video itself is uploaded straight from the app to Cloudinary (see
// lib/services/cloudinary_api.dart) - the backend only ever sees and stores
// the resulting hosted URL, so this is just a sanity check, not a real
// upload path.
function validateVideoUrl(videoUrl) {
  if (videoUrl === undefined || videoUrl === null || videoUrl === '') return { valid: true, videoUrl: null };
  if (typeof videoUrl !== 'string' || videoUrl.length > 500 || !/^https:\/\//.test(videoUrl)) {
    return { valid: false, message: 'Invalid video URL' };
  }
  return { valid: true, videoUrl };
}

function validateAmenities(amenities) {
  if (amenities === undefined) return { valid: true, amenities: undefined };
  if (!Array.isArray(amenities)) return { valid: false, message: 'Amenities must be a list' };
  for (const a of amenities) {
    if (!Property.AMENITIES.includes(a)) return { valid: false, message: `Invalid amenity: ${a}` };
  }
  return { valid: true, amenities: [...new Set(amenities)] };
}

// Shared by POST /:id/tenants and the join-request approval route below -
// both end up creating the same kind of Tenant record. joinCode collisions
// are rare (6 chars, 32-char alphabet) but the unique index can still
// reject one - regenerate and retry rather than fail the whole request.
async function createTenantRecord(tenantData) {
  let tenant;
  for (let attempt = 0; attempt < 5 && !tenant; attempt += 1) {
    try {
      tenant = await Tenant.create(tenantData);
    } catch (err) {
      if (err.code === 11000 && attempt < 4) continue;
      throw err;
    }
  }
  return tenant;
}

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

  const { type, mode, title, location, address, price, bhk, sqft, about, contact, active, images, videoUrl, amenities } = req.body;
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
  const imagesCheck = validateImages(images);
  if (!imagesCheck.valid) {
    return res.status(400).json({ message: imagesCheck.message });
  }
  const videoCheck = validateVideoUrl(videoUrl);
  if (!videoCheck.valid) {
    return res.status(400).json({ message: videoCheck.message });
  }
  const amenitiesCheck = validateAmenities(amenities);
  if (!amenitiesCheck.valid) {
    return res.status(400).json({ message: amenitiesCheck.message });
  }

  const property = await Property.create({
    owner: req.user._id,
    type,
    mode,
    title,
    location,
    address: typeof address === 'string' ? address : '',
    price,
    bhk,
    sqft,
    about,
    contact,
    active: active ?? true,
    images: imagesCheck.images ?? [],
    videoUrl: videoCheck.videoUrl,
    amenities: amenitiesCheck.amenities ?? [],
  });
  res.status(201).json({ property });
});

router.patch('/:id', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }

  const { type, mode, title, location, address, price, bhk, sqft, about, contact, active, images, videoUrl, amenities } = req.body;
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
  if (address !== undefined) property.address = typeof address === 'string' ? address : '';
  if (price !== undefined) property.price = price;
  if (sqft !== undefined) property.sqft = sqft;
  if (about !== undefined) property.about = about;
  if (contact !== undefined) property.contact = contact;
  if (active !== undefined) property.active = active;
  if (images !== undefined) {
    const imagesCheck = validateImages(images);
    if (!imagesCheck.valid) return res.status(400).json({ message: imagesCheck.message });
    property.images = imagesCheck.images;
  }
  if (videoUrl !== undefined) {
    const videoCheck = validateVideoUrl(videoUrl);
    if (!videoCheck.valid) return res.status(400).json({ message: videoCheck.message });
    property.videoUrl = videoCheck.videoUrl;
  }
  if (amenities !== undefined) {
    const amenitiesCheck = validateAmenities(amenities);
    if (!amenitiesCheck.valid) return res.status(400).json({ message: amenitiesCheck.message });
    property.amenities = amenitiesCheck.amenities;
  }

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

  const {
    name,
    phone,
    email,
    roomNumber,
    moveInDate,
    monthlyRent,
    altPhone,
    moveOutDate,
    stayType,
    lockInMonths,
    noticePeriodDays,
    agreementPeriodMonths,
    rentDueDay,
    securityDeposit,
    referredBy,
    remarks,
    tenantType,
    otherDetails,
  } = req.body;
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
  let parsedMoveOut;
  if (moveOutDate) {
    parsedMoveOut = new Date(moveOutDate);
    if (Number.isNaN(parsedMoveOut.getTime())) {
      return res.status(400).json({ message: 'Invalid move-out date' });
    }
  }
  if (stayType !== undefined && !Tenant.STAY_TYPES.includes(stayType)) {
    return res.status(400).json({ message: 'Invalid stay type' });
  }
  if (tenantType !== undefined && tenantType !== null && !Tenant.TENANT_TYPES.includes(tenantType)) {
    return res.status(400).json({ message: 'Invalid tenant type' });
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
    altPhone: altPhone || undefined,
    moveOutDate: parsedMoveOut,
    stayType: stayType || undefined,
    lockInMonths: lockInMonths ?? undefined,
    noticePeriodDays: noticePeriodDays ?? undefined,
    agreementPeriodMonths: agreementPeriodMonths ?? undefined,
    rentDueDay: rentDueDay ?? undefined,
    securityDeposit: securityDeposit ?? undefined,
    referredBy: referredBy || undefined,
    remarks: remarks || undefined,
    tenantType: tenantType || undefined,
    otherDetails: otherDetails || undefined,
  };

  const tenant = await createTenantRecord(tenantData);
  res.status(201).json({ tenant });
});

// --- Join requests (self-service) ---
//
// A prospective tenant fills out the public web form at GET /invite?id=...
// (see backend/public/invite.html and GET/POST routes below) without
// needing the app or an account. The owner reviews it here and approving
// creates a real Tenant record - same shape POST /:id/tenants makes, just
// triggered from the other side.

router.get('/:id/join-requests', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const joinRequests = await PropertyJoinRequest.find({ property: property._id, status: 'pending' }).sort({ createdAt: 1 });
  res.json({ joinRequests });
});

router.patch('/:id/join-requests/:reqId', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const joinRequest = await PropertyJoinRequest.findOne({ _id: req.params.reqId, property: property._id, status: 'pending' });
  if (!joinRequest) {
    return res.status(404).json({ message: 'Request not found' });
  }

  const { status, monthlyRent } = req.body;
  if (!['approved', 'rejected'].includes(status)) {
    return res.status(400).json({ message: 'Invalid status' });
  }

  if (status === 'rejected') {
    joinRequest.status = 'rejected';
    await joinRequest.save();
    return res.json({ joinRequest });
  }

  // The requester's own "Rent Amount" field on the web form is optional -
  // if they (or the owner) never set one, the owner must supply it now,
  // same as it's required when adding a tenant manually.
  const rent = monthlyRent ?? joinRequest.monthlyRent;
  if (typeof rent !== 'number' || rent <= 0) {
    return res.status(400).json({ message: 'A valid monthly rent is required to approve this request' });
  }

  const tenant = await createTenantRecord({
    property: property._id,
    owner: req.user._id,
    name: joinRequest.name,
    phone: joinRequest.phone,
    altPhone: joinRequest.altPhone || undefined,
    roomNumber: joinRequest.roomNumber || undefined,
    monthlyRent: rent,
    securityDeposit: joinRequest.securityDeposit ?? undefined,
    moveInDate: joinRequest.moveInDate || new Date(),
  });

  joinRequest.status = 'approved';
  joinRequest.tenant = tenant._id;
  await joinRequest.save();
  res.json({ joinRequest, tenant });
});

// --- Public invite (no auth - reached via the QR/link before the visitor
// has signed in or even installed the app) ---

router.get('/:id/public', async (req, res) => {
  const property = await Property.findById(req.params.id).select('title location type');
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  res.json({ property });
});

// Vacant units only, and only label/floor - same privacy shape as the
// society equivalent (GET /society/flats/public).
router.get('/:id/units/public', async (req, res) => {
  const property = await Property.findById(req.params.id).select('_id');
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const units = await Unit.find({ property: property._id, status: 'vacant' }).select('label floor').sort({ floor: 1, label: 1 });
  res.json({ units });
});

router.post('/:id/join-requests-public', async (req, res) => {
  const property = await Property.findById(req.params.id).select('_id');
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const { name, phone, altPhone, roomNumber, monthlyRent, securityDeposit, moveInDate } = req.body;
  if (!name || !phone) {
    return res.status(400).json({ message: 'Name and phone are required' });
  }

  let parsedMoveIn;
  if (moveInDate) {
    parsedMoveIn = new Date(moveInDate);
    if (Number.isNaN(parsedMoveIn.getTime())) parsedMoveIn = undefined;
  }

  const joinRequest = await PropertyJoinRequest.create({
    property: property._id,
    name,
    phone,
    altPhone: altPhone || undefined,
    roomNumber: roomNumber || undefined,
    monthlyRent: typeof monthlyRent === 'number' ? monthlyRent : undefined,
    securityDeposit: typeof securityDeposit === 'number' ? securityDeposit : undefined,
    moveInDate: parsedMoveIn,
  });
  res.status(201).json({ joinRequest });
});

// --- Announcements ---
//
// An owner's broadcast to tenants of one property. Only reaches tenants who
// have actually joined that property (linked their account with the join
// code shared in AddTenantScreen) - see GET /my-rent/announcements, which
// is scoped to the signed-in tenant's own linked+active Tenant records.

router.get('/:id/announcements', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const announcements = await Announcement.find({ property: property._id }).sort({ createdAt: -1 });
  res.json({ announcements });
});

router.post('/:id/announcements', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const { title, message } = req.body;
  if (!title || !message) {
    return res.status(400).json({ message: 'Title and message are required' });
  }
  const announcement = await Announcement.create({ property: property._id, owner: req.user._id, title, message });
  res.status(201).json({ announcement });
});

router.delete('/:id/announcements/:announcementId', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const result = await Announcement.deleteOne({ _id: req.params.announcementId, property: property._id });
  if (result.deletedCount === 0) {
    return res.status(404).json({ message: 'Announcement not found' });
  }
  res.json({ success: true });
});

// --- Complaints (maintenance tickets) ---

router.get('/:id/complaints', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const complaints = await PropertyComplaint.find({ property: property._id }).populate('tenant', 'name phone').sort({ createdAt: -1 });
  res.json({ complaints });
});

router.get('/:id/complaints/count', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const count = await PropertyComplaint.countDocuments({ property: property._id, status: { $ne: 'resolved' } });
  res.json({ count });
});

router.post('/:id/complaints', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const { description, location, category, urgent, tenantId } = req.body;
  if (!description || !category) {
    return res.status(400).json({ message: 'Description and issue type are required' });
  }
  if (!PropertyComplaint.CATEGORIES.includes(category)) {
    return res.status(400).json({ message: 'Invalid issue type' });
  }
  if (location !== undefined && location !== null && !PropertyComplaint.LOCATIONS.includes(location)) {
    return res.status(400).json({ message: 'Invalid issue location' });
  }

  let tenant;
  if (tenantId) {
    tenant = await Tenant.findOne({ _id: tenantId, property: property._id });
    if (!tenant) {
      return res.status(404).json({ message: 'Tenant not found' });
    }
  }

  const complaint = await PropertyComplaint.create({
    property: property._id,
    owner: req.user._id,
    tenant: tenant?._id,
    description,
    location: location || undefined,
    category,
    urgent: Boolean(urgent),
  });
  res.status(201).json({ complaint });
});

router.patch('/:id/complaints/:complaintId', requireAuth, async (req, res) => {
  const property = await Property.findOne({ _id: req.params.id, owner: req.user._id });
  if (!property) {
    return res.status(404).json({ message: 'Property not found' });
  }
  const complaint = await PropertyComplaint.findOne({ _id: req.params.complaintId, property: property._id });
  if (!complaint) {
    return res.status(404).json({ message: 'Complaint not found' });
  }
  const { status } = req.body;
  if (!PropertyComplaint.STATUSES.includes(status)) {
    return res.status(400).json({ message: 'Invalid status' });
  }
  complaint.status = status;
  await complaint.save();
  res.json({ complaint });
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
