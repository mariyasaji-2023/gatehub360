const mongoose = require('mongoose');

const STATUSES = ['pending', 'approved', 'rejected'];

// A prospective tenant's self-submitted request to join a property, filled
// out on the public web form at GET /invite?id=<propertyId> (no sign-in
// required - that's the point, they may not have the app yet). The owner
// reviews it in-app and approves/rejects; approving creates a real Tenant
// record (see routes/properties.js) the same way adding one manually does,
// including a fresh join code the owner then shares back.
const propertyJoinRequestSchema = new mongoose.Schema(
  {
    property: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true, index: true },
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    altPhone: { type: String, trim: true },
    roomNumber: { type: String, trim: true },
    monthlyRent: { type: Number, default: null },
    securityDeposit: { type: Number, default: null },
    moveInDate: { type: Date, default: null },
    status: { type: String, enum: STATUSES, default: 'pending' },
    // Set when approved, so a re-fetch of an already-handled request can
    // still surface which Tenant record it became.
    tenant: { type: mongoose.Schema.Types.ObjectId, ref: 'Tenant', default: null },
  },
  { timestamps: true }
);

const PropertyJoinRequest = mongoose.model('PropertyJoinRequest', propertyJoinRequestSchema);
PropertyJoinRequest.STATUSES = STATUSES;

module.exports = PropertyJoinRequest;
