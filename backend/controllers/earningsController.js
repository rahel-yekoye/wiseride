const User = require('../models/User');
const Ride = require('../models/Ride');
const Transaction = require('../models/Transaction');
const Payout = require('../models/Payout');

// Calculate fare with commission
const calculateFareBreakdown = (totalFare, commissionRate) => {
  const commissionAmount = totalFare * commissionRate;
  const netAmount = totalFare - commissionAmount;
  
  return {
    totalFare,
    commissionRate,
    commissionAmount: parseFloat(commissionAmount.toFixed(2)),
    netAmount: parseFloat(netAmount.toFixed(2))
  };
};

// Process ride earnings
const processRideEarnings = async (req, res) => {
  try {
    const { rideId, totalFare } = req.body;

    if (!rideId || !totalFare) {
      return res.status(400).json({ message: 'Ride ID and total fare are required' });
    }

    const driver = await User.findById(req.user._id);
    if (!driver || driver.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can process earnings' });
    }

    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    if (ride.driverId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized to process this ride' });
    }

    if (ride.status !== 'completed') {
      return res.status(400).json({ message: 'Ride must be completed first' });
    }

    // Check if earnings already processed
    const existingTransaction = await Transaction.findOne({
      rideId: ride._id,
      type: 'ride_earning'
    });

    if (existingTransaction) {
      return res.status(400).json({ message: 'Earnings already processed for this ride' });
    }

    // Calculate fare breakdown
    const fareBreakdown = calculateFareBreakdown(totalFare, driver.commissionRate);
    const balanceBefore = driver.balance;
    const balanceAfter = balanceBefore + fareBreakdown.netAmount;

    // Create ride earning transaction
    const transaction = new Transaction({
      driverId: driver._id,
      rideId: ride._id,
      type: 'ride_earning',
      amount: fareBreakdown.netAmount,
      status: 'completed',
      description: `Earnings from ride to ${ride.destination.address}`,
      balanceBefore,
      balanceAfter,
      metadata: {
        commissionRate: fareBreakdown.commissionRate,
        commissionAmount: fareBreakdown.commissionAmount,
        netAmount: fareBreakdown.netAmount
      }
    });

    await transaction.save();

    // Create commission transaction
    const commissionTransaction = new Transaction({
      driverId: driver._id,
      rideId: ride._id,
      type: 'commission',
      amount: -fareBreakdown.commissionAmount,
      status: 'completed',
      description: `Commission for ride to ${ride.destination.address}`,
      balanceBefore: balanceAfter,
      balanceAfter: balanceAfter,
      metadata: {
        commissionRate: fareBreakdown.commissionRate,
        commissionAmount: fareBreakdown.commissionAmount
      }
    });

    await commissionTransaction.save();

    // Update driver balance and earnings
    driver.balance = balanceAfter;
    driver.earnings.total += fareBreakdown.netAmount;
    driver.earnings.today += fareBreakdown.netAmount;
    driver.earnings.thisWeek += fareBreakdown.netAmount;
    driver.earnings.thisMonth += fareBreakdown.netAmount;

    await driver.save();

    // Update ride fare
    ride.fare = totalFare;
    await ride.save();

    res.json({
      message: 'Earnings processed successfully',
      fareBreakdown,
      transaction,
      newBalance: balanceAfter
    });
  } catch (error) {
    console.error('Error in processRideEarnings:', error);
    res.status(500).json({ message: error.message });
  }
};

// Get earnings summary
const getEarningsSummary = async (req, res) => {
  try {
    const driver = await User.findById(req.user._id);
    if (!driver || driver.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can view earnings' });
    }

    // Get completed rides count
    const completedRides = await Ride.countDocuments({
      driverId: driver._id,
      status: 'completed'
    });

    // Get total transactions
    const transactions = await Transaction.find({
      driverId: driver._id,
      status: 'completed'
    });

    // Calculate total commission paid
    const totalCommission = transactions
      .filter(t => t.type === 'commission')
      .reduce((sum, t) => sum + Math.abs(t.amount), 0);

    // Get pending payout amount
    const pendingPayouts = await Payout.find({
      driverId: driver._id,
      status: { $in: ['pending', 'processing'] }
    });

    const pendingPayoutAmount = pendingPayouts.reduce((sum, p) => sum + p.amount, 0);

    res.json({
      balance: driver.balance,
      earnings: driver.earnings,
      completedRides,
      totalCommission: parseFloat(totalCommission.toFixed(2)),
      pendingPayoutAmount: parseFloat(pendingPayoutAmount.toFixed(2)),
      availableForPayout: parseFloat((driver.balance - pendingPayoutAmount).toFixed(2)),
      commissionRate: driver.commissionRate
    });
  } catch (error) {
    console.error('Error in getEarningsSummary:', error);
    res.status(500).json({ message: error.message });
  }
};

// Get transaction history
const getTransactionHistory = async (req, res) => {
  try {
    const { page = 1, limit = 20, type, startDate, endDate } = req.query;

    const driver = await User.findById(req.user._id);
    if (!driver || driver.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can view transactions' });
    }

    // Build query
    const query = { driverId: driver._id };
    
    if (type) {
      query.type = type;
    }
    
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    const transactions = await Transaction.find(query)
      .populate('rideId', 'origin destination fare status')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Transaction.countDocuments(query);

    res.json({
      transactions,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      totalTransactions: count
    });
  } catch (error) {
    console.error('Error in getTransactionHistory:', error);
    res.status(500).json({ message: error.message });
  }
};

