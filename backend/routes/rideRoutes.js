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

router.route('/user')
  .get(getUserRides);

router.route('/:id')
  .get(getRideById);

router.route('/:id/status')
  .put(updateRideStatus);

// Search for available drivers/rides
router.route('/search')
  .post(searchAvailableRides);

// Get ride statistics
router.route('/stats')
  .get(getRideStats);

// Ride management routes
router.put('/:id/accept', acceptRide);
router.put('/:id/start', startRide);
router.put('/:id/end', endRide);
router.put('/:id/cancel', cancelRide);
router.post('/:id/rate', rateRide);

// Get available rides (for drivers)
router.get('/available', getAvailableRides);

// Backward compatibility for search endpoint
router.get('/search/nearby', searchAvailableRides);

module.exports = router;