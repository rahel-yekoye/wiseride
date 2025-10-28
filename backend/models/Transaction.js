const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  rideId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Ride'
  },
  type: {
    type: String,
    enum: ['ride_earning', 'commission', 'payout', 'bonus', 'penalty', 'refund'],
    required: true
  },
  amount: {
    type: Number,
    required: true
  },
  currency: {
    type: String,
    default: 'ETB' // Ethiopian Birr
  },
  status: {
    type: String,
    enum: ['pending', 'completed', 'failed', 'cancelled'],
    default: 'pending'
  },
  description: {
    type: String
  },
  balanceBefore: {
    type: Number,
    default: 0
  },
  balanceAfter: {
    type: Number,
    default: 0
  },
  metadata: {
    commissionRate: Number,
    commissionAmount: Number,
    netAmount: Number,
    paymentMethod: String,
    referenceNumber: String
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
transactionSchema.index({ driverId: 1, createdAt: -1 });
transactionSchema.index({ rideId: 1 });
transactionSchema.index({ status: 1 });
transactionSchema.index({ type: 1 });

module.exports = mongoose.model('Transaction', transactionSchema);
