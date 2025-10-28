const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
  getRideHistory,
  getRideStatistics,
  getRideDetails,
  exportRideHistory,
  getFavoriteLocations,
} = require('../controllers/rideHistoryController');

// All routes require authentication
router.use(protect);

// Get ride history with filters
router.get('/', getRideHistory);

// Get ride statistics
router.get('/stats', getRideStatistics);

// Get ride details
router.get('/:id', getRideDetails);

// Export ride history to CSV
router.get('/export/csv', exportRideHistory);

// Get favorite locations
router.get('/favorites/locations', getFavoriteLocations);

module.exports = router;
