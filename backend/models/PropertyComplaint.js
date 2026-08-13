const mongoose = require('mongoose');

const CATEGORIES = ['plumbing', 'electrical', 'cleaning', 'structural', 'appliance', 'pest_control', 'other'];
const STATUSES = ['received', 'in_progress', 'resolved', 'closed'];
const LOCATIONS = ['room', 'bathroom', 'kitchen', 'common_area', 'exterior', 'other'];

// A maintenance ticket raised against a property - separate from the
// society Complaint model, which is scoped to a Society instead. `tenant`
// is optional: an owner can log one against a specific tenant's unit, or
// just against the property in general.
const propertyComplaintSchema = new mongoose.Schema(
  {
    property: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true, index: true },
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    tenant: { type: mongoose.Schema.Types.ObjectId, ref: 'Tenant', default: null },
    description: { type: String, required: true, trim: true },
    location: { type: String, enum: LOCATIONS, default: null },
    category: { type: String, enum: CATEGORIES, required: true },
    urgent: { type: Boolean, default: false },
    status: { type: String, enum: STATUSES, default: 'received' },
  },
  { timestamps: true }
);

const PropertyComplaint = mongoose.model('PropertyComplaint', propertyComplaintSchema);
PropertyComplaint.CATEGORIES = CATEGORIES;
PropertyComplaint.STATUSES = STATUSES;
PropertyComplaint.LOCATIONS = LOCATIONS;

module.exports = PropertyComplaint;
