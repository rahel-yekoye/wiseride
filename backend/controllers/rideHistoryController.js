const Ride = require('../models/Ride');
const Rating = require('../models/Rating');
const User = require('../models/User');

// Get detailed ride history with filters
const getRideHistory = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      status,
      startDate,
      endDate,
      vehicleType,
    } = req.query;

    const query = {
      $or: [
        { riderId: req.user._id },
        { driverId: req.user._id },
      ],
    };

    // Apply filters
    if (status) query.status = status;
    if (vehicleType) query.vehicleType = vehicleType;
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    const rides = await Ride.find(query)
      .populate('riderId', 'name phone profilePicture')
      .populate('driverId', 'name phone profilePicture vehicleInfo rating')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Ride.countDocuments(query);

    // Get ratings for these rides
    const rideIds = rides.map(ride => ride._id);
    const ratings = await Rating.find({ rideId: { $in: rideIds } });
    const ratingsMap = {};
    ratings.forEach(rating => {
      ratingsMap[rating.rideId.toString()] = rating;
    });

    // Attach ratings to rides
    const ridesWithRatings = rides.map(ride => {
      const rideObj = ride.toObject();
      rideObj.rating = ratingsMap[ride._id.toString()] || null;
      return rideObj;
    });

    res.json({
      rides: ridesWithRatings,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      totalRides: count,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get ride statistics
const getRideStatistics = async (req, res) => {
  try {
    const { period = 'month' } = req.query; // day, week, month, year, all

    let startDate = new Date();
    switch (period) {
      case 'day':
        startDate.setHours(0, 0, 0, 0);
        break;
      case 'week':
        startDate.setDate(startDate.getDate() - 7);
        break;
      case 'month':
        startDate.setMonth(startDate.getMonth() - 1);
        break;
      case 'year':
        startDate.setFullYear(startDate.getFullYear() - 1);
        break;
      case 'all':
        startDate = new Date(0); // Beginning of time
        break;
    }

    const query = {
      $or: [
        { riderId: req.user._id },
        { driverId: req.user._id },
      ],
      createdAt: { $gte: startDate },
    };

    // Aggregate statistics
    const stats = await Ride.aggregate([
      { $match: query },
      {
        $group: {
          _id: null,
          totalRides: { $sum: 1 },
          completedRides: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] },
          },
          cancelledRides: {
            $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] },
          },
          totalFare: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, '$fare', 0] },
          },
          avgFare: {
            $avg: { $cond: [{ $eq: ['$status', 'completed'] }, '$fare', null] },
          },
        },
      },
    ]);

    // Get ride distribution by vehicle type
    const vehicleDistribution = await Ride.aggregate([
      { $match: query },
      {
        $group: {
          _id: '$vehicleType',
          count: { $sum: 1 },
        },
      },
    ]);

    // Get ride distribution by hour (for peak time analysis)
    const hourlyDistribution = await Ride.aggregate([
      { $match: query },
      {
        $group: {
          _id: { $hour: '$createdAt' },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    res.json({
      period,
      statistics: stats[0] || {
        totalRides: 0,
        completedRides: 0,
        cancelledRides: 0,
        totalFare: 0,
        avgFare: 0,
      },
      vehicleDistribution,
      hourlyDistribution,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get single ride details with full information
const getRideDetails = async (req, res) => {
  try {
    const ride = await Ride.findById(req.params.id)
      .populate('riderId', 'name phone email profilePicture')
      .populate('driverId', 'name phone email profilePicture vehicleInfo rating');

    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    // Check authorization
    const isRider = ride.riderId._id.toString() === req.user._id.toString();
    const isDriver = ride.driverId && ride.driverId._id.toString() === req.user._id.toString();

    if (!isRider && !isDriver) {
      return res.status(403).json({ message: 'Not authorized to view this ride' });
    }

    // Get rating if exists
    const rating = await Rating.findOne({ rideId: ride._id });

    // Calculate trip duration
    let duration = null;
    if (ride.startTime && ride.endTime) {
      duration = Math.round((ride.endTime - ride.startTime) / 60000); // minutes
    }

    res.json({
      ride,
      rating,
      duration,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Export ride history (CSV format)
const exportRideHistory = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const query = {
      $or: [
        { riderId: req.user._id },
        { driverId: req.user._id },
      ],
    };

    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) query.createdAt.$gte = new Date(startDate);
      if (endDate) query.createdAt.$lte = new Date(endDate);
    }

    const rides = await Ride.find(query)
      .populate('riderId', 'name phone')
      .populate('driverId', 'name phone')
      .sort({ createdAt: -1 });

    // Generate CSV
    let csv = 'Date,Rider,Driver,Origin,Destination,Status,Fare,Vehicle Type\n';
    
    rides.forEach(ride => {
      const date = new Date(ride.createdAt).toLocaleDateString();
      const rider = ride.riderId?.name || 'N/A';
      const driver = ride.driverId?.name || 'N/A';
      const origin = ride.origin.address.replace(/,/g, ';');
      const destination = ride.destination.address.replace(/,/g, ';');
      const status = ride.status;
      const fare = ride.fare || 0;
      const vehicleType = ride.vehicleType;

      csv += `${date},${rider},${driver},${origin},${destination},${status},${fare},${vehicleType}\n`;
    });

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=ride-history.csv');
    res.send(csv);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get favorite locations (most frequent pickup/dropoff points)
const getFavoriteLocations = async (req, res) => {
  try {
    const { type = 'both' } = req.query; // 'pickup', 'dropoff', or 'both'

    const matchStage = {
      riderId: req.user._id,
      status: 'completed',
    };

    let locations = [];

    if (type === 'pickup' || type === 'both') {
      const pickups = await Ride.aggregate([
        { $match: matchStage },
        {
          $group: {
            _id: '$origin.address',
            count: { $sum: 1 },
            coordinates: { $first: '$origin.coordinates' },
          },
        },
        { $sort: { count: -1 } },
        { $limit: 5 },
      ]);
      locations.push(...pickups.map(p => ({ ...p, type: 'pickup' })));
    }

    if (type === 'dropoff' || type === 'both') {
      const dropoffs = await Ride.aggregate([
        { $match: matchStage },
        {
          $group: {
            _id: '$destination.address',
            count: { $sum: 1 },
            coordinates: { $first: '$destination.coordinates' },
          },
        },
        { $sort: { count: -1 } },
        { $limit: 5 },
      ]);
      locations.push(...dropoffs.map(d => ({ ...d, type: 'dropoff' })));
    }

    res.json({ favoriteLocations: locations });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getRideHistory,
  getRideStatistics,
  getRideDetails,
  exportRideHistory,
  getFavoriteLocations,
};
