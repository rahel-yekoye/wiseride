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
  },
  coordinates: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true
    }
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
  }]
}, {
  timestamps: true
});

// Create geospatial index for origin coordinates
rideSchema.index({ 'origin.coordinates': '2dsphere' });
rideSchema.index({ 'destination.coordinates': '2dsphere' });

// Middleware to automatically set coordinates from lat/lng
locationSchema.pre('save', function(next) {
  if (this.lat && this.lng) {
    this.coordinates = {
      type: 'Point',
      coordinates: [this.lng, this.lat] // MongoDB expects [longitude, latitude]
    };
  }
  next();
});

// Middleware to set coordinates when lat/lng are updated
locationSchema.pre('findOneAndUpdate', function(next) {
  const update = this.getUpdate();
  if (update.lat && update.lng) {
    update.coordinates = {
      type: 'Point',
      coordinates: [update.lng, update.lat]
    };
  }
  next();
});

module.exports = mongoose.model('Ride', rideSchema);