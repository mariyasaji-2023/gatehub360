const mongoose = require('mongoose');

const STATUSES = ['pending', 'approved', 'rejected'];

const joinRequestSchema = new mongoose.Schema(
  {
    society: { type: mongoose.Schema.Types.ObjectId, ref: 'Society', required: true, index: true },
    flat: { type: mongoose.Schema.Types.ObjectId, ref: 'Flat', default: null },
    requester: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    status: { type: String, enum: STATUSES, default: 'pending' },
  },
  { timestamps: true }
);

const JoinRequest = mongoose.model('JoinRequest', joinRequestSchema);
JoinRequest.STATUSES = STATUSES;

module.exports = JoinRequest;
