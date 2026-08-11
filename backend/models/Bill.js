const mongoose = require('mongoose');

const billSchema = new mongoose.Schema(
  {
    society: { type: mongoose.Schema.Types.ObjectId, ref: 'Society', required: true, index: true },
    resident: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    flatNumber: { type: String, trim: true },
    month: { type: Number, required: true, min: 1, max: 12 },
    year: { type: Number, required: true },
    amount: { type: Number, required: true },
    status: { type: String, enum: ['unpaid', 'paid'], default: 'unpaid' },
    paidAt: { type: Date },
    razorpayPaymentId: { type: String }
  },
  { timestamps: true }
);

billSchema.index({ resident: 1, month: 1, year: 1 }, { unique: true });

module.exports = mongoose.model('Bill', billSchema);
