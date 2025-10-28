const express = require('express');
const router = express.Router();
const {
  processRideEarnings,
  getEarningsSummary,
  getTransactionHistory,
  requestPayout,
  getPayoutHistory,
  processPayout,
  getPendingPayouts
} = require('../controllers/earningsController');
const { auth } = require('../middleware/auth');

// All routes are protected
router.use(auth);

// Driver earnings routes
router.post('/process', processRideEarnings);
router.get('/summary', getEarningsSummary);
router.get('/transactions', getTransactionHistory);

// Payout routes
router.post('/payout/request', requestPayout);
router.get('/payout/history', getPayoutHistory);

// Admin routes
router.get('/payout/pending', getPendingPayouts);
router.put('/payout/:payoutId/process', processPayout);

module.exports = router;
