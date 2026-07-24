const mongoose = require('mongoose');

const STATUSES = ['vacant', 'occupied'];

const flatSchema = new mongoose.Schema(
  {
    society: { type: mongoose.Schema.Types.ObjectId, ref: 'Society', required: true, index: true },
    flatNumber: { type: String, required: true, trim: true },
    status: { type: String, enum: STATUSES, default: 'vacant' },
    resident: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    // Residents who've flagged interest in a vacant flat - a lightweight
    // inquiry note for the association, not a formal request/approval flow.
    interestedBy: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], default: [] },
  },
  { timestamps: true }
);

flatSchema.index({ society: 1, flatNumber: 1 }, { unique: true });

const Flat = mongoose.model('Flat', flatSchema);
Flat.STATUSES = STATUSES;

module.exports = Flat;
