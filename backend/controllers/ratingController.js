const Rating = require('../models/Rating');
const Ride = require('../models/Ride');
const User = require('../models/User');

// Submit rating for a completed ride
const submitRating = async (req, res) => {
  try {
    const { rideId } = req.params;
    const { score, review, categories } = req.body;

    // Verify ride exists and is completed
    const ride = await Ride.findById(rideId);
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    if (ride.status !== 'completed') {
      return res.status(400).json({ message: 'Can only rate completed rides' });
    }

    // Check if user is part of this ride
    const isRider = ride.riderId.toString() === req.user._id.toString();
    const isDriver = ride.driverId && ride.driverId.toString() === req.user._id.toString();

    if (!isRider && !isDriver) {
      return res.status(403).json({ message: 'Not authorized to rate this ride' });
    }

    // Find or create rating document
    let rating = await Rating.findOne({ rideId });
    
    if (!rating) {
      rating = new Rating({
        rideId,
        driverId: ride.driverId,
        riderId: ride.riderId,
      });
    }

    // Update appropriate rating based on user role
    if (isRider) {
      // Rider rating driver
      if (rating.driverRating && rating.driverRating.score) {
        return res.status(400).json({ message: 'You have already rated this ride' });
      }

      rating.driverRating = {
        score,
        review,
        categories,
      };

      // Update driver's overall rating
      await updateDriverRating(ride.driverId);
    } else if (isDriver) {
      // Driver rating rider
      if (rating.riderRating && rating.riderRating.score) {
        return res.status(400).json({ message: 'You have already rated this ride' });
      }

      rating.riderRating = {
        score,
        review,
        categories,
      };

      // Update rider's overall rating
      await updateRiderRating(ride.riderId);
    }

    await rating.save();

    res.json({
      message: 'Rating submitted successfully',
      rating,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update driver's overall rating
async function updateDriverRating(driverId) {
  const ratings = await Rating.find({
    driverId,
    'driverRating.score': { $exists: true },
  });

  if (ratings.length === 0) return;

  const totalScore = ratings.reduce((sum, r) => sum + r.driverRating.score, 0);
  const average = totalScore / ratings.length;

  await User.findByIdAndUpdate(driverId, {
    'rating.average': parseFloat(average.toFixed(2)),
    'rating.count': ratings.length,
  });
}

// Update rider's overall rating
async function updateRiderRating(riderId) {
  const ratings = await Rating.find({
    riderId,
    'riderRating.score': { $exists: true },
  });

  if (ratings.length === 0) return;

  const totalScore = ratings.reduce((sum, r) => sum + r.riderRating.score, 0);
  const average = totalScore / ratings.length;

  await User.findByIdAndUpdate(riderId, {
    'rating.average': parseFloat(average.toFixed(2)),
    'rating.count': ratings.length,
  });
}

// Get ratings for a user (driver or rider)
const getUserRatings = async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 20, role = 'driver' } = req.query;

    const query = role === 'driver' 
      ? { driverId: userId, 'driverRating.score': { $exists: true } }
      : { riderId: userId, 'riderRating.score': { $exists: true } };

    const ratings = await Rating.find(query)
      .populate('riderId', 'name profilePicture')
      .populate('driverId', 'name profilePicture')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Rating.countDocuments(query);

    // Calculate rating distribution
    const distribution = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    ratings.forEach(rating => {
      const score = role === 'driver' 
        ? rating.driverRating.score 
        : rating.riderRating.score;
      distribution[Math.floor(score)]++;
    });

    res.json({
      ratings,
      totalPages: Math.ceil(count / limit),
      currentPage: page,
      totalRatings: count,
      distribution,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get rating for a specific ride
const getRideRating = async (req, res) => {
  try {
    const { rideId } = req.params;

    const rating = await Rating.findOne({ rideId })
      .populate('riderId', 'name profilePicture')
      .populate('driverId', 'name profilePicture');

    if (!rating) {
      return res.status(404).json({ message: 'No rating found for this ride' });
    }

    res.json(rating);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Report/dispute a rating
const disputeRating = async (req, res) => {
  try {
    const { rideId } = req.params;
    const { reason } = req.body;

    const rating = await Rating.findOne({ rideId });
    if (!rating) {
      return res.status(404).json({ message: 'Rating not found' });
    }

    // Verify user is part of this rating
    const isRider = rating.riderId.toString() === req.user._id.toString();
    const isDriver = rating.driverId.toString() === req.user._id.toString();

    if (!isRider && !isDriver) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    rating.isDisputed = true;
    rating.disputeReason = reason;
    await rating.save();

    res.json({
      message: 'Rating dispute submitted. Our team will review it.',
      rating,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get rating statistics for a user
const getRatingStatistics = async (req, res) => {
  try {
    const { userId } = req.params;
    const { role = 'driver' } = req.query;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const query = role === 'driver'
      ? { driverId: userId, 'driverRating.score': { $exists: true } }
      : { riderId: userId, 'riderRating.score': { $exists: true } };

    const ratings = await Rating.find(query);

    // Calculate category averages
    const categoryAverages = {};
    const categoryCounts = {};

    ratings.forEach(rating => {
      const ratingData = role === 'driver' ? rating.driverRating : rating.riderRating;
      
      if (ratingData.categories) {
        Object.keys(ratingData.categories).forEach(category => {
          if (!categoryAverages[category]) {
            categoryAverages[category] = 0;
            categoryCounts[category] = 0;
          }
          categoryAverages[category] += ratingData.categories[category];
          categoryCounts[category]++;
        });
      }
    });

    // Calculate final averages
    Object.keys(categoryAverages).forEach(category => {
      categoryAverages[category] = parseFloat(
        (categoryAverages[category] / categoryCounts[category]).toFixed(2)
      );
    });

    // Get recent reviews
    const recentReviews = ratings
      .filter(r => {
        const ratingData = role === 'driver' ? r.driverRating : r.riderRating;
        return ratingData.review && ratingData.review.trim() !== '';
      })
      .slice(0, 10)
      .map(r => ({
        score: role === 'driver' ? r.driverRating.score : r.riderRating.score,
        review: role === 'driver' ? r.driverRating.review : r.riderRating.review,
        createdAt: r.createdAt,
      }));

    res.json({
      overallRating: user.rating,
      categoryAverages,
      totalRatings: ratings.length,
      recentReviews,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  submitRating,
  getUserRatings,
  getRideRating,
  disputeRating,
  getRatingStatistics,
};
