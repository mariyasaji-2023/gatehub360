const mongoose = require('mongoose');

// A property owner's broadcast message to their tenants — same idea as
// Notice.js for societies, but scoped to a Property instead. Only reaches
// tenants whose Tenant record has been linked (see routes/rent.js), i.e.
// tenants who've actually joined that property with their join code.
const announcementSchema = new mongoose.Schema(
  {
    property: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true, index: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    title: { type: String, required: true, trim: true },
    message: { type: String, required: true, trim: true },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Announcement', announcementSchema);
