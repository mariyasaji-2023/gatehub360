const mongoose = require('mongoose');

// A visitor logged against a property - entryTime is set the moment the
// owner logs them in; exitTime stays null until they're checked out, which
// is what distinguishes "currently inside" from history.
const visitorSchema = new mongoose.Schema(
  {
    property: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true, index: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    name: { type: String, required: true, trim: true },
    phone: { type: String, trim: true },
    purpose: { type: String, trim: true },
    // Who they're visiting - free text (tenant name/room), not a hard
    // reference, since a visitor might be here for the owner or nobody
    // specific (e.g. a delivery, a technician).
    meetingName: { type: String, trim: true },
    entryTime: { type: Date, default: Date.now },
    exitTime: { type: Date, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Visitor', visitorSchema);
