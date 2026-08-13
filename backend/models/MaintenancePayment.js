const mongoose = require('mongoose');

// Same shape as RentPayment, kept as its own model/collection (rather than
// a `type` flag on RentPayment) so its unique per-month index can't collide
// with a rent payment for the same tenant/month, and so a maintenance
// feature rollback never risks touching real rent records.
const METHODS = ['cash', 'upi', 'bank_transfer', 'online'];

const maintenancePaymentSchema = new mongoose.Schema(
  {
    tenant: { type: mongoose.Schema.Types.ObjectId, ref: 'Tenant', required: true, index: true },
    property: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true, index: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    month: { type: Number, required: true, min: 1, max: 12 },
    year: { type: Number, required: true },
    amount: { type: Number, required: true },
    method: { type: String, required: true, enum: METHODS },
    razorpayPaymentId: { type: String },
    paidAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

maintenancePaymentSchema.index({ tenant: 1, month: 1, year: 1 }, { unique: true });

const MaintenancePayment = mongoose.model('MaintenancePayment', maintenancePaymentSchema);
MaintenancePayment.METHODS = METHODS;

module.exports = MaintenancePayment;
