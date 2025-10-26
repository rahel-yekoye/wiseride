const Ride = require('../models/Ride');
const User = require('../models/User');
const { io } = require('../app');

// Helper function to calculate distance between two points (Haversine formula)
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Radius of the earth in km
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const d = R * c; // Distance in km
  return d;
};

const deg2rad = (deg) => {
  return deg * (Math.PI / 180);
};

// Helper function to calculate estimated fare
const calculateEstimatedFare = (distance, vehicleType) => {
  // Base fare varies by vehicle type
  const baseFares = {
    'bus': 2.50,
    'taxi': 5.00,
    'minibus': 4.00,
    'private_car': 6.00
  };

  // Per km rate varies by vehicle type
  const perKmRates = {
    'bus': 0.50,
    'taxi': 1.20,
    'minibus': 0.80,
    'private_car': 1.50
  };

  const baseFare = baseFares[vehicleType] || 5.00;
  const perKmRate = perKmRates[vehicleType] || 1.00;

  return baseFare + (distance * perKmRate);
};

// Helper function to calculate route points between two locations
// In a real implementation, you would use a routing API like Google Maps Directions API
const calculateRoute = (origin, destination) => {
  // For now, we'll create a simple straight line
  // In a real implementation, you would get actual route points from a directions API
  return [
    { lat: origin.lat, lng: origin.lng },
    { lat: destination.lat, lng: destination.lng }
  ];
};

