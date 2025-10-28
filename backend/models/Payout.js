const mongoose = require('mongoose');

const payoutSchema = new mongoose.Schema({
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  currency: {
    type: String,
    default: 'ETB'
  },
  status: {
    type: String,
    enum: ['pending', 'processing', 'completed', 'failed', 'cancelled'],
    default: 'pending'
  },
  paymentMethod: {
    type: String,
    enum: ['bank_transfer', 'mobile_money', 'cash'],
    required: true
  },
  bankDetails: {
    bankName: String,
    accountNumber: String,
    accountHolderName: String,
    swiftCode: String
  },
  mobileMoneyDetails: {
    provider: String, // e.g., 'M-Pesa', 'HelloCash'
    phoneNumber: String,
    accountName: String
  },
  requestedAt: {
    type: Date,
    default: Date.now
  },
  processedAt: {
    type: Date
  },
  completedAt: {
    type: Date
  },
  processedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  transactionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Transaction'
  },
  referenceNumber: {
    type: String,
    unique: true,
    sparse: true
  },
  failureReason: {
    type: String
  },
  notes: {
    type: String
  }
}, {
  timestamps: true
});

// Generate reference number before saving
payoutSchema.pre('save', function(next) {
  if (!this.referenceNumber && this.isNew) {
    this.referenceNumber = `PAY-${Date.now()}-${Math.random().toString(36).substr(2, 9).toUpperCase()}`;
  }
  next();
});

// Indexes
payoutSchema.index({ driverId: 1, createdAt: -1 });
payoutSchema.index({ status: 1 });
payoutSchema.index({ referenceNumber: 1 });

module.exports = mongoose.model('Payout', payoutSchema);
