const mongoose = require('mongoose');

const emergencyAlertSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  rideId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Ride',
  },
  type: {
    type: String,
    enum: ['accident', 'harassment', 'medical', 'vehicle_issue', 'other'],
    required: true,
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true,
    },
    address: String,
  },
  description: {
    type: String,
    maxlength: 500,
  },
  status: {
    type: String,
    enum: ['active', 'responded', 'resolved', 'false_alarm'],
    default: 'active',
  },
  // Emergency contacts notified
  contactsNotified: [{
    name: String,
    phone: String,
    relationship: String,
    notifiedAt: Date,
  }],
  // Response tracking
  respondedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', // Admin or support staff
  },
  respondedAt: Date,
  resolution: String,
  // Audio/Video evidence
  evidence: [{
    type: {
      type: String,
      enum: ['audio', 'video', 'image'],
    },
    url: String,
    uploadedAt: {
      type: Date,
      default: Date.now,
    },
  }],
  // Priority level
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'critical'],
    default: 'high',
  },
}, {
  timestamps: true,
});

// Geospatial index
emergencyAlertSchema.index({ location: '2dsphere' });
emergencyAlertSchema.index({ userId: 1, createdAt: -1 });
emergencyAlertSchema.index({ status: 1, priority: -1 });
emergencyAlertSchema.index({ rideId: 1 });

module.exports = mongoose.model('EmergencyAlert', emergencyAlertSchema);
