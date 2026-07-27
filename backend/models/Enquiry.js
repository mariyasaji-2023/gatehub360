const mongoose = require('mongoose');

const enquirySchema = new mongoose.Schema(
  {
    property: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true, index: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    client: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    clientPhone: { type: String, required: true, trim: true },
    read: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Enquiry', enquirySchema);
