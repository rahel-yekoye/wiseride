const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const dotenv = require('dotenv');
const http = require('http');
const cron = require('node-cron');

// Load environment variables
dotenv.config();

// Database connection
const connectDB = require('./config/db');
const { createIndexes } = require('./scripts/initIndexes');

// Connect to database
connectDB().then(async () => {
  // Create indexes after connection
  try {
    await createIndexes();
    console.log('Database indexes initialized');
  } catch (error) {
    console.error('Error initializing indexes:', error);
  }
});

// Initialize app
const app = express();
const server = http.createServer(app);

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Routes
app.get('/', (req, res) => {
  res.json({ 
    message: 'WiseRide API', 
    version: '1.0.0',
    description: 'Public Transport Scheduling and Route Guidance API for Addis Ababa'
  });
});

// API routes
app.use('/api/users', require('./routes/userRoutes'));
app.use('/api/rides', require('./routes/rideRoutes'));
app.use('/api/school', require('./routes/schoolRoutes'));
app.use('/api/driver', require('./routes/driverRoutes'));
app.use('/api/registration', require('./routes/registrationRoutes'));
app.use('/api/earnings', require('./routes/earningsRoutes'));

// New enhanced feature routes
app.use('/api/ratings', require('./routes/ratingRoutes'));
app.use('/api/promo', require('./routes/promoCodeRoutes'));
app.use('/api/ride-history', require('./routes/rideHistoryRoutes'));
app.use('/api/emergency', require('./routes/emergencyRoutes'));

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : {}
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

// Initialize Socket.io
const { initializeSocket } = require('./services/socketService');
const io = initializeSocket(server);

// Scheduled tasks for earnings reset
const { resetEarnings } = require('./controllers/earningsController');

// Reset daily earnings at midnight
cron.schedule('0 0 * * *', () => {
  console.log('Running daily earnings reset...');
  resetEarnings('daily');
});

// Reset weekly earnings every Monday at midnight
cron.schedule('0 0 * * 1', () => {
  console.log('Running weekly earnings reset...');
  resetEarnings('weekly');
});

// Reset monthly earnings on the 1st of each month at midnight
cron.schedule('0 0 1 * *', () => {
  console.log('Running monthly earnings reset...');
  resetEarnings('monthly');
});

// Port configuration
const PORT = process.env.PORT || 4000;

// Start server
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log('Socket.io initialized for real-time notifications');
  console.log('Scheduled tasks initialized for earnings reset');
});

module.exports = { app, server, io };