const express = require('express');
const router = express.Router();
const {
  updateLocation,
  toggleOnlineStatus,
  getNearbyRides,
  acceptRide,
  startRide,
  completeRide,
  getEarnings,
  updateProfile,
  getDashboard
} = require('../controllers/driverController');
const { auth } = require('../middleware/auth');

// All routes are protected
router.use(auth);

// Driver dashboard
router.get('/dashboard', getDashboard);

// Location and status
router.put('/location', updateLocation);
router.put('/toggle-online', toggleOnlineStatus);

// Rides
router.get('/rides/nearby', getNearbyRides);
router.put('/rides/:rideId/accept', acceptRide);
router.put('/rides/:rideId/start', startRide);
router.put('/rides/:rideId/complete', completeRide);

// Profile and earnings
router.get('/earnings', getEarnings);
router.put('/profile', updateProfile);

module.exports = router;
