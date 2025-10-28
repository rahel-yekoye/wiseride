# WiseRide Driver Functionality Setup Guide

This guide will help you set up the complete driver functionality with proper database indexing and sample data.

## Prerequisites

- Node.js (v14 or higher)
- MongoDB (local or cloud)
- Flutter SDK

## Backend Setup

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Environment Configuration
Create a `.env` file in the backend directory:
```env
NODE_ENV=development
PORT=4000
MONGODB_URI=mongodb://localhost:27017/wiseride
JWT_SECRET=your_jwt_secret_key_here
```

### 3. Database Setup
```bash
# Initialize database indexes
npm run init-db

# Add sample data
npm run seed-data

# Or run both at once
npm run setup
```

### 4. Start Backend Server
```bash
# Development mode
npm run dev

# Production mode
npm start
```

## Frontend Setup

### 1. Install Dependencies
```bash
cd mobile
flutter pub get
```

### 2. Run the App
```bash
# For web
flutter run -d chrome

# For mobile
flutter run
```

## Testing the Driver Functionality

### 1. Login as Driver
- **Email**: `driver@wiseride.com`
- **Password**: `password123`

### 2. Test Features
1. **Dashboard**: View earnings and status
2. **Profile**: Update driver information
3. **Available Rides**: See nearby ride requests
4. **Accept Rides**: Accept and manage rides
5. **Earnings**: View earnings history

## Database Schema

### User Model (Enhanced for Drivers)
```javascript
{
  name: String,
  email: String,
  role: 'driver',
  driverLicense: String,
  vehicleInfo: {
    make: String,
    model: String,
    year: Number,
    color: String,
    plateNumber: String,
    capacity: Number
  },
  isOnline: Boolean,
  currentLocation: {
    lat: Number,
    lng: Number,
    address: String,
    coordinates: {
      type: 'Point',
      coordinates: [lng, lat]
    }
  },
  earnings: {
    total: Number,
    today: Number,
    thisWeek: Number,
    thisMonth: Number
  },
  rating: {
    average: Number,
    count: Number
  }
}
```

### Ride Model (Geospatial Support)
```javascript
{
  type: 'public',
  riderId: ObjectId,
  driverId: ObjectId,
  origin: {
    lat: Number,
    lng: Number,
    address: String,
    coordinates: {
      type: 'Point',
      coordinates: [lng, lat]
    }
  },
  destination: {
    lat: Number,
    lng: Number,
    address: String,
    coordinates: {
      type: 'Point',
      coordinates: [lng, lat]
    }
  },
  status: 'requested|accepted|in_progress|completed|cancelled',
  vehicleType: 'taxi|bus|minibus|private_car',
  fare: Number
}
```

## API Endpoints

### Driver Endpoints
- `GET /api/driver/dashboard` - Get driver dashboard
- `PUT /api/driver/toggle-online` - Toggle online status
- `PUT /api/driver/location` - Update location
- `GET /api/driver/rides/nearby` - Get nearby rides
- `PUT /api/driver/rides/:id/accept` - Accept ride
- `PUT /api/driver/rides/:id/start` - Start ride
- `PUT /api/driver/rides/:id/complete` - Complete ride
- `GET /api/driver/earnings` - Get earnings
- `PUT /api/driver/profile` - Update profile

## Troubleshooting

### Common Issues

1. **Geospatial Index Error**
   ```bash
   # Run this to create indexes
   npm run init-db
   ```

2. **No Sample Data**
   ```bash
   # Run this to add sample data
   npm run seed-data
   ```

3. **Database Connection Issues**
   - Check MongoDB is running
   - Verify MONGODB_URI in .env file
   - Check network connectivity

4. **API Errors**
   - Check backend server is running on port 4000
   - Verify CORS settings
   - Check authentication tokens

### Database Indexes
The following indexes are automatically created:
- `origin.coordinates: 2dsphere` - For geospatial queries
- `destination.coordinates: 2dsphere` - For destination queries
- `status: 1, type: 1` - For ride filtering
- `currentLocation.coordinates: 2dsphere` - For driver location
- `role: 1, isOnline: 1` - For driver queries

## Sample Data

The setup includes sample data:
- 1 test driver account
- 3 test rider accounts
- 3 sample ride requests
- Pre-configured earnings and ratings

## Development Tips

1. **Hot Reload**: Use `npm run dev` for automatic restarts
2. **Database Reset**: Drop database and run `npm run setup` to reset
3. **API Testing**: Use Postman or similar tools to test endpoints
4. **Logs**: Check console for detailed error messages

## Production Deployment

1. Set `NODE_ENV=production`
2. Use a production MongoDB instance
3. Set secure JWT secrets
4. Configure proper CORS settings
5. Set up monitoring and logging

## Support

If you encounter issues:
1. Check the console logs
2. Verify database connectivity
3. Ensure all dependencies are installed
4. Check the API endpoints are accessible
