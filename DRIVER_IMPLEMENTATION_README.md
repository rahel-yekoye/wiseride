# WiseRide Driver Functionality Implementation

## Overview

This document outlines the complete implementation of driver functionality for the WiseRide platform, including:

1. **Driver Registration System** - Complete onboarding flow with document verification
2. **Real-time Ride Request System** - WebSocket-based notifications for instant ride matching
3. **Earnings & Payment System** - Commission-based earnings with payout management

---

## 🚀 Features Implemented

### 1. Driver Registration & Onboarding

#### Models Created:
- **DriverDocument** (`models/DriverDocument.js`)
  - Stores driver verification documents
  - Tracks verification status
  - Supports multiple document types

#### Enhanced User Model:
- Driver registration status tracking
- Vehicle information with type
- Bank and mobile money payment details
- Availability schedule (weekly)
- Service areas
- Commission rate configuration
- Balance tracking

#### Registration Flow:
1. Driver starts registration with vehicle/payment info
2. Uploads required documents (license, registration, insurance, ID)
3. Submits for admin review
4. Admin approves/rejects with reasons
5. Driver gets verified and can start accepting rides

#### API Endpoints:
- `POST /api/registration/start` - Start registration
- `POST /api/registration/documents` - Upload documents
- `GET /api/registration/documents` - Get uploaded documents
- `POST /api/registration/submit` - Submit for review
- `GET /api/registration/status` - Check registration status
- `PUT /api/registration/:driverId/review` - Admin review (approve/reject)
- `GET /api/registration/pending` - Admin view pending registrations

---

### 2. Real-time Ride Request System

#### Socket.io Integration:
- **Service**: `services/socketService.js`
- Real-time bidirectional communication
- JWT authentication for socket connections
- Separate rooms for drivers and riders

#### Features:
- **Instant Notifications**: Drivers receive ride requests immediately
- **Location Tracking**: Real-time driver location updates to riders
- **Status Updates**: Live ride status changes (accepted, started, completed)
- **Driver Availability**: Online/offline status management

#### Socket Events:

**Driver Events:**
- `ride:new_request` - New ride available
- `driver:location:update` - Update driver location
- `driver:status:update` - Online/offline toggle
- `ride:accept` - Accept a ride
- `ride:start` - Start ride
- `ride:complete` - Complete ride
- `ride:cancel` - Cancel ride

**Rider Events:**
- `ride:accepted` - Driver accepted ride
- `ride:started` - Ride started
- `ride:completed` - Ride completed
- `driver:location:updated` - Driver location update

#### Enhanced Controllers:
- **driverController.js** - Added real-time notifications for ride actions
- **rideController.js** - Broadcasts new rides to all online drivers

---

### 3. Earnings & Payment System

#### Models Created:

**Transaction** (`models/Transaction.js`)
- Records all financial transactions
- Types: ride_earning, commission, payout, bonus, penalty, refund
- Tracks balance before/after each transaction
- Stores commission metadata

**Payout** (`models/Payout.js`)
- Manages payout requests
- Supports bank transfer, mobile money, cash
- Auto-generates reference numbers
- Tracks processing status

#### Commission System:
- **Default Rate**: 15% (configurable per driver)
- **Automatic Calculation**: Deducts commission from ride fare
- **Transparent Breakdown**: Shows total fare, commission, net amount
- **Balance Tracking**: Real-time driver balance updates

#### Earnings Features:
- **Real-time Balance**: Updated after each ride
- **Period Tracking**: Daily, weekly, monthly earnings
- **Transaction History**: Complete audit trail
- **Payout Requests**: Drivers can withdraw earnings
- **Minimum Payout**: 100 ETB threshold

#### API Endpoints:
- `POST /api/earnings/process` - Process ride earnings with commission
- `GET /api/earnings/summary` - Get earnings summary
- `GET /api/earnings/transactions` - Transaction history (paginated)
- `POST /api/earnings/payout/request` - Request payout
- `GET /api/earnings/payout/history` - Payout history
- `PUT /api/earnings/payout/:payoutId/process` - Admin process payout
- `GET /api/earnings/payout/pending` - Admin view pending payouts

