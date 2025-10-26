const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema({
  lat: {
    type: Number,
    required: true
  },
  lng: {
    type: Number,
    required: true
  },
  address: {
    type: String,
    required: true
  }
});

const rideSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['public', 'private', 'school'],
    default: 'public'
  },
  riderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  origin: {
    type: locationSchema,
    required: true
  },
  destination: {
    type: locationSchema,
    required: true
  },
  fare: {
    type: Number
  },
  status: {
    type: String,
    enum: ['requested', 'accepted', 'in_progress', 'completed', 'cancelled'],
    default: 'requested'
  },
  startTime: {
    type: Date
  },
  endTime: {
    type: Date
  },
  estimatedArrival: {
    type: Date
  },
  vehicleType: {
    type: String,
    enum: ['bus', 'taxi', 'minibus', 'private_car']
  },
  route: [{
    lat: Number,
    lng: Number
  }],
  ratings: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    rating: {
      type: Number,
      min: 1,
      max: 5
    },
    feedback: String,
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed', 'refunded'],
    default: 'pending'
  },
  paymentMethod: String,
  transactionId: String
}, {
  timestamps: true
});

module.exports = mongoose.model('Ride', rideSchema);