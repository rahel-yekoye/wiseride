const mongoose = require('mongoose');

const ratingSchema = new mongoose.Schema({
  rideId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Ride',
    required: true,
  },
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  riderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  // Rating from rider to driver
  driverRating: {
    score: {
      type: Number,
      min: 1,
      max: 5,
      required: true,
    },
    review: {
      type: String,
      maxlength: 500,
    },
    categories: {
      cleanliness: { type: Number, min: 1, max: 5 },
      punctuality: { type: Number, min: 1, max: 5 },
      driving: { type: Number, min: 1, max: 5 },
      communication: { type: Number, min: 1, max: 5 },
    },
  },
  // Rating from driver to rider
  riderRating: {
    score: {
      type: Number,
      min: 1, 
      max: 5,
    },
    review: {
      type: String,
      maxlength: 500,
    },
    categories: {
      behavior: { type: Number, min: 1, max: 5 },
      punctuality: { type: Number, min: 1, max: 5 },
      communication: { type: Number, min: 1, max: 5 },
    },
  },
  // Metadata
  ratedAt: {
    type: Date,
    default: Date.now,
  },
  isDisputed: {
    type: Boolean,
    default: false,
  },
  disputeReason: String,
}, {
  timestamps: true,
});

// Indexes
ratingSchema.index({ rideId: 1 }, { unique: true });
ratingSchema.index({ driverId: 1, createdAt: -1 });
ratingSchema.index({ riderId: 1, createdAt: -1 });

module.exports = mongoose.model('Rating', ratingSchema);