#### Scheduled Tasks:
- **Daily Reset**: Midnight - Resets `earnings.today`
- **Weekly Reset**: Monday midnight - Resets `earnings.thisWeek`
- **Monthly Reset**: 1st of month - Resets `earnings.thisMonth`

---

## 📁 File Structure

```
backend/
├── models/
│   ├── User.js (enhanced)
│   ├── Ride.js
│   ├── DriverDocument.js (new)
│   ├── Transaction.js (new)
│   └── Payout.js (new)
├── controllers/
│   ├── driverController.js (enhanced)
│   ├── rideController.js (enhanced)
│   ├── registrationController.js (new)
│   └── earningsController.js (new)
├── routes/
│   ├── driverRoutes.js
│   ├── rideRoutes.js
│   ├── registrationRoutes.js (new)
│   └── earningsRoutes.js (new)
├── services/
│   └── socketService.js (new)
├── app.js (enhanced with Socket.io)
├── package.json (updated dependencies)
└── API_DOCUMENTATION.md (new)
```

---

## 🔧 Installation & Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

**New Dependencies Added:**
- `socket.io` - Real-time communication
- `multer` - File upload handling
- `node-cron` - Scheduled tasks

### 2. Environment Variables

Ensure your `.env` file has:
```env
PORT=4000
MONGODB_URI=mongodb://localhost:27017/wiseride
JWT_SECRET=your_jwt_secret_key
NODE_ENV=development
```

### 3. Initialize Database

```bash
npm run init-db
```

This creates necessary indexes for:
- Geospatial queries (location-based)
- Driver documents
- Transactions
- Payouts

### 4. Start Server

```bash
# Development
npm run dev

# Production
npm start
```

Server will start on `http://localhost:4000` with:
- REST API endpoints
- Socket.io server
- Scheduled cron jobs

---

## 🧪 Testing the Implementation

### 1. Driver Registration Flow

```bash
# 1. Register as driver
POST /api/users/register
{
  "name": "John Driver",
  "email": "john@example.com",
  "password": "password123",
  "role": "driver",
  "phone": "+251911234567"
}

# 2. Login
POST /api/users/login

# 3. Start registration
POST /api/registration/start
{
  "vehicleInfo": {
    "make": "Toyota",
    "model": "Corolla",
    "year": 2020,
    "color": "White",
    "plateNumber": "AA-12345",
    "capacity": 4,
    "vehicleType": "taxi"
  },
  "bankDetails": {
    "bankName": "CBE",
    "accountNumber": "1234567890",
    "accountHolderName": "John Driver"
  }
}

# 4. Upload documents
POST /api/registration/documents
{
  "documentType": "license",
  "documentUrl": "https://example.com/license.jpg",
  "documentNumber": "DL123456"
}

# 5. Submit for review
POST /api/registration/submit

# 6. Admin approves (as admin user)
PUT /api/registration/{driverId}/review
{
  "action": "approve"
}
```

### 2. Real-time Ride Flow

```javascript
// Driver connects
const socket = io('http://localhost:4000', {
  auth: { token: driverToken }
});

// Listen for new rides
socket.on('ride:new_request', (data) => {
  console.log('New ride:', data);
});

// Rider creates ride (triggers notification)
POST /api/rides
{
  "origin": { "lat": 9.0320, "lng": 38.7469, "address": "Bole" },
  "destination": { "lat": 9.0450, "lng": 38.7600, "address": "Piassa" },
  "vehicleType": "taxi"
}

// Driver accepts
PUT /api/driver/rides/{rideId}/accept

// Driver starts
PUT /api/driver/rides/{rideId}/start

// Driver completes
PUT /api/driver/rides/{rideId}/complete
{
  "fare": 150
}
```

### 3. Earnings & Payout Flow

```bash
# 1. Process ride earnings
POST /api/earnings/process
{
  "rideId": "ride_id_here",
  "totalFare": 150
}

# Response shows commission breakdown:
# Total: 150 ETB
# Commission (15%): 22.50 ETB
# Net: 127.50 ETB

# 2. Check earnings summary
GET /api/earnings/summary

# 3. View transactions
GET /api/earnings/transactions?page=1&limit=20

# 4. Request payout
POST /api/earnings/payout/request
{
  "amount": 1000,
  "paymentMethod": "bank_transfer"
}

# 5. Admin processes payout
PUT /api/earnings/payout/{payoutId}/process
{
  "action": "complete",
  "referenceNumber": "TXN123456"
}
```

