const express = require('express');
const router = express.Router();
const { 
  createRide,
  getUserRides,
  getRideById,
  updateRideStatus,
  acceptRide,
  getAvailableRides,
  cancelRide
} = require('../controllers/rideController');
const auth = require('../middleware/auth');

// All routes are protected
router.use(auth);

// Ride routes
router.route('/')
  .post(createRide)
  .get(getUserRides);

router.route('/:id')
  .get(getRideById)
  .put(updateRideStatus);

router.put('/:id/accept', auth, acceptRide);
router.get('/available', auth, getAvailableRides);
router.put('/:id/cancel', auth, cancelRide);

module.exports = router;