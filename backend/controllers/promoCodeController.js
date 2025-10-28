const PromoCode = require('../models/PromoCode');
const User = require('../models/User');

// Validate and apply promo code
const validatePromoCode = async (req, res) => {
  try {
    const { code, rideAmount, vehicleType } = req.body;

    const promoCode = await PromoCode.findOne({ 
      code: code.toUpperCase() 
    });

    if (!promoCode) {
      return res.status(404).json({ message: 'Invalid promo code' });
    }

    // Check if promo code is valid
    if (!promoCode.isValid()) {
      return res.status(400).json({ message: 'Promo code has expired or reached usage limit' });
    }

    // Check if user can use this promo code
    if (!promoCode.canBeUsedBy(req.user._id)) {
      return res.status(400).json({ 
        message: `You have already used this promo code ${promoCode.maxUsagePerUser} time(s)` 
      });
    }

    // Check vehicle type eligibility
    if (promoCode.applicableVehicleTypes.length > 0 && 
        !promoCode.applicableVehicleTypes.includes(vehicleType)) {
      return res.status(400).json({ 
        message: `This promo code is not applicable for ${vehicleType}` 
      });
    }

    // Check user type eligibility
    const user = await User.findById(req.user._id);
    const isNewUser = user.createdAt > new Date(Date.now() - 30 * 24 * 60 * 60 * 1000); // 30 days
    
    if (promoCode.applicableUserTypes.includes('new_user') && !isNewUser) {
      return res.status(400).json({ message: 'This promo code is only for new users' });
    }

    // Calculate discount
    const discount = promoCode.calculateDiscount(rideAmount);

    if (discount === 0) {
      return res.status(400).json({ 
        message: `Minimum ride amount of ${promoCode.minRideAmount} ETB required` 
      });
    }

    const finalAmount = rideAmount - discount;

    // Build richer response to support percentage display on client
    const response = {
      valid: true,
      promoCode: {
        code: promoCode.code,
        description: promoCode.description,
        type: promoCode.type,
        value: promoCode.value,
        maxDiscountAmount: promoCode.maxDiscountAmount,
        minRideAmount: promoCode.minRideAmount,
      },
      discount,
      originalAmount: rideAmount,
      finalAmount,
    };

    return res.json(response);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Apply promo code to a ride (called after ride completion)
const applyPromoCode = async (req, res) => {
  try {
    const { code, rideId, rideAmount } = req.body;

    const promoCode = await PromoCode.findOne({ 
      code: code.toUpperCase() 
    });

    if (!promoCode || !promoCode.isValid() || !promoCode.canBeUsedBy(req.user._id)) {
      return res.status(400).json({ message: 'Invalid or expired promo code' });
    }

    const discount = promoCode.calculateDiscount(rideAmount);

    // Record usage
    promoCode.usedBy.push({
      userId: req.user._id,
      rideId,
      discountAmount: discount,
    });
    promoCode.currentUsageCount++;

    await promoCode.save();

    // Handle referral rewards if applicable
    if (promoCode.isReferralCode && promoCode.referredBy) {
      await handleReferralReward(promoCode.referredBy, req.user._id, promoCode.referralReward);
    }

    res.json({
      message: 'Promo code applied successfully',
      discount,
      finalAmount: rideAmount - discount,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Handle referral rewards
async function handleReferralReward(referrerId, refereeId, rewards) {
  try {
    // Add balance to referrer
    await User.findByIdAndUpdate(referrerId, {
      $inc: { balance: rewards.referrer },
    });

    // Add balance to referee
    await User.findByIdAndUpdate(refereeId, {
      $inc: { balance: rewards.referee },
    });

    // Could also create Transaction records here for tracking
  } catch (error) {
    console.error('Error handling referral reward:', error);
  }
}

// Create promo code (Admin only)
const createPromoCode = async (req, res) => {
  try {
    const payload = { ...req.body };
    // If no type provided, default to percentage-based discount with safe defaults
    if (!payload.type) {
      payload.type = 'percentage';
      if (typeof payload.value !== 'number') {
        payload.value = 10; // default 10%
      }
      if (payload.maxDiscountAmount === undefined) {
        payload.maxDiscountAmount = 50; // cap ETB off by default
      }
      if (payload.validFrom === undefined) payload.validFrom = new Date();
      if (payload.validUntil === undefined) payload.validUntil = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    }

    const promoCode = new PromoCode(payload);
    await promoCode.save();

    res.status(201).json({
      message: 'Promo code created successfully',
      promoCode,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all promo codes (Admin only)
const getAllPromoCodes = async (req, res) => {
  try {
    const { page = 1, limit = 20, isActive } = req.query;

    const query = {};
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }

    const promoCodes = await PromoCode.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await PromoCode.countDocuments(query);

    res.json({
      promoCodes,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      totalCodes: count,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update promo code (Admin only)
const updatePromoCode = async (req, res) => {
  try {
    const { id } = req.params;
    const promoCode = await PromoCode.findByIdAndUpdate(
      id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!promoCode) {
      return res.status(404).json({ message: 'Promo code not found' });
    }

    res.json({
      message: 'Promo code updated successfully',
      promoCode,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Delete promo code (Admin only)
const deletePromoCode = async (req, res) => {
  try {
    const { id } = req.params;
    const promoCode = await PromoCode.findByIdAndDelete(id);

    if (!promoCode) {
      return res.status(404).json({ message: 'Promo code not found' });
    }

    res.json({ message: 'Promo code deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get user's promo code usage history
const getUserPromoHistory = async (req, res) => {
  try {
    const promoCodes = await PromoCode.find({
      'usedBy.userId': req.user._id,
    }).select('code description type usedBy');

    const history = [];
    promoCodes.forEach(promo => {
      const userUsages = promo.usedBy.filter(
        usage => usage.userId.toString() === req.user._id.toString()
      );
      userUsages.forEach(usage => {
        history.push({
          code: promo.code,
          description: promo.description,
          type: promo.type,
          discountAmount: usage.discountAmount,
          usedAt: usage.usedAt,
          rideId: usage.rideId,
        });
      });
    });

    history.sort((a, b) => b.usedAt - a.usedAt);

    res.json({ history });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Generate referral code for user
const generateReferralCode = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    
    // Check if user already has a referral code
    const existingCode = await PromoCode.findOne({
      isReferralCode: true,
      referredBy: req.user._id,
    });

    if (existingCode) {
      return res.json({
        message: 'Referral code already exists',
        referralCode: existingCode.code,
      });
    }

    // Generate unique code
    const code = `REF${user.name.substring(0, 3).toUpperCase()}${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

    const referralCode = new PromoCode({
      code,
      description: `Referral code from ${user.name}`,
      type: 'fixed_amount',
      value: 50, // 50 ETB discount for new user
      maxUsagePerUser: 1,
      validFrom: new Date(),
      validUntil: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000), // 1 year
      applicableUserTypes: ['new_user'],
      isReferralCode: true,
      referredBy: req.user._id,
      referralReward: {
        referrer: 50, // Referrer gets 50 ETB
        referee: 50,  // New user gets 50 ETB
      },
    });

    await referralCode.save();

    res.json({
      message: 'Referral code generated successfully',
      referralCode: referralCode.code,
      reward: 'You and your friend will each get 50 ETB!',
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  validatePromoCode,
  applyPromoCode,
  createPromoCode,
  getAllPromoCodes,
  updatePromoCode,
  deletePromoCode,
  getUserPromoHistory,
  generateReferralCode,
};
