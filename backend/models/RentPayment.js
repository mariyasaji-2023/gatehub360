const mongoose = require('mongoose');

// Owner collected it in person (cash/UPI/bank transfer they arranged
// themselves) vs the tenant paid through the app's own Razorpay checkout.
const METHODS = ['cash', 'upi', 'bank_transfer', 'online'];

// One record per tenant per calendar month, created only once that month is
// actually paid — there's no separate "pending" document. Whether a month is
// due is computed on the fly from the tenant's moveInDate vs which months
// already have a paid record (see routes/properties.js and routes/rent.js).
const rentPaymentSchema = new mongoose.Schema(
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

rentPaymentSchema.index({ tenant: 1, month: 1, year: 1 }, { unique: true });

const RentPayment = mongoose.model('RentPayment', rentPaymentSchema);
RentPayment.METHODS = METHODS;

module.exports = RentPayment;