// Request payout
const requestPayout = async (req, res) => {
  try {
    const { amount, paymentMethod, bankDetails, mobileMoneyDetails } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({ message: 'Valid amount is required' });
    }

    if (!paymentMethod) {
      return res.status(400).json({ message: 'Payment method is required' });
    }

    const driver = await User.findById(req.user._id);
    if (!driver || driver.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can request payouts' });
    }

    // Check if driver has sufficient balance
    const pendingPayouts = await Payout.find({
      driverId: driver._id,
      status: { $in: ['pending', 'processing'] }
    });

    const pendingAmount = pendingPayouts.reduce((sum, p) => sum + p.amount, 0);
    const availableBalance = driver.balance - pendingAmount;

    if (amount > availableBalance) {
      return res.status(400).json({ 
        message: 'Insufficient balance',
        availableBalance,
        requestedAmount: amount
      });
    }

    // Minimum payout amount check
    const minPayoutAmount = 100; // ETB
    if (amount < minPayoutAmount) {
      return res.status(400).json({ 
        message: `Minimum payout amount is ${minPayoutAmount} ETB` 
      });
    }

    // Create payout request
    const payout = new Payout({
      driverId: driver._id,
      amount,
      paymentMethod,
      bankDetails: paymentMethod === 'bank_transfer' ? bankDetails : undefined,
      mobileMoneyDetails: paymentMethod === 'mobile_money' ? mobileMoneyDetails : undefined
    });

    await payout.save();

    res.json({
      message: 'Payout request submitted successfully',
      payout
    });
  } catch (error) {
    console.error('Error in requestPayout:', error);
    res.status(500).json({ message: error.message });
  }
};

// Get payout history
const getPayoutHistory = async (req, res) => {
  try {
    const { page = 1, limit = 20, status } = req.query;

    const driver = await User.findById(req.user._id);
    if (!driver || driver.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can view payout history' });
    }

    const query = { driverId: driver._id };
    if (status) {
      query.status = status;
    }

    const payouts = await Payout.find(query)
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Payout.countDocuments(query);

    res.json({
      payouts,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      totalPayouts: count
    });
  } catch (error) {
    console.error('Error in getPayoutHistory:', error);
    res.status(500).json({ message: error.message });
  }
};

// Admin: Process payout
const processPayout = async (req, res) => {
  try {
    const { payoutId } = req.params;
    const { action, referenceNumber, failureReason } = req.body;

    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can process payouts' });
    }

    const payout = await Payout.findById(payoutId);
    if (!payout) {
      return res.status(404).json({ message: 'Payout not found' });
    }

    const driver = await User.findById(payout.driverId);
    if (!driver) {
      return res.status(404).json({ message: 'Driver not found' });
    }

    if (action === 'approve') {
      payout.status = 'processing';
      payout.processedBy = req.user._id;
      payout.processedAt = new Date();
      await payout.save();

      res.json({
        message: 'Payout approved and processing',
        payout
      });
    } else if (action === 'complete') {
      if (!referenceNumber) {
        return res.status(400).json({ message: 'Reference number is required' });
      }

      payout.status = 'completed';
      payout.completedAt = new Date();
      payout.referenceNumber = referenceNumber;

      // Create transaction
      const balanceBefore = driver.balance;
      const balanceAfter = balanceBefore - payout.amount;

      const transaction = new Transaction({
        driverId: driver._id,
        type: 'payout',
        amount: -payout.amount,
        status: 'completed',
        description: `Payout via ${payout.paymentMethod}`,
        balanceBefore,
        balanceAfter,
        metadata: {
          paymentMethod: payout.paymentMethod,
          referenceNumber: payout.referenceNumber
        }
      });

      await transaction.save();

      payout.transactionId = transaction._id;
      await payout.save();

      // Update driver balance
      driver.balance = balanceAfter;
      await driver.save();

      res.json({
        message: 'Payout completed successfully',
        payout,
        transaction
      });
    } else if (action === 'reject') {
      payout.status = 'failed';
      payout.failureReason = failureReason || 'Payout rejected';
      payout.processedBy = req.user._id;
      payout.processedAt = new Date();
      await payout.save();

      res.json({
        message: 'Payout rejected',
        payout
      });
    } else {
      return res.status(400).json({ message: 'Invalid action' });
    }
  } catch (error) {
    console.error('Error in processPayout:', error);
    res.status(500).json({ message: error.message });
  }
};

// Admin: Get all pending payouts
const getPendingPayouts = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Only admins can view pending payouts' });
    }

    const payouts = await Payout.find({
      status: { $in: ['pending', 'processing'] }
    })
    .populate('driverId', 'name email phone vehicleInfo')
    .sort({ createdAt: -1 });

    res.json(payouts);
  } catch (error) {
    console.error('Error in getPendingPayouts:', error);
    res.status(500).json({ message: error.message });
  }
};

// Reset daily/weekly/monthly earnings (scheduled job)
const resetEarnings = async (period) => {
  try {
    const update = {};
    
    if (period === 'daily') {
      update['earnings.today'] = 0;
    } else if (period === 'weekly') {
      update['earnings.thisWeek'] = 0;
    } else if (period === 'monthly') {
      update['earnings.thisMonth'] = 0;
    }

    await User.updateMany(
      { role: 'driver' },
      { $set: update }
    );

    console.log(`${period} earnings reset successfully`);
  } catch (error) {
    console.error(`Error resetting ${period} earnings:`, error);
  }
};

module.exports = {
  processRideEarnings,
  getEarningsSummary,
  getTransactionHistory,
  requestPayout,
  getPayoutHistory,
  processPayout,
  getPendingPayouts,
  resetEarnings,
  calculateFareBreakdown
};
