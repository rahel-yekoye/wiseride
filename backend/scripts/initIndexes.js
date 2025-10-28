const mongoose = require('mongoose');
const Ride = require('../models/Ride');
const User = require('../models/User');

// Connect to database
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/wiseride', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('MongoDB connected');
  } catch (error) {
    console.error('MongoDB connection error:', error);
    process.exit(1);
  }
};

// Create geospatial indexes
const createIndexes = async () => {
  try {
    console.log('Creating geospatial indexes...');
    
    // Create 2dsphere index for origin coordinates
    await Ride.collection.createIndex({ 'origin.coordinates': '2dsphere' });
    console.log('✓ Created index for origin.coordinates');
    
    // Create 2dsphere index for destination coordinates
    await Ride.collection.createIndex({ 'destination.coordinates': '2dsphere' });
    console.log('✓ Created index for destination.coordinates');
    
    // Create index for status and type for better query performance
    await Ride.collection.createIndex({ status: 1, type: 1 });
    console.log('✓ Created index for status and type');
    
    // Create index for driver location
    await User.collection.createIndex({ 'currentLocation.coordinates': '2dsphere' });
    console.log('✓ Created index for driver currentLocation');
    
    // Create index for driver role and online status
    await User.collection.createIndex({ role: 1, isOnline: 1 });
    console.log('✓ Created index for driver role and online status');
    
    console.log('All indexes created successfully!');
  } catch (error) {
    console.error('Error creating indexes:', error);
  }
};

// Main function
const main = async () => {
  await connectDB();
  await createIndexes();
  process.exit(0);
};

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { createIndexes };

