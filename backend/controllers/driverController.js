const User = require('../models/User');
const Ride = require('../models/Ride');
const { emitToRider, emitToAllDrivers } = require('../services/socketService');

// Update driver location
const updateLocation = async (req, res) => {
  try {
    const { lat, lng, address } = req.body;
    
    if (lat === undefined || lng === undefined) {
      return res.status(400).json({ message: 'Latitude and longitude are required' });
    }

    const driver = await User.findById(req.user._id);
    if (!driver || driver.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can update location' });
    }

    driver.currentLocation = {
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      address: address || 'Unknown location',
      timestamp: new Date(),
      coordinates: {
        type: 'Point',
        coordinates: [parseFloat(lng), parseFloat(lat)]
      }
    };

    await driver.save();
    res.json({ message: 'Location updated successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Toggle driver online/offline status
const toggleOnlineStatus = async (req, res) => {
  try {
    const driver = await User.findById(req.user._id);
    if (!driver || driver.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can toggle online status' });
    }

    driver.isOnline = !driver.isOnline;
    await driver.save();

    res.json({ 
      message: `Driver is now ${driver.isOnline ? 'online' : 'offline'}`,
      isOnline: driver.isOnline 
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get available rides near driver
const getNearbyRides = async (req, res) => {
  try {
    const { lat, lng, radius = 10 } = req.query; // radius in km
    
    if (!lat || !lng) {
      return res.status(400).json({ message: 'Latitude and longitude are required' });
    }

    const driver = await User.findById(req.user._id);
    if (!driver || driver.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can view nearby rides' });
    }

    // Find rides within radius using proper geospatial query
    const rides = await Ride.find({
      status: 'requested',
      type: 'public',
      'origin.coordinates': {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(lng), parseFloat(lat)]
          },
          $maxDistance: radius * 1000 // Convert km to meters
        }
      }
    }).populate('riderId', 'name phone rating');

    res.json(rides);
  } catch (error) {
    console.error('Error in getNearbyRides:', error);
    res.status(500).json({ message: error.message });
  }
};

// Accept a ride
const acceptRide = async (req, res) => {
  try {
    const { rideId } = req.params;
    
    const driver = await User.findById(req.user._id);
    if (!driver || driver.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can accept rides' });
    }

    if (!driver.isOnline) {
      return res.status(400).json({ message: 'Driver must be online to accept rides' });
    }

    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    if (ride.status !== 'requested') {
      return res.status(400).json({ message: 'Ride is no longer available' });
    }

    ride.driverId = req.user._id;
    ride.status = 'accepted';
    ride.estimatedArrival = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes from now

    await ride.save();
    
    // Populate driver info for response
    await ride.populate('driverId', 'name phone vehicleInfo rating');
    await ride.populate('riderId', 'name phone rating');

    // Send real-time notification to rider
    emitToRider(ride.riderId._id.toString(), 'ride:accepted', {
      rideId: ride._id,
      driver: {
        id: driver._id,
        name: driver.name,
        phone: driver.phone,
        vehicleInfo: driver.vehicleInfo,
        rating: driver.rating,
        currentLocation: driver.currentLocation
      },
      estimatedArrival: ride.estimatedArrival
    });

    res.json(ride);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Start a ride
const startRide = async (req, res) => {
  try {
    const { rideId } = req.params;
    
    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    if (ride.driverId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized to start this ride' });
    }

    if (ride.status !== 'accepted') {
      return res.status(400).json({ message: 'Ride must be accepted before starting' });
    }

    ride.status = 'in_progress';
    ride.startTime = new Date();
    await ride.save();

    // Send real-time notification to rider
    emitToRider(ride.riderId.toString(), 'ride:started', {
      rideId: ride._id,
      startTime: ride.startTime
    });

    res.json(ride);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Complete a ride
const completeRide = async (req, res) => {
  try {
    const { rideId } = req.params;
    const { fare } = req.body;
    
    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    if (ride.driverId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized to complete this ride' });
    }

    if (ride.status !== 'in_progress') {
      return res.status(400).json({ message: 'Ride must be in progress to complete' });
    }

    ride.status = 'completed';
    ride.endTime = new Date();
    ride.fare = fare || 0;

    await ride.save();

    // Send real-time notification to rider
    emitToRider(ride.riderId.toString(), 'ride:completed', {
      rideId: ride._id,
      fare: ride.fare,
      endTime: ride.endTime
    });

    res.json(ride);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get driver earnings
const getEarnings = async (req, res) => {
  try {
    const driver = await User.findById(req.user._id);
    if (!driver || driver.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can view earnings' });
    }

    // Initialize earnings if not present
    if (!driver.earnings) {
      driver.earnings = {
        total: 0,
        today: 0,
        thisWeek: 0,
        thisMonth: 0
      };
      await driver.save();
    }

    // Get completed rides for this driver
    const completedRides = await Ride.find({
      driverId: req.user._id,
      status: 'completed'
    }).sort({ endTime: -1 });

    const earnings = {
      total: driver.earnings?.total || 0,
      today: driver.earnings?.today || 0,
      thisWeek: driver.earnings?.thisWeek || 0,
      thisMonth: driver.earnings?.thisMonth || 0,
      recentRides: completedRides.slice(0, 10) // Last 10 rides
    };

    res.json(earnings);
  } catch (error) {
    console.error('Error in getEarnings:', error);
    res.status(500).json({ message: error.message });
  }
};

// Update driver profile
const updateProfile = async (req, res) => {
  try {
    const { driverLicense, vehicleInfo } = req.body;
    
    const driver = await User.findById(req.user._id);
    if (!driver || driver.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can update profile' });
    }

    if (driverLicense) driver.driverLicense = driverLicense;
    if (vehicleInfo) driver.vehicleInfo = vehicleInfo;

    await driver.save();
    res.json(driver);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get driver dashboard data
const getDashboard = async (req, res) => {
  try {
    const driver = await User.findById(req.user._id);
    if (!driver || driver.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can view dashboard' });
    }

    // Initialize earnings if not present
    if (!driver.earnings) {
      driver.earnings = {
        total: 0,
        today: 0,
        thisWeek: 0,
        thisMonth: 0
      };
      await driver.save();
    }

    // Get recent rides
    const recentRides = await Ride.find({
      driverId: req.user._id
    }).sort({ createdAt: -1 }).limit(5).populate('riderId', 'name phone');

    // Get today's rides
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todayRides = await Ride.find({
      driverId: req.user._id,
      createdAt: { $gte: today, $lt: tomorrow }
    });

    const dashboard = {
      driver: {
        name: driver.name,
        rating: driver.rating || { average: 0, count: 0 },
        isOnline: driver.isOnline,
        earnings: driver.earnings,
        balance: driver.balance || 0
      },
      recentRides,
      todayRides: todayRides.length,
      todayEarnings: driver.earnings?.today || 0
    };

    res.json(dashboard);
  } catch (error) {
    console.error('Error in getDashboard:', error);
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  updateLocation,
  toggleOnlineStatus,
  getNearbyRides,
  acceptRide,
  startRide,
  completeRide,
  getEarnings,
  updateProfile,
  getDashboard
};
