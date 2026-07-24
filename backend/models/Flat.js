const mongoose = require('mongoose');

const STATUSES = ['vacant', 'occupied'];

const flatSchema = new mongoose.Schema(
  {
    society: { type: mongoose.Schema.Types.ObjectId, ref: 'Society', required: true, index: true },
    flatNumber: { type: String, required: true, trim: true },
    status: { type: String, enum: STATUSES, default: 'vacant' },
    resident: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  },
  { timestamps: true }
);

flatSchema.index({ society: 1, flatNumber: 1 }, { unique: true });

const Flat = mongoose.model('Flat', flatSchema);
Flat.STATUSES = STATUSES;

module.exports = Flat;
