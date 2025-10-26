const express = require('express');
const router = express.Router();
const { 
  createRide,
  getUserRides,
  getRideById,
  updateRideStatus,
  acceptRide,
  getAvailableRides,
  searchAvailableRides,
  cancelRide,
  startRide,
  endRide,
  rateRide,
  getRideStats
} = require('../controllers/rideController');
const auth = require('../middleware/auth');

// All routes are protected
router.use(auth);

// Ride routes
router.route('/')
  .post(createRide)
  .get(getUserRides);

router.route('/user')
  .get(getUserRides);

router.route('/:id')
  .get(getRideById);

router.route('/:id/status')
  .put(updateRideStatus);

router.route('/search')
  .post(searchAvailableRides);

router.route('/stats')
  .get(getRideStats);

router.put('/:id/accept', acceptRide);
router.put('/:id/start', startRide);
router.put('/:id/end', endRide);
router.put('/:id/cancel', cancelRide);
router.post('/:id/rate', rateRide);

router.get('/available', getAvailableRides);

module.exports = router;