// Create a new ride
const createRide = async (req, res) => {
  try {
    const { type, origin, destination, vehicleType, fare } = req.body;

    // Use provided fare if available (from frontend calculation), otherwise calculate
    let finalFare = fare;
    if (!finalFare) {
      const distance = calculateDistance(
        origin.lat, 
        origin.lng, 
        destination.lat, 
        destination.lng
      );
      finalFare = calculateEstimatedFare(distance, vehicleType);
    }

    const ride = await Ride.create({
      type: type || 'public',
      riderId: req.user._id,
      origin,
      destination,
      vehicleType,
      fare: finalFare
    });

    res.status(201).json(ride);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all rides for a user
const getUserRides = async (req, res) => {
  try {
    const rides = await Ride.find({ 
      $or: [{ riderId: req.user._id }, { driverId: req.user._id }] 
    }).sort({ createdAt: -1 });
    
    res.json(rides);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get ride by ID
const getRideById = async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }
    
    // Check if user is authorized to view this ride
    if (ride.riderId.toString() !== req.user._id.toString() && 
        ride.driverId && ride.driverId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }
    
    res.json(ride);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update ride status
const updateRideStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const ride = await Ride.findById(req.params.id);
    
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }
    
    // Check if user is authorized to update this ride
    if (ride.riderId.toString() !== req.user._id.toString() && 
        ride.driverId && ride.driverId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }
    
    ride.status = status;
    
    if (status === 'in_progress') {
      ride.startTime = new Date();
    } else if (status === 'completed') {
      ride.endTime = new Date();
    }
    
    const updatedRide = await ride.save();
    res.json(updatedRide);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Accept ride (for drivers)
const acceptRide = async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }
    
    // Check if user is a driver
    if (req.user.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can accept rides' });
    }
    
    // Check if ride is still available
    if (ride.status !== 'requested') {
      return res.status(400).json({ message: 'Ride is no longer available' });
    }
    
    ride.driverId = req.user._id;
    ride.status = 'accepted';
    const updatedRide = await ride.save();
    
    // Emit real-time update
    io.emit('ride_accepted', {
      rideId: ride._id,
      driverId: req.user._id,
      riderId: ride.riderId,
      status: 'accepted'
    });
    
    res.json(updatedRide);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get available rides (for drivers)
const getAvailableRides = async (req, res) => {
  try {
    // Check if user is a driver
    if (req.user.role !== 'driver') {
      return res.status(401).json({ message: 'Only drivers can view available rides' });
    }
    
    const rides = await Ride.find({ 
      status: 'requested',
      type: 'public'
    }).sort({ createdAt: -1 });
    
    res.json(rides);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Search for available rides (for riders)
const searchAvailableRides = async (req, res) => {
  try {
    // Check if user is a rider
    if (req.user.role !== 'rider' && req.user.role !== 'parent') {
      return res.status(401).json({ message: 'Only riders can search for available rides' });
    }
    
    const { origin, destination, vehicleType } = req.body;
    
    // Build the query
    const query = { 
      status: 'requested',
      type: 'public'
    };
    
    // Add vehicle type filter if provided
    if (vehicleType) {
      query.vehicleType = vehicleType;
    }
    
    // If no rides found, create some sample rides for demonstration
    let rides = await Ride.find(query).sort({ createdAt: -1 });
    
    // If no rides exist, create sample rides
    if (rides.length === 0) {
      await createSampleRides();
      rides = await Ride.find(query).sort({ createdAt: -1 });
    }
    
    // Filter rides based on proximity to origin and destination
    let filteredRides = rides;
    
    if (origin && destination) {
      filteredRides = rides.filter(ride => {
        // Calculate distance from search origin to ride origin
        const originDistance = calculateDistance(
          origin.lat, origin.lng,
          ride.origin.lat, ride.origin.lng
        );
        
        // Calculate distance from search destination to ride destination
        const destDistance = calculateDistance(
          destination.lat, destination.lng,
          ride.destination.lat, ride.destination.lng
        );
        
        // Accept rides within 5km of origin and 5km of destination
        return originDistance <= 5 && destDistance <= 5;
      });
    }
    
    // Add route information to each ride
    const ridesWithRoutes = filteredRides.map(ride => {
      const route = calculateRoute(ride.origin, ride.destination);
      return {
        ...ride.toObject(),
        route: route
      };
    });
    
    res.json(ridesWithRoutes);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Cancel ride
const cancelRide = async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }
    
    // Check if user is authorized to cancel this ride
    if (ride.riderId.toString() !== req.user._id.toString() && 
        ride.driverId && ride.driverId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized' });
    }
    
    ride.status = 'cancelled';
    const updatedRide = await ride.save();
    
    res.json(updatedRide);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Start ride (for drivers)
const startRide = async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }
    
    // Check if user is the driver of this ride
    if (ride.driverId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Only the assigned driver can start this ride' });
    }
    
    // Check if ride is accepted
    if (ride.status !== 'accepted') {
      return res.status(400).json({ message: 'Ride must be accepted before starting' });
    }
    
    ride.status = 'in_progress';
    ride.startTime = new Date();
    const updatedRide = await ride.save();
    
    // Emit real-time update
    io.emit('ride_started', {
      rideId: ride._id,
      driverId: ride.driverId,
      riderId: ride.riderId,
      status: 'in_progress',
      startTime: ride.startTime
    });
    
    res.json(updatedRide);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// End ride (for drivers)
const endRide = async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id);
    
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }
    
    // Check if user is the driver of this ride
    if (ride.driverId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Only the assigned driver can end this ride' });
    }
    
    // Check if ride is in progress
    if (ride.status !== 'in_progress') {
      return res.status(400).json({ message: 'Ride must be in progress to end' });
    }
    
    ride.status = 'completed';
    ride.endTime = new Date();
    const updatedRide = await ride.save();
    
    // Emit real-time update
    io.emit('ride_completed', {
      rideId: ride._id,
      driverId: ride.driverId,
      riderId: ride.riderId,
      status: 'completed',
      endTime: ride.endTime
    });
    
    res.json(updatedRide);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Rate ride
const rateRide = async (req, res) => {
  try {
    const { rating, feedback } = req.body;
    const ride = await Ride.findById(req.params.id);
    
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }
    
    // Check if user is authorized to rate this ride
    if (ride.riderId.toString() !== req.user._id.toString() && 
        ride.driverId.toString() !== req.user._id.toString()) {
      return res.status(401).json({ message: 'Not authorized to rate this ride' });
    }
    
    // Add rating to ride
    if (!ride.ratings) {
      ride.ratings = [];
    }
    
    ride.ratings.push({
      userId: req.user._id,
      rating: rating,
      feedback: feedback,
      createdAt: new Date()
    });
    
    const updatedRide = await ride.save();
    res.json(updatedRide);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get ride statistics
const getRideStats = async (req, res) => {
  try {
    const userId = req.user._id;
    const role = req.user.role;
    
    let stats = {};
    
    if (role === 'driver') {
      stats = await Ride.aggregate([
        { $match: { driverId: userId } },
        {
          $group: {
            _id: null,
            totalRides: { $sum: 1 },
            completedRides: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
            totalEarnings: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, '$fare', 0] } },
            averageRating: { $avg: '$ratings.rating' }
          }
        }
      ]);
    } else {
      stats = await Ride.aggregate([
        { $match: { riderId: userId } },
        {
          $group: {
            _id: null,
            totalRides: { $sum: 1 },
            completedRides: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
            totalSpent: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, '$fare', 0] } }
          }
        }
      ]);
    }
    
    res.json(stats[0] || {});
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Create sample rides for demonstration
const createSampleRides = async () => {
  try {
    // Check if sample rides already exist
    const existingRides = await Ride.find({ status: 'requested' });
    if (existingRides.length > 0) {
      return;
    }

    // Create sample rides with different vehicle types and routes
    const sampleRides = [
      {
        type: 'public',
        origin: {
          lat: 9.0192,
          lng: 38.7525,
          address: 'Meskel Square, Addis Ababa'
        },
        destination: {
          lat: 9.0054,
          lng: 38.7636,
          address: 'Bole International Airport, Addis Ababa'
        },
        vehicleType: 'bus',
        fare: 15.50,
        status: 'requested'
      },
      {
        type: 'public',
        origin: {
          lat: 9.0192,
          lng: 38.7525,
          address: 'Meskel Square, Addis Ababa'
        },
        destination: {
          lat: 9.0054,
          lng: 38.7636,
          address: 'Bole International Airport, Addis Ababa'
        },
        vehicleType: 'taxi',
        fare: 45.00,
        status: 'requested'
      },
      {
        type: 'public',
        origin: {
          lat: 9.0192,
          lng: 38.7525,
          address: 'Meskel Square, Addis Ababa'
        },
        destination: {
          lat: 9.0054,
          lng: 38.7636,
          address: 'Bole International Airport, Addis Ababa'
        },
        vehicleType: 'minibus',
        fare: 25.00,
        status: 'requested'
      },
      {
        type: 'public',
        origin: {
          lat: 8.9806,
          lng: 38.7578,
          address: 'Piazza, Addis Ababa'
        },
        destination: {
          lat: 9.0192,
          lng: 38.7525,
          address: 'Meskel Square, Addis Ababa'
        },
        vehicleType: 'bus',
        fare: 8.50,
        status: 'requested'
      },
      {
        type: 'public',
        origin: {
          lat: 8.9806,
          lng: 38.7578,
          address: 'Piazza, Addis Ababa'
        },
        destination: {
          lat: 9.0192,
          lng: 38.7525,
          address: 'Meskel Square, Addis Ababa'
        },
        vehicleType: 'taxi',
        fare: 35.00,
        status: 'requested'
      }
    ];

    // Create rides (we'll use a dummy rider ID for now)
    for (const rideData of sampleRides) {
      await Ride.create(rideData);
    }

    console.log('Sample rides created successfully');
  } catch (error) {
    console.error('Error creating sample rides:', error);
  }
};

module.exports = {
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
  getRideStats,
};