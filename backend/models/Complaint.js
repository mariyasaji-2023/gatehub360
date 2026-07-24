const mongoose = require('mongoose');

const CATEGORIES = ['plumbing', 'electrical', 'cleaning', 'security', 'parking', 'noise', 'other'];
const STATUSES = ['open', 'in_progress', 'resolved'];
const PRIORITIES = ['normal', 'urgent'];

const complaintSchema = new mongoose.Schema(
  {
    society: { type: mongoose.Schema.Types.ObjectId, ref: 'Society', required: true, index: true },
    raisedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    flatNumber: { type: String, trim: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, required: true, trim: true },
    category: { type: String, required: true, enum: CATEGORIES },
    status: { type: String, enum: STATUSES, default: 'open' },
    priority: { type: String, enum: PRIORITIES, default: 'normal' },
  },
  { timestamps: true }
);

const Complaint = mongoose.model('Complaint', complaintSchema);
Complaint.CATEGORIES = CATEGORIES;
Complaint.STATUSES = STATUSES;
Complaint.PRIORITIES = PRIORITIES;

module.exports = Complaint;
