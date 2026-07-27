const mongoose = require('mongoose');

const TYPES = ['Apartment', 'Villa', 'Plot', 'Commercial'];
const MODES = ['Buy', 'Rent', 'Sell', 'Commercial'];
const BHKS = ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'N/A'];

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
  },
  { timestamps: true }
);

const Property = mongoose.model('Property', propertySchema);
Property.TYPES = TYPES;
Property.MODES = MODES;
Property.BHKS = BHKS;

module.exports = Property;
