const mongoose = require('mongoose');

const STATUSES = ['active', 'moved_out'];

// Last 10 digits of a phone number, ignoring +91/spacing/formatting - the
// stable key we match a signed-in `tenant` role User against, since sign-in
// is phone-OTP verified. Same digits in, same digits out, regardless of how
// the owner typed the number.
function last10(phone) {
  return (phone || '').replace(/\D/g, '').slice(-10);
}

// 6-character code a tenant types into the app to link their account to
// this record. Alphabet excludes visually ambiguous characters (0/O, 1/I/L)
// since owners read this out loud or share it over text.
const CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
function generateJoinCode() {
  let code = '';
  for (let i = 0; i < 6; i += 1) {
    code += CODE_ALPHABET[Math.floor(Math.random() * CODE_ALPHABET.length)];
  }
  return code;
}

// Core tenant record for a property owner's own unit — separate from the
// `tenant` User role, which just means "someone browsing listings". A tenant
// only becomes payable-by-them once they enter `joinCode` in the app, which
// sets `linkedUser` (see routes/rent.js) - the actual authorization boundary
// for everything rent-related. `phone`/`phoneDigits` are kept as contact
// info the owner sees, not used for matching. KYC and rental agreement
// upload are a follow-up once file storage is wired up.
const tenantSchema = new mongoose.Schema(
  {
    property: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true, index: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    phoneDigits: { type: String, index: true },
    email: { type: String, trim: true },
    roomNumber: { type: String, trim: true },
    monthlyRent: { type: Number, required: true, min: 0 },
    moveInDate: { type: Date, required: true },
    moveOutDate: { type: Date, default: null },
    status: { type: String, enum: STATUSES, default: 'active' },
    joinCode: { type: String, unique: true, index: true },
    linkedUser: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null, index: true },
  },
  { timestamps: true }
);

tenantSchema.pre('validate', function setPhoneDigits(next) {
  this.phoneDigits = last10(this.phone);
  if (!this.joinCode) this.joinCode = generateJoinCode();
  next();
});

const Tenant = mongoose.model('Tenant', tenantSchema);
Tenant.STATUSES = STATUSES;
Tenant.last10 = last10;
Tenant.generateJoinCode = generateJoinCode;

module.exports = Tenant;
