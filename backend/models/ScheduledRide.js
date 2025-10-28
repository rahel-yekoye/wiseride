const mongoose = require('mongoose');

const scheduledRideSchema = new mongoose.Schema({
  riderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  origin: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number],
      required: true,
    },
    address: {
      type: String,
      required: true,
    },
  },
  destination: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number],
      required: true,
    },
    address: {
      type: String,
      required: true,
    },
  },
  vehicleType: {
    type: String,
    enum: ['taxi', 'private_car', 'minibus', 'bus'],
    default: 'taxi',
  },
  scheduledTime: {
    type: Date,
    required: true,
  },
  // Pickup window (e.g., 15 minutes before/after scheduled time)
  pickupWindow: {
    type: Number,
    default: 15, // minutes
  },
  // Fare estimation
  estimatedFare: {
    type: Number,
  },
  // Preferences
  preferences: {
    driverGender: {
      type: String,
      enum: ['any', 'male', 'female'],
      default: 'any',
    },
    minDriverRating: {
      type: Number,
      min: 1,
      max: 5,
      default: 3,
    },
    ac: {
      type: Boolean,
      default: false,
    },
    notes: String,
  },
  // Status
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'assigned', 'cancelled', 'completed', 'expired'],
    default: 'pending',
  },
  // Assigned driver
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  assignedAt: Date,
  // Created ride (when scheduled ride becomes active)
  rideId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Ride',
  },
  // Cancellation
  cancelledBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  cancellationReason: String,
  cancelledAt: Date,
  // Notifications
  reminderSent: {
    type: Boolean,
    default: false,
  },
  reminderSentAt: Date,
  // Recurring ride settings
  isRecurring: {
    type: Boolean,
    default: false,
  },
  recurrence: {
    frequency: {
      type: String,
      enum: ['daily', 'weekly', 'monthly'],
    },
    daysOfWeek: [Number], // 0-6 for Sunday-Saturday
    endDate: Date,
  },
}, {
  timestamps: true,
});

// Indexes
scheduledRideSchema.index({ riderId: 1, scheduledTime: 1 });
scheduledRideSchema.index({ scheduledTime: 1, status: 1 });
scheduledRideSchema.index({ driverId: 1, scheduledTime: 1 });
scheduledRideSchema.index({ 'origin.coordinates': '2dsphere' });
scheduledRideSchema.index({ status: 1 });

// Methods
scheduledRideSchema.methods.isExpired = function() {
  const now = new Date();
  const expiryTime = new Date(this.scheduledTime);
  expiryTime.setMinutes(expiryTime.getMinutes() + this.pickupWindow);
  return now > expiryTime && this.status === 'pending';
};

scheduledRideSchema.methods.shouldSendReminder = function() {
  if (this.reminderSent) return false;
  
  const now = new Date();
  const reminderTime = new Date(this.scheduledTime);
  reminderTime.setHours(reminderTime.getHours() - 1); // 1 hour before
  
  return now >= reminderTime && this.status === 'confirmed';
};

module.exports = mongoose.model('ScheduledRide', scheduledRideSchema);
