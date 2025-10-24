const Ride = require('../models/Ride');
const User = require('../models/User');

// Create a new ride
const createRide = async (req, res) => {
  try {
    const { type, origin, destination, vehicleType } = req.body;

    const ride = await Ride.create({
      type,
      riderId: req.user._id,
      origin,
      destination,
      vehicleType,
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

module.exports = {
  createRide,
  getUserRides,
  getRideById,
  updateRideStatus,
  acceptRide,
  getAvailableRides,
  cancelRide,
};