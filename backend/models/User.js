const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  role: {
    type: String,
    enum: ['rider', 'driver', 'parent', 'admin'],
    default: 'rider'
  },
  phone: {
    type: String,
    trim: true
  },
  driverVerified: {
    type: Boolean,
    default: false
  },
  driverLicense: {
    type: String,
    trim: true
  },
  driverRegistrationStatus: {
    type: String,
    enum: ['not_started', 'pending', 'documents_submitted', 'under_review', 'approved', 'rejected'],
    default: 'not_started'
  },
  driverApprovalDate: {
    type: Date
  },
  driverRejectionReason: {
    type: String
  },
  vehicleInfo: {
    type: {
      make: String,
      model: String,
      year: Number,
      color: String,
      plateNumber: String,
      capacity: Number,
      vehicleType: {
        type: String,
        enum: ['bus', 'taxi', 'minibus', 'private_car']
      }
    }
  },
  bankDetails: {
    type: {
      bankName: String,
      accountNumber: String,
      accountHolderName: String,
      swiftCode: String
    }
  },
  mobileMoneyDetails: {
    type: {
      provider: String,
      phoneNumber: String,
      accountName: String
    }
  },
  availabilitySchedule: {
    type: {
      monday: { start: String, end: String, available: Boolean },
      tuesday: { start: String, end: String, available: Boolean },
      wednesday: { start: String, end: String, available: Boolean },
      thursday: { start: String, end: String, available: Boolean },
      friday: { start: String, end: String, available: Boolean },
      saturday: { start: String, end: String, available: Boolean },
      sunday: { start: String, end: String, available: Boolean }
    }
  },
  serviceAreas: [{
    type: String
  }],
  commissionRate: {
    type: Number,
    default: 0.15 // 15% commission
  },
  balance: {
    type: Number,
    default: 0
  },
  isOnline: {
    type: Boolean,
    default: false
  },
  currentLocation: {
    type: {
      lat: Number,
      lng: Number,
      address: String,
      timestamp: Date,
      coordinates: {
        type: {
          type: String,
          enum: ['Point'],
          default: 'Point'
        },
        coordinates: {
          type: [Number] // [lng, lat]
        }
      }
    }
  },
  earnings: {
    type: {
      total: { type: Number, default: 0 },
      today: { type: Number, default: 0 },
      thisWeek: { type: Number, default: 0 },
      thisMonth: { type: Number, default: 0 }
    }
  },
  rating: {
    type: {
      average: { type: Number, default: 0 },
      count: { type: Number, default: 0 }
    }
  },
  location: {
    type: {
      lat: Number,
      lng: Number,
      address: String
    }
  },
  preferences: {
    type: {
      notifications: {
        type: Boolean,
        default: true
      },
      darkMode: {
        type: Boolean,
        default: false
      }
    }
  },
  emergencyContacts: [{
    name: String,
    phone: String,
    relationship: String
  }]
}, {
  timestamps: true
});

// Geospatial index for driver location search
userSchema.index({ 'currentLocation.coordinates': '2dsphere' });

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    // Still ensure currentLocation.coordinates is set if lat/lng updated
    if (this.currentLocation && this.currentLocation.lat && this.currentLocation.lng) {
      this.currentLocation.coordinates = {
        type: 'Point',
        coordinates: [this.currentLocation.lng, this.currentLocation.lat]
      };
    }
    return next();
  }
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    
    // Also ensure currentLocation.coordinates if present
    if (this.currentLocation && this.currentLocation.lat && this.currentLocation.lng) {
      this.currentLocation.coordinates = {
        type: 'Point',
        coordinates: [this.currentLocation.lng, this.currentLocation.lat]
      };
    }

    next();
  } catch (error) {
    next(error);
  }
});

// Compare password method
userSchema.methods.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Remove password from JSON output
userSchema.methods.toJSON = function () {
  const userObject = this.toObject();
  delete userObject.password;
  return userObject;
};

module.exports = mongoose.model('User', userSchema);
