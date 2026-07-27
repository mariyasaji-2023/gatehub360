const mongoose = require('mongoose');

const TYPES = ['PG', 'Hostel', 'Service Apt', 'Flat'];
const GENDERS = ['Men', 'Women', 'Co-ed'];

const roomOptionSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    price: { type: Number, required: true, min: 0 },
    available: { type: Number, required: true, min: 0 },
  },
  { _id: false }
);

const hostelSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    type: { type: String, required: true, enum: TYPES },
    gender: { type: String, required: true, enum: GENDERS },
    title: { type: String, required: true, trim: true },
    location: { type: String, required: true, trim: true },
    about: { type: String, required: true, trim: true },
    contact: { type: String, required: true, trim: true },
    amenities: { type: [String], default: [] },
    // At least one room option is required - it's what a listing is actually
    // priced and booked against. The card/browse "starting price" is derived
    // from these rather than duplicated as a separate top-level field.
    rooms: { type: [roomOptionSchema], default: [] },
    active: { type: Boolean, default: true },
  },
  { timestamps: true }
);

const Hostel = mongoose.model('Hostel', hostelSchema);
Hostel.TYPES = TYPES;
Hostel.GENDERS = GENDERS;

module.exports = Hostel;
