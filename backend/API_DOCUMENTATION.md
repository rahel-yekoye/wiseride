# WiseRide API Documentation

## Driver Functionality Implementation

### Base URL
```
http://localhost:4000/api
```

---

## 1. Driver Registration APIs

### Start Driver Registration
**POST** `/registration/start`

Start the driver registration process by providing vehicle and payment information.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
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
    "bankName": "Commercial Bank of Ethiopia",
    "accountNumber": "1234567890",
    "accountHolderName": "John Doe",
    "swiftCode": "CBETETAA"
  },
  "mobileMoneyDetails": {
    "provider": "M-Pesa",
    "phoneNumber": "+251911234567",
    "accountName": "John Doe"
  },
  "serviceAreas": ["Bole", "Piassa", "Merkato"],
  "availabilitySchedule": {
    "monday": { "start": "08:00", "end": "18:00", "available": true },
    "tuesday": { "start": "08:00", "end": "18:00", "available": true }
  }
}
```

**Response:**
```json
{
  "message": "Driver registration started successfully",
  "user": { ... }
}
```

---

### Upload Driver Document
**POST** `/registration/documents`

Upload required documents for driver verification.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "documentType": "license",
  "documentUrl": "https://storage.example.com/documents/license.jpg",
  "documentNumber": "DL123456",
  "expiryDate": "2025-12-31",
  "metadata": {
    "fileSize": 1024000,
    "mimeType": "image/jpeg",
    "originalName": "drivers_license.jpg"
  }
}
```

**Document Types:**
- `license` - Driver's license
- `vehicle_registration` - Vehicle registration
- `insurance` - Vehicle insurance
- `id_card` - National ID card
- `profile_photo` - Driver profile photo

**Response:**
```json
{
  "message": "Document uploaded successfully",
  "document": { ... }
}
```

---

### Get Driver Documents
**GET** `/registration/documents`

Retrieve all uploaded documents for the driver.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
[
  {
    "_id": "...",
    "documentType": "license",
    "documentUrl": "...",
    "verificationStatus": "pending",
    "createdAt": "..."
  }
]
```

---

### Submit Registration for Review
**POST** `/registration/submit`

Submit the completed registration for admin review.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "message": "Registration submitted for review successfully",
  "user": { ... }
}
```

---

### Get Registration Status
**GET** `/registration/status`

Check the current status of driver registration.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "status": "under_review",
  "approvalDate": null,
  "rejectionReason": null,
  "vehicleInfo": { ... },
  "documents": [ ... ],
  "requiredDocuments": ["license", "vehicle_registration", "insurance", "id_card"],
  "completionPercentage": 100
}
```

---

### Admin: Review Registration
**PUT** `/registration/:driverId/review`

Approve or reject a driver registration (Admin only).

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Request Body:**
```json
{
  "action": "approve",
  "reason": "All documents verified"
}
```

**Actions:**
- `approve` - Approve the registration
- `reject` - Reject the registration

---

### Admin: Get Pending Registrations
**GET** `/registration/pending`

Get all pending driver registrations (Admin only).

**Headers:**
```
Authorization: Bearer <admin_token>
```

---

## 2. Earnings & Payment APIs

### Process Ride Earnings
**POST** `/earnings/process`

Process earnings from a completed ride with commission calculation.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "rideId": "ride_id_here",
  "totalFare": 150.00
}
```

**Response:**
```json
{
  "message": "Earnings processed successfully",
  "fareBreakdown": {
    "totalFare": 150.00,
    "commissionRate": 0.15,
    "commissionAmount": 22.50,
    "netAmount": 127.50
  },
  "transaction": { ... },
  "newBalance": 1127.50
}
```

---

### Get Earnings Summary
**GET** `/earnings/summary`

Get comprehensive earnings summary for the driver.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "balance": 1127.50,
  "earnings": {
    "total": 5000.00,
    "today": 250.00,
    "thisWeek": 1200.00,
    "thisMonth": 3500.00
  },
  "completedRides": 45,
  "totalCommission": 750.00,
  "pendingPayoutAmount": 0,
  "availableForPayout": 1127.50,
  "commissionRate": 0.15
}
```

---

### Get Transaction History
**GET** `/earnings/transactions`

Get paginated transaction history with filters.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20)
- `type` - Transaction type filter
- `startDate` - Start date filter
- `endDate` - End date filter

**Transaction Types:**
- `ride_earning` - Earnings from ride
- `commission` - Commission deducted
- `payout` - Payout withdrawal
- `bonus` - Bonus payment
- `penalty` - Penalty deduction
- `refund` - Refund

**Response:**
```json
{
  "transactions": [ ... ],
  "totalPages": 5,
  "currentPage": 1,
  "totalTransactions": 100
}
```

---

### Request Payout
**POST** `/earnings/payout/request`

Request a payout withdrawal.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "amount": 1000.00,
  "paymentMethod": "bank_transfer",
  "bankDetails": {
    "bankName": "Commercial Bank of Ethiopia",
    "accountNumber": "1234567890",
    "accountHolderName": "John Doe"
  }
}
```

**Payment Methods:**
- `bank_transfer` - Bank transfer
- `mobile_money` - Mobile money (M-Pesa, HelloCash)
- `cash` - Cash pickup

