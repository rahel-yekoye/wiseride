const mongoose = require('mongoose');

const driverDocumentSchema = new mongoose.Schema({
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  documentType: {
    type: String,
    enum: ['license', 'vehicle_registration', 'insurance', 'id_card', 'profile_photo'],
    required: true
  },
  documentUrl: {
    type: String,
    required: true
  },
  documentNumber: {
    type: String,
    trim: true
  },
  expiryDate: {
    type: Date
  },
  verificationStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  },
  verifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  verifiedAt: {
    type: Date
  },
  rejectionReason: {
    type: String
  },
  metadata: {
    fileSize: Number,
    mimeType: String,
    originalName: String
  }
}, {
  timestamps: true
});

// Index for quick lookups
driverDocumentSchema.index({ driverId: 1, documentType: 1 });
driverDocumentSchema.index({ verificationStatus: 1 });

module.exports = mongoose.model('DriverDocument', driverDocumentSchema);
