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
const { calculateFareEstimate } = require('../services/fareCalculationService');
const { auth } = require('../middleware/auth');

// All routes are protected
router.use(auth);

// Fare estimation endpoint
router.post('/estimate', async (req, res) => {
  try {
    const { originLat, originLng, destLat, destLng, vehicleType, weatherCondition } = req.body;
    
    if (!originLat || !originLng || !destLat || !destLng) {
      return res.status(400).json({ message: 'Origin and destination coordinates are required' });
    }
    
    const estimate = calculateFareEstimate({
      originLat,
      originLng,
      destLat,
      destLng,
      vehicleType: vehicleType || 'taxi',
      weatherCondition,
    });
    
    res.json(estimate);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Ride routes
router.route('/')
  .post(createRide)
  .get(getUserRides);

router.route('/:id')
  .get(getRideById)
  .put(updateRideStatus);

// Search for available drivers near a location
const { searchAvailableRides } = require('../controllers/rideController');
router.get('/search/nearby', searchAvailableRides);

router.put('/:id/accept', auth, acceptRide);
router.get('/available', auth, getAvailableRides);
router.put('/:id/cancel', auth, cancelRide);

module.exports = router;