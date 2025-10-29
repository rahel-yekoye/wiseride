const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const dotenv = require('dotenv');
const http = require('http');
const socketIo = require('socket.io');
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
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

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
app.use('/api/ratings', require('./routes/ratingRoutes'));
app.use('/api/promo', require('./routes/promoCodeRoutes'));
app.use('/api/ride-history', require('./routes/rideHistoryRoutes'));
app.use('/api/emergency', require('./routes/emergencyRoutes'));

// WebSocket connection handling
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // Join user-specific room
  socket.on('join_user_room', (data) => {
    socket.join(`user_${data.userId}`);
    console.log(`User ${data.userId} joined their room`);
  });

  // Join ride-specific room
  socket.on('join_ride_room', (data) => {
    socket.join(`ride_${data.rideId}`);
    console.log(`User joined ride room: ${data.rideId}`);
  });

  // Leave ride room
  socket.on('leave_ride_room', (data) => {
    socket.leave(`ride_${data.rideId}`);
    console.log(`User left ride room: ${data.rideId}`);
  });

  // Handle ride requests
  socket.on('ride_request', (data) => {
    // Notify available drivers
    socket.broadcast.emit('new_ride_request', data);
    console.log('Ride request broadcasted:', data.rideId);
  });

  // Handle driver location updates
  socket.on('driver_location_update', (data) => {
    // Broadcast to riders in the same ride
    socket.to(`ride_${data.rideId}`).emit('driver_location_update', data);
  });

  // Handle rider location updates
  socket.on('rider_location_update', (data) => {
    // Broadcast to drivers in the same ride
    socket.to(`ride_${data.rideId}`).emit('rider_location_update', data);
  });

  // Handle messages
  socket.on('message_to_driver', (data) => {
    socket.to(`ride_${data.rideId}`).emit('message_from_rider', data);
  });

  socket.on('message_to_rider', (data) => {
    socket.to(`ride_${data.rideId}`).emit('message_from_driver', data);
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

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
const PORT = process.env.PORT || 5000;

// Start server with socket.io
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log('Socket.io initialized for real-time notifications');
  console.log('Scheduled tasks initialized for earnings reset');
});

// Make io available to other modules
app.set('io', io);

module.exports = { app, server, io };