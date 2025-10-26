const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const dotenv = require('dotenv');
const http = require('http');
const socketIo = require('socket.io');

// Load environment variables
dotenv.config();

// Database connection
const connectDB = require('./config/db');

// Connect to database
connectDB();

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

// Port configuration
const PORT = process.env.PORT || 5000;

// Start server
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`WebSocket server initialized`);
});

// Make io available to other modules
app.set('io', io);

module.exports = { app, server, io };