**Response:**
```json
{
  "message": "Payout request submitted successfully",
  "payout": {
    "_id": "...",
    "amount": 1000.00,
    "status": "pending",
    "referenceNumber": "PAY-1234567890-ABC123"
  }
}
```

---

### Get Payout History
**GET** `/earnings/payout/history`

Get paginated payout history.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `page` - Page number
- `limit` - Items per page
- `status` - Status filter

**Payout Statuses:**
- `pending` - Awaiting processing
- `processing` - Being processed
- `completed` - Successfully completed
- `failed` - Failed
- `cancelled` - Cancelled

---

### Admin: Process Payout
**PUT** `/earnings/payout/:payoutId/process`

Process a payout request (Admin only).

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Request Body:**
```json
{
  "action": "complete",
  "referenceNumber": "TXN123456789",
  "failureReason": ""
}
```

**Actions:**
- `approve` - Approve and start processing
- `complete` - Mark as completed
- `reject` - Reject the payout

---

### Admin: Get Pending Payouts
**GET** `/earnings/payout/pending`

Get all pending payout requests (Admin only).

**Headers:**
```
Authorization: Bearer <admin_token>
```

---

## 3. Real-time Notifications (Socket.io)

### Connection
```javascript
const socket = io('http://localhost:4000', {
  auth: {
    token: 'your_jwt_token'
  }
});
```

### Driver Events

#### Listen for New Ride Requests
```javascript
socket.on('ride:new_request', (data) => {
  console.log('New ride request:', data);
  // data: { rideId, riderId, origin, destination, vehicleType, type }
});
```

#### Notify Location Update
```javascript
socket.emit('driver:location:update', {
  location: { lat: 9.0320, lng: 38.7469 },
  riderId: 'rider_id_here',
  eta: '5 minutes'
});
```

#### Update Online Status
```javascript
socket.emit('driver:status:update', {
  isOnline: true
});
```

#### Accept Ride
```javascript
socket.emit('ride:accept', {
  rideId: 'ride_id',
  riderId: 'rider_id',
  driverInfo: { name: '...', phone: '...', vehicleInfo: {...} },
  estimatedArrival: new Date()
});
```

#### Start Ride
```javascript
socket.emit('ride:start', {
  rideId: 'ride_id',
  riderId: 'rider_id',
  startTime: new Date()
});
```

#### Complete Ride
```javascript
socket.emit('ride:complete', {
  rideId: 'ride_id',
  riderId: 'rider_id',
  fare: 150.00,
  endTime: new Date()
});
```

#### Cancel Ride
```javascript
socket.emit('ride:cancel', {
  rideId: 'ride_id',
  riderId: 'rider_id',
  reason: 'Emergency'
});
```

### Rider Events

#### Listen for Ride Accepted
```javascript
socket.on('ride:accepted', (data) => {
  console.log('Driver accepted ride:', data);
  // data: { rideId, driverId, driverInfo, estimatedArrival }
});
```

#### Listen for Ride Started
```javascript
socket.on('ride:started', (data) => {
  console.log('Ride started:', data);
  // data: { rideId, startTime }
});
```

#### Listen for Ride Completed
```javascript
socket.on('ride:completed', (data) => {
  console.log('Ride completed:', data);
  // data: { rideId, fare, endTime }
});
```

#### Listen for Driver Location Updates
```javascript
socket.on('driver:location:updated', (data) => {
  console.log('Driver location:', data);
  // data: { driverId, location, eta }
});
```

---

## 4. Existing Driver APIs

### Update Driver Location
**PUT** `/driver/location`

**Request Body:**
```json
{
  "lat": 9.0320,
  "lng": 38.7469,
  "address": "Bole, Addis Ababa"
}
```

---

### Toggle Online Status
**PUT** `/driver/toggle-online`

Toggle driver online/offline status.

---

### Get Nearby Rides
**GET** `/driver/rides/nearby?lat=9.0320&lng=38.7469&radius=10`

Get available rides near driver's location.

---

### Accept Ride
**PUT** `/driver/rides/:rideId/accept`

Accept a ride request.

---

### Start Ride
**PUT** `/driver/rides/:rideId/start`

Start an accepted ride.

---

### Complete Ride
**PUT** `/driver/rides/:rideId/complete`

Complete a ride.

**Request Body:**
```json
{
  "fare": 150.00
}
```

---

### Get Driver Dashboard
**GET** `/driver/dashboard`

Get comprehensive driver dashboard data.

---

## Error Responses

All endpoints may return the following error responses:

**400 Bad Request**
```json
{
  "message": "Error description"
}
```

**401 Unauthorized**
```json
{
  "message": "Not authorized"
}
```

**404 Not Found**
```json
{
  "message": "Resource not found"
}
```

**500 Internal Server Error**
```json
{
  "message": "Something went wrong!"
}
```

---

## Scheduled Tasks

The system automatically runs the following scheduled tasks:

- **Daily Earnings Reset**: Midnight every day (resets `earnings.today`)
- **Weekly Earnings Reset**: Monday midnight (resets `earnings.thisWeek`)
- **Monthly Earnings Reset**: 1st of each month (resets `earnings.thisMonth`)

---

## Commission Structure

Default commission rate: **15%**

Example calculation for a 150 ETB ride:
- Total Fare: 150.00 ETB
- Commission (15%): 22.50 ETB
- Driver Net Earnings: 127.50 ETB

Commission rates can be customized per driver by admin.
