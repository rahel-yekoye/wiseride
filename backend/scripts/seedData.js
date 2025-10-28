const mongoose = require('mongoose');
const Ride = require('../models/Ride');
const User = require('../models/User');
const bcrypt = require('bcryptjs');

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

// Create sample data
const seedData = async () => {
  try {
    console.log('Creating sample data...');
    
    // Create a test driver
    const hashedPassword = await bcrypt.hash('password123', 10);
    const driver = new User({
      name: 'John Driver',
      email: 'driver@wiseride.com',
      password: hashedPassword,
      role: 'driver',
      phone: '+251911234567',
      driverVerified: true,
      driverLicense: 'DL123456',
      vehicleInfo: {
        make: 'Toyota',
        model: 'Camry',
        year: 2020,
        color: 'White',
        plateNumber: 'AA-1234',
        capacity: 4
      },
      isOnline: false,
      earnings: {
        total: 2500,
        today: 120,
        thisWeek: 800,
        thisMonth: 2500
      },
      rating: {
        average: 4.8,
        count: 150
      }
    });
    
    await driver.save();
    console.log('✓ Created test driver');
    
    // Create test riders
    const rider1 = new User({
      name: 'Sarah Johnson',
      email: 'sarah@example.com',
      password: hashedPassword,
      role: 'rider',
      phone: '+251911234567',
      rating: {
        average: 4.5,
        count: 25
      }
    });
    
    const rider2 = new User({
      name: 'Michael Chen',
      email: 'michael@example.com',
      password: hashedPassword,
      role: 'rider',
      phone: '+251922345678',
      rating: {
        average: 4.2,
        count: 18
      }
    });
    
    const rider3 = new User({
      name: 'Alem Gebre',
      email: 'alem@example.com',
      password: hashedPassword,
      role: 'rider',
      phone: '+251933456789',
      rating: {
        average: 4.7,
        count: 32
      }
    });
    
    await Promise.all([rider1.save(), rider2.save(), rider3.save()]);
    console.log('✓ Created test riders');
    
    // Create sample rides
    const rides = [
      {
        type: 'public',
        riderId: rider1._id,
        origin: {
          lat: 8.9806,
          lng: 38.7578,
          address: 'Bole Airport, Addis Ababa',
          coordinates: {
            type: 'Point',
            coordinates: [38.7578, 8.9806]
          }
        },
        destination: {
          lat: 9.0054,
          lng: 38.7636,
          address: 'Meskel Square, Addis Ababa',
          coordinates: {
            type: 'Point',
            coordinates: [38.7636, 9.0054]
          }
        },
        vehicleType: 'taxi',
        status: 'requested'
      },
      {
        type: 'public',
        riderId: rider2._id,
        origin: {
          lat: 9.0192,
          lng: 38.7525,
          address: 'Addis Ababa University, Addis Ababa',
          coordinates: {
            type: 'Point',
            coordinates: [38.7525, 9.0192]
          }
        },
        destination: {
          lat: 9.0054,
          lng: 38.7636,
          address: 'Sheraton Addis, Addis Ababa',
          coordinates: {
            type: 'Point',
            coordinates: [38.7636, 9.0054]
          }
        },
        vehicleType: 'bus',
        status: 'requested'
      },
      {
        type: 'public',
        riderId: rider3._id,
        origin: {
          lat: 9.0192,
          lng: 38.7525,
          address: 'Mercato, Addis Ababa',
          coordinates: {
            type: 'Point',
            coordinates: [38.7525, 9.0192]
          }
        },
        destination: {
          lat: 8.9806,
          lng: 38.7578,
          address: 'Bole Road, Addis Ababa',
          coordinates: {
            type: 'Point',
            coordinates: [38.7578, 8.9806]
          }
        },
        vehicleType: 'minibus',
        status: 'requested'
      }
    ];
    
    await Ride.insertMany(rides);
    console.log('✓ Created sample rides');
    
    console.log('Sample data created successfully!');
    console.log('You can now test the driver functionality with:');
    console.log('- Driver email: driver@wiseride.com');
    console.log('- Password: password123');
    
  } catch (error) {
    console.error('Error creating sample data:', error);
  }
};

// Main function
const main = async () => {
  await connectDB();
  await seedData();
  process.exit(0);
};

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { seedData };
