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

// Create indexes for geospatial queries
const createIndexes = async () => {
  try {
    await mongoose.connection.collection('rides').createIndex(
      { 'origin.coordinates': '2dsphere' },
      { background: true }
    );
    await mongoose.connection.collection('rides').createIndex(
      { 'destination.coordinates': '2dsphere' },
      { background: true }
    );
    console.log('Created 2dsphere index on origin.coordinates and destination.coordinates');
  } catch (err) {
    console.error('Error creating indexes:', err);
  }
};

// Call the function to create indexes when the model is loaded
createIndexes();

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