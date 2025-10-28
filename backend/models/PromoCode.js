const mongoose = require('mongoose');

const promoCodeSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
    trim: true,
  },
  description: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    enum: ['percentage', 'fixed_amount', 'free_ride'],
    required: true,
  },
  value: {
    type: Number,
    required: true,
    min: 0,
  },
  // Usage limits
  maxUsageTotal: {
    type: Number,
    default: null, // null = unlimited
  },
  maxUsagePerUser: {
    type: Number,
    default: 1,
  },
  currentUsageCount: {
    type: Number,
    default: 0,
  },
  // Validity period
  validFrom: {
    type: Date,
    required: true,
  },
  validUntil: {
    type: Date,
    required: true,
  },
  // Conditions
  minRideAmount: {
    type: Number,
    default: 0,
  },
  maxDiscountAmount: {
    type: Number,
    default: null, // null = no limit
  },
  applicableVehicleTypes: [{
    type: String,
    enum: ['taxi', 'private_car', 'minibus', 'bus'],
  }],
  applicableUserTypes: [{
    type: String,
    enum: ['new_user', 'existing_user', 'all'],
    default: ['all'],
  }],
  // Referral system
  isReferralCode: {
    type: Boolean,
    default: false,
  },
  referredBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
  },
  referralReward: {
    referrer: { type: Number, default: 0 }, // Reward for referrer
    referee: { type: Number, default: 0 },  // Reward for new user
  },
  // Status
  isActive: {
    type: Boolean,
    default: true,
  },
  // Usage tracking
  usedBy: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    rideId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Ride',
    },
    usedAt: {
      type: Date,
      default: Date.now,
    },
    discountAmount: Number,
  }],
}, {
  timestamps: true,
});

// Indexes
promoCodeSchema.index({ code: 1 });
promoCodeSchema.index({ validFrom: 1, validUntil: 1 });
promoCodeSchema.index({ isActive: 1 });
promoCodeSchema.index({ 'usedBy.userId': 1 });

// Methods
promoCodeSchema.methods.isValid = function() {
  const now = new Date();
  return (
    this.isActive &&
    now >= this.validFrom &&
    now <= this.validUntil &&
    (this.maxUsageTotal === null || this.currentUsageCount < this.maxUsageTotal)
  );
};

promoCodeSchema.methods.canBeUsedBy = function(userId) {
  if (!this.isValid()) return false;
  
  const userUsageCount = this.usedBy.filter(
    usage => usage.userId.toString() === userId.toString()
  ).length;
  
  return userUsageCount < this.maxUsagePerUser;
};

promoCodeSchema.methods.calculateDiscount = function(rideAmount) {
  if (rideAmount < this.minRideAmount) return 0;
  
  let discount = 0;
  
  switch (this.type) {
    case 'percentage':
      discount = (rideAmount * this.value) / 100;
      break;
    case 'fixed_amount':
      discount = this.value;
      break;
    case 'free_ride':
      discount = rideAmount;
      break;
  }
  
  // Apply max discount limit if set
  if (this.maxDiscountAmount !== null) {
    discount = Math.min(discount, this.maxDiscountAmount);
  }
  
  // Discount cannot exceed ride amount
  discount = Math.min(discount, rideAmount);
  
  return Math.round(discount);
};

module.exports = mongoose.model('PromoCode', promoCodeSchema);
