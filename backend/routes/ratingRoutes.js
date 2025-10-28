const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  submitRating,
  getUserRatings,
  getRideRating,
  disputeRating,
  getRatingStatistics,
} = require('../controllers/ratingController');

// All routes require authentication
router.use(protect);

// Submit rating for a ride
router.post('/:rideId', submitRating);

// Get ratings for a user (driver or rider)
router.get('/user/:userId', getUserRatings);

// Get rating for a specific ride
router.get('/ride/:rideId', getRideRating);

// Dispute a rating
router.post('/:rideId/dispute', disputeRating);

// Get rating statistics for a user
router.get('/stats/:userId', getRatingStatistics);

module.exports = router;