---

## 🔐 Security Features

1. **JWT Authentication**: All endpoints protected
2. **Role-based Access**: Driver/Rider/Admin permissions
3. **Socket Authentication**: JWT verification for WebSocket connections
4. **Document Verification**: Admin approval required
5. **Balance Validation**: Prevents overdraft on payouts
6. **Transaction Integrity**: Atomic operations with balance tracking

---

## 📊 Database Indexes

Optimized queries with indexes on:
- `User.currentLocation.coordinates` (2dsphere) - Location-based queries
- `Ride.origin.coordinates` (2dsphere) - Nearby rides
- `DriverDocument.driverId` + `documentType` - Document lookups
- `Transaction.driverId` + `createdAt` - Transaction history
- `Payout.driverId` + `status` - Payout queries

---

## 🎯 Next Steps for Mobile App (Flutter)

### Screens to Implement:

1. **Driver Registration Screens**
   - Vehicle information form
   - Document upload (camera/gallery)
   - Payment details form
   - Registration status tracker

2. **Driver Dashboard**
   - Online/offline toggle
   - Earnings summary cards
   - Today's stats
   - Quick actions

3. **Ride Management**
   - Available rides list
   - Ride details modal
   - Accept/reject buttons
   - Navigation integration

4. **Earnings Screen**
   - Balance display
   - Earnings breakdown (daily/weekly/monthly)
   - Transaction history list
   - Payout request button

5. **Payout Screen**
   - Payout request form
   - Payment method selection
   - Payout history
   - Status tracking

### Services to Create:

1. **SocketService** - Socket.io client integration
2. **RegistrationService** - API calls for registration
3. **EarningsService** - Earnings and payout APIs
4. **LocationService** - Real-time location tracking
5. **NotificationService** - Push notifications

---

## 📝 API Documentation

Complete API documentation available in: `backend/API_DOCUMENTATION.md`

Includes:
- All endpoint specifications
- Request/response examples
- Socket.io event documentation
- Error handling
- Authentication requirements

---

## 🐛 Troubleshooting

### Socket.io Connection Issues
```javascript
// Check if token is valid
socket.on('connect_error', (error) => {
  console.error('Connection error:', error.message);
});
```

### Commission Not Calculating
- Ensure ride is completed before processing earnings
- Check driver's `commissionRate` field
- Verify ride hasn't been processed already

### Payout Request Fails
- Check minimum payout amount (100 ETB)
- Verify available balance (balance - pending payouts)
- Ensure payment details are provided

---

## 📈 Performance Considerations

1. **Geospatial Queries**: Uses MongoDB 2dsphere indexes for fast location searches
2. **Pagination**: All list endpoints support pagination
3. **Socket Rooms**: Drivers and riders in separate rooms for efficient broadcasting
4. **Scheduled Tasks**: Cron jobs run at off-peak hours
5. **Transaction Atomicity**: Balance updates are atomic to prevent race conditions

---

## 🤝 Contributing

When extending this implementation:

1. Follow existing code structure
2. Add appropriate error handling
3. Update API documentation
4. Test real-time features thoroughly
5. Consider transaction integrity for financial operations

---

## 📞 Support

For questions or issues with this implementation, refer to:
- API Documentation: `backend/API_DOCUMENTATION.md`
- Socket Events: See socketService.js
- Database Models: Check models/ directory

---

## ✅ Implementation Checklist

- [x] Driver registration with document upload
- [x] Admin approval workflow
- [x] Real-time ride notifications (Socket.io)
- [x] Commission-based earnings calculation
- [x] Transaction history tracking
- [x] Payout request system
- [x] Admin payout processing
- [x] Scheduled earnings reset
- [x] Location-based ride matching
- [x] Real-time status updates
- [x] Balance management
- [x] API documentation

---

## 🎉 Summary

This implementation provides a complete driver functionality system with:

- **Professional onboarding** with document verification
- **Real-time communication** for instant ride matching
- **Transparent earnings** with commission tracking
- **Flexible payouts** supporting multiple payment methods
- **Admin controls** for verification and payout processing
- **Scalable architecture** ready for production use

The system is production-ready and follows best practices for security, performance, and maintainability.
