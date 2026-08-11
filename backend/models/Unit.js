const mongoose = require('mongoose');

const TYPES = ['Room', 'RK', 'BHK', 'Studio Apartment'];
const STATUSES = ['vacant', 'occupied'];

// One row an owner adds under "Add Units" becomes `count` of these — each a
// separately trackable bed/unit so vacancy status can be flipped per-unit.
const unitSchema = new mongoose.Schema(
  {
    property: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true, index: true },
    floor: { type: String, required: true, trim: true },
    type: { type: String, required: true, enum: TYPES },
    label: { type: String, required: true, trim: true },
    beds: { type: Number, required: true, min: 1 },
    status: { type: String, enum: STATUSES, default: 'vacant' },
  },
  { timestamps: true }
);

const Unit = mongoose.model('Unit', unitSchema);
Unit.TYPES = TYPES;
Unit.STATUSES = STATUSES;

module.exports = Unit;
