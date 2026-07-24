const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    firebaseUid: { type: String, required: true, unique: true, index: true },
    name: { type: String, trim: true },
    email: { type: String, lowercase: true, trim: true },
    phoneNumber: { type: String, trim: true },
    photoURL: { type: String },
    role: {
      type: String,
      enum: ['apartment_association', 'pg_owner', 'property_owner', 'tenant', 'service_provider'],
    },
    serviceType: {
      type: String,
      enum: ['plumber', 'electrician'],
    },
    society: { type: mongoose.Schema.Types.ObjectId, ref: 'Society', index: true },
    flatNumber: { type: String, trim: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
