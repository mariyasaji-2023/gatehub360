const mongoose = require('mongoose');
const crypto = require('crypto');

function generateCode() {
  return crypto.randomBytes(4).toString('hex').slice(0, 6).toUpperCase();
}

const societySchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    address: { type: String, required: true, trim: true },
    pincode: { type: String, required: true, trim: true },
    area: { type: String, required: true, trim: true },
    city: { type: String, required: true, trim: true },
    state: { type: String, required: true, trim: true },
    code: { type: String, required: true, unique: true, uppercase: true, trim: true, default: generateCode },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    admins: { type: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }], default: [] },
  },
  { timestamps: true }
);

const Society = mongoose.model('Society', societySchema);
Society.generateCode = generateCode;

module.exports = Society;
