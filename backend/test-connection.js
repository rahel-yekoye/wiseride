const mongoose = require('mongoose');

// Test database connection
const testConnection = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/wiseride', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ MongoDB connected successfully');
    
    // Test creating a simple document
    const testSchema = new mongoose.Schema({
      name: String,
      coordinates: {
        type: {
          type: String,
          enum: ['Point'],
          default: 'Point'
        },
        coordinates: [Number]
      }
    });
    
    testSchema.index({ coordinates: '2dsphere' });
    
    const TestModel = mongoose.model('Test', testSchema);
    
    // Create a test document
    const testDoc = new TestModel({
      name: 'Test Location',
      coordinates: {
        type: 'Point',
        coordinates: [38.7578, 8.9806] // Addis Ababa coordinates
      }
    });
    
    await testDoc.save();
    console.log('✅ Test document created successfully');
    
    // Test geospatial query
    const nearby = await TestModel.find({
      coordinates: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [38.7578, 8.9806]
          },
          $maxDistance: 1000
        }
      }
    });
    
    console.log('✅ Geospatial query test successful');
    console.log(`Found ${nearby.length} nearby documents`);
    
    // Clean up
    await TestModel.deleteMany({});
    console.log('✅ Test cleanup completed');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
};

testConnection();
