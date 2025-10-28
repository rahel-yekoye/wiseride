const socketIO = require('socket.io');
const jwt = require('jsonwebtoken');

let io;
const connectedDrivers = new Map(); // Map of driverId -> socketId
const connectedRiders = new Map(); // Map of riderId -> socketId

const initializeSocket = (server) => {
  io = socketIO(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    }
  });

  // Authentication middleware
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      
      if (!token) {
        return next(new Error('Authentication error'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.userId;
      socket.userRole = decoded.role;
      
      next();
    } catch (error) {
      next(new Error('Authentication error'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`User connected: ${socket.userId} (${socket.userRole})`);

    // Store connection based on role
    if (socket.userRole === 'driver') {
      connectedDrivers.set(socket.userId, socket.id);
      socket.join('drivers');
      console.log(`Driver ${socket.userId} joined drivers room`);
    } else if (socket.userRole === 'rider') {
      connectedRiders.set(socket.userId, socket.id);
      socket.join('riders');
      console.log(`Rider ${socket.userId} joined riders room`);
    }

    // Driver location update
    socket.on('driver:location:update', (data) => {
      if (socket.userRole === 'driver') {
        // Broadcast location to specific rider if in active ride
        if (data.riderId) {
          const riderSocketId = connectedRiders.get(data.riderId);
          if (riderSocketId) {
            io.to(riderSocketId).emit('driver:location:updated', {
              driverId: socket.userId,
              location: data.location,
              eta: data.eta
            });
          }
        }
      }
    });

    // Driver online status
    socket.on('driver:status:update', (data) => {
      if (socket.userRole === 'driver') {
        console.log(`Driver ${socket.userId} is now ${data.isOnline ? 'online' : 'offline'}`);
      }
    });

    // Ride request from rider
    socket.on('ride:request', (rideData) => {
      if (socket.userRole === 'rider') {
        // Broadcast to all online drivers in the area
        socket.to('drivers').emit('ride:new_request', {
          rideId: rideData.rideId,
          riderId: socket.userId,
          origin: rideData.origin,
          destination: rideData.destination,
          fare: rideData.fare,
          vehicleType: rideData.vehicleType
        });
        console.log(`New ride request from rider ${socket.userId}`);
      }
    });

    // Driver accepts ride
    socket.on('ride:accept', (data) => {
      if (socket.userRole === 'driver') {
        const riderSocketId = connectedRiders.get(data.riderId);
        if (riderSocketId) {
          io.to(riderSocketId).emit('ride:accepted', {
            rideId: data.rideId,
            driverId: socket.userId,
            driverInfo: data.driverInfo,
            estimatedArrival: data.estimatedArrival
          });
          console.log(`Driver ${socket.userId} accepted ride ${data.rideId}`);
        }
      }
    });

    // Driver starts ride
    socket.on('ride:start', (data) => {
      if (socket.userRole === 'driver') {
        const riderSocketId = connectedRiders.get(data.riderId);
        if (riderSocketId) {
          io.to(riderSocketId).emit('ride:started', {
            rideId: data.rideId,
            driverId: socket.userId,
            startTime: data.startTime
          });
          console.log(`Driver ${socket.userId} started ride ${data.rideId}`);
        }
      }
    });

    // Driver completes ride
    socket.on('ride:complete', (data) => {
      if (socket.userRole === 'driver') {
        const riderSocketId = connectedRiders.get(data.riderId);
        if (riderSocketId) {
          io.to(riderSocketId).emit('ride:completed', {
            rideId: data.rideId,
            driverId: socket.userId,
            fare: data.fare,
            endTime: data.endTime
          });
          console.log(`Driver ${socket.userId} completed ride ${data.rideId}`);
        }
      }
    });

    // Ride cancelled
    socket.on('ride:cancel', (data) => {
      if (socket.userRole === 'rider') {
        const driverSocketId = connectedDrivers.get(data.driverId);
        if (driverSocketId) {
          io.to(driverSocketId).emit('ride:cancelled', {
            rideId: data.rideId,
            riderId: socket.userId,
            reason: data.reason
          });
        }
      } else if (socket.userRole === 'driver') {
        const riderSocketId = connectedRiders.get(data.riderId);
        if (riderSocketId) {
          io.to(riderSocketId).emit('ride:cancelled', {
            rideId: data.rideId,
            driverId: socket.userId,
            reason: data.reason
          });
        }
      }
    });

    // Disconnect
    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.userId}`);
      
      if (socket.userRole === 'driver') {
        connectedDrivers.delete(socket.userId);
      } else if (socket.userRole === 'rider') {
        connectedRiders.delete(socket.userId);
      }
    });
  });

  return io;
};

// Helper functions to emit events from controllers
const emitToDriver = (driverId, event, data) => {
  const socketId = connectedDrivers.get(driverId);
  if (socketId && io) {
    io.to(socketId).emit(event, data);
    return true;
  }
  return false;
};

const emitToRider = (riderId, event, data) => {
  const socketId = connectedRiders.get(riderId);
  if (socketId && io) {
    io.to(socketId).emit(event, data);
    return true;
  }
  return false;
};

const emitToAllDrivers = (event, data) => {
  if (io) {
    io.to('drivers').emit(event, data);
    return true;
  }
  return false;
};

const emitToAllRiders = (event, data) => {
  if (io) {
    io.to('riders').emit(event, data);
    return true;
  }
  return false;
};

const getConnectedDrivers = () => {
  return Array.from(connectedDrivers.keys());
};

const getConnectedRiders = () => {
  return Array.from(connectedRiders.keys());
};

const isDriverOnline = (driverId) => {
  return connectedDrivers.has(driverId);
};

const isRiderOnline = (riderId) => {
  return connectedRiders.has(riderId);
};

module.exports = {
  initializeSocket,
  emitToDriver,
  emitToRider,
  emitToAllDrivers,
  emitToAllRiders,
  getConnectedDrivers,
  getConnectedRiders,
  isDriverOnline,
  isRiderOnline
};
