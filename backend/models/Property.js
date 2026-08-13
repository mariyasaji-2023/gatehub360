const mongoose = require('mongoose');

const TYPES = ['Apartment', 'Villa', 'Plot', 'Commercial'];
const MODES = ['Buy', 'Rent', 'Sell', 'Commercial'];
const BHKS = ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'N/A'];
const AMENITIES = [
  'Parking',
  'Lift',
  'Power Backup',
  '24x7 Security',
  'CCTV',
  'Gym',
  'Swimming Pool',
  'Club House',
  "Children's Play Area",
  'Park/Garden',
  'Water Supply',
  'Gas Pipeline',
  'Intercom',
  'Fire Safety',
  'Furnished',
];

const propertySchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    type: { type: String, required: true, enum: TYPES },
    mode: { type: String, required: true, enum: MODES },
    title: { type: String, required: true, trim: true },
    location: { type: String, required: true, trim: true },
    price: { type: String, required: true, trim: true },
    bhk: { type: String, required: true, enum: BHKS },
    sqft: { type: String, required: true, trim: true },
    about: { type: String, required: true, trim: true },
    contact: { type: String, required: true, trim: true },
    active: { type: Boolean, default: true },
    // Photos of the property, added when the owner creates/edits the listing.
    // Stored as plain base64 (no data: URI prefix) so there's no dependency
    // on external file storage - fine at this app's scale since MAX_IMAGES
    // and per-image size are capped in the route handlers below.
    images: { type: [String], default: [] },
    // A walkthrough video, if the owner added one. Unlike images, video is
    // far too large to store inline in Mongo (16MB document limit) - the
    // app uploads it straight to Cloudinary and only the resulting hosted
    // URL is saved here.
    videoUrl: { type: String, default: null, trim: true },
    amenities: { type: [String], enum: AMENITIES, default: [] },
    // Floor names the owner has added for vacancy management (e.g. "Ground
    // Floor", "1st Floor") - order as added, individual Units reference these
    // by name rather than a separate Floor collection.
    floors: { type: [String], default: [] },
    vacancyPublishedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

const Property = mongoose.model('Property', propertySchema);
Property.TYPES = TYPES;
Property.MODES = MODES;
Property.BHKS = BHKS;
Property.AMENITIES = AMENITIES;

module.exports = Property;
