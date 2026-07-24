const mongoose = require('mongoose');

const CATEGORIES = [
  'plumbing',
  'electrician',
  'ac-service',
  'painting',
  'cleaning',
  'carpentry',
  'upvc-windows',
  'cctv',
  'locksmith',
  'bathroom',
];

const serviceSchema = new mongoose.Schema(
  {
    provider: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    providerName: { type: String, trim: true },
    categorySlug: { type: String, required: true, enum: CATEGORIES },
    price: { type: String, required: true, trim: true },
    desc: { type: String, required: true, trim: true },
    active: { type: Boolean, default: true },
  },
  { timestamps: true }
);

serviceSchema.index({ provider: 1, categorySlug: 1 }, { unique: true });

const Service = mongoose.model('Service', serviceSchema);
Service.CATEGORIES = CATEGORIES;

module.exports = Service;
