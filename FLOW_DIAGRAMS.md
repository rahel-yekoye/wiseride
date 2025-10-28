# WiseRide Driver Functionality - Flow Diagrams

## 1. Driver Registration Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    DRIVER REGISTRATION FLOW                  │
└─────────────────────────────────────────────────────────────┘

Step 1: User Registration
┌──────────┐
│  Driver  │──► POST /api/users/register
└──────────┘    { role: "driver", name, email, password }
                        │
                        ▼
                ┌───────────────┐
                │ User Created  │
                │ Status: rider │
                └───────────────┘

Step 2: Start Registration
┌──────────┐
│  Driver  │──► POST /api/registration/start
└──────────┘    { vehicleInfo, bankDetails, serviceAreas }
                        │
                        ▼
                ┌─────────────────────┐
                │ Status: pending     │
                │ Vehicle info saved  │
                └─────────────────────┘

Step 3: Upload Documents (Repeat 4 times)
┌──────────┐
│  Driver  │──► POST /api/registration/documents
└──────────┘    { documentType: "license", documentUrl, ... }
                        │
                        ▼
                ┌─────────────────────────┐
                │ Document Saved          │
                │ Status: pending         │
                └─────────────────────────┘
                        │
                        ▼ (After all 4 docs)
                ┌─────────────────────────────┐
                │ Status: documents_submitted │
                └─────────────────────────────┘

Step 4: Submit for Review
┌──────────┐
│  Driver  │──► POST /api/registration/submit
└──────────┘            │
                        ▼
                ┌───────────────────┐
                │ Status:           │
                │ under_review      │
                └───────────────────┘

Step 5: Admin Review
┌───────┐
│ Admin │──► PUT /api/registration/:driverId/review
└───────┘    { action: "approve" }
                        │
                ┌───────┴────────┐
                │                │
         ┌──────▼──────┐  ┌─────▼──────┐
         │  APPROVED   │  │  REJECTED  │
         │ verified:   │  │ verified:  │
         │   true      │  │   false    │
         └─────────────┘  └────────────┘
                │
                ▼
        ┌──────────────────┐
        │ Driver can now   │
        │ accept rides     │
        └──────────────────┘
```

---

## 2. Real-time Ride Request Flow

```
┌─────────────────────────────────────────────────────────────┐
│                 REAL-TIME RIDE REQUEST FLOW                  │
└─────────────────────────────────────────────────────────────┘

Step 1: Connections
┌────────┐                    ┌────────┐
│ Driver │◄──Socket.io───────►│ Server │
└────────┘    (JWT Auth)      └────────┘
     │                             │
     │ Join "drivers" room         │
     └─────────────────────────────┘

┌────────┐                    ┌────────┐
│ Rider  │◄──Socket.io───────►│ Server │
└────────┘    (JWT Auth)      └────────┘
     │                             │
     │ Join "riders" room          │
     └─────────────────────────────┘

Step 2: Ride Request
┌────────┐
│ Rider  │──► POST /api/rides
└────────┘    { origin, destination, vehicleType }
                        │
                        ▼
                ┌───────────────┐
                │ Ride Created  │
                │ Status:       │
                │ requested     │
                └───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │ Socket.io Broadcast           │
        │ Event: ride:new_request       │
        │ To: All drivers in room       │
        └───────────────────────────────┘
                        │
                ┌───────┴───────┐
                ▼               ▼
        ┌──────────┐    ┌──────────┐
        │ Driver 1 │    │ Driver 2 │
        │ Notified │    │ Notified │
        └──────────┘    └──────────┘

Step 3: Driver Accepts
┌──────────┐
│ Driver 1 │──► PUT /api/driver/rides/:id/accept
└──────────┘            │
                        ▼
                ┌───────────────┐
                │ Ride Updated  │
                │ Status:       │
                │ accepted      │
                │ driverId: set │
                └───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │ Socket.io Emit                │
        │ Event: ride:accepted          │
        │ To: Specific rider            │
        └───────────────────────────────┘
                        │
                        ▼
                ┌──────────┐
                │  Rider   │
                │ Notified │
                │ (Driver  │
                │  info)   │
                └──────────┘

Step 4: Driver Starts Ride
┌──────────┐
│ Driver 1 │──► PUT /api/driver/rides/:id/start
└──────────┘            │
                        ▼
                ┌───────────────┐
                │ Ride Updated  │
                │ Status:       │
                │ in_progress   │
                └───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │ Socket.io Emit                │
        │ Event: ride:started           │
        │ To: Rider                     │
        └───────────────────────────────┘

Step 5: Location Updates (During Ride)
┌──────────┐
│ Driver 1 │──► socket.emit('driver:location:update')
└──────────┘    { location, riderId, eta }
                        │
                        ▼
        ┌───────────────────────────────┐
        │ Socket.io Emit                │
        │ Event: driver:location:updated│
        │ To: Rider                     │
        └───────────────────────────────┘
                        │
                        ▼
                ┌──────────┐
                │  Rider   │
                │ Sees     │
                │ Driver   │
                │ Location │
                └──────────┘

Step 6: Complete Ride
┌──────────┐
│ Driver 1 │──► PUT /api/driver/rides/:id/complete
└──────────┘    { fare: 150 }
                        │
                        ▼
                ┌───────────────┐
                │ Ride Updated  │
                │ Status:       │
                │ completed     │
                └───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │ Socket.io Emit                │
        │ Event: ride:completed         │
        │ To: Rider                     │
        └───────────────────────────────┘
```

---

## 3. Earnings & Payout Flow

```
┌─────────────────────────────────────────────────────────────┐
│                  EARNINGS & PAYOUT FLOW                      │
└─────────────────────────────────────────────────────────────┘

Step 1: Complete Ride
┌──────────┐
│  Driver  │──► PUT /api/driver/rides/:id/complete
└──────────┘    { fare: 150 }
                        │
                        ▼
                ┌───────────────┐
                │ Ride Status:  │
                │ completed     │
                └───────────────┘

Step 2: Process Earnings
┌──────────┐
│  Driver  │──► POST /api/earnings/process
└──────────┘    { rideId, totalFare: 150 }
                        │
                        ▼
        ┌───────────────────────────────┐
        │ Calculate Commission          │
        │                               │
        │ Total Fare:      150.00 ETB   │
        │ Commission (15%): 22.50 ETB   │
        │ Net Amount:      127.50 ETB   │
        └───────────────────────────────┘
                        │
                ┌───────┴────────┐
                ▼                ▼
    ┌──────────────────┐  ┌──────────────────┐
    │ Transaction 1    │  │ Transaction 2    │
    │ Type: ride_earning│  │ Type: commission │
    │ Amount: +127.50  │  │ Amount: -22.50   │
    │ Status: completed│  │ Status: completed│
    └──────────────────┘  └──────────────────┘
                        │
                        ▼
                ┌───────────────┐
                │ Update Driver │
                │ Balance:      │
                │ +127.50 ETB   │
                │               │
                │ Earnings:     │
                │ today: +127.50│
                │ week: +127.50 │
                │ month: +127.50│
                └───────────────┘

Step 3: Check Earnings
┌──────────┐
│  Driver  │──► GET /api/earnings/summary
└──────────┘            │
                        ▼
        ┌───────────────────────────────┐
        │ Response:                     │
        │ balance: 1127.50              │
        │ earnings: {                   │
        │   total: 5000.00              │
        │   today: 250.00               │
        │   thisWeek: 1200.00           │
        │   thisMonth: 3500.00          │
        │ }                             │
        │ completedRides: 45            │
        │ totalCommission: 750.00       │
        │ availableForPayout: 1127.50   │
        └───────────────────────────────┘

Step 4: Request Payout
┌──────────┐
│  Driver  │──► POST /api/earnings/payout/request
└──────────┘    { amount: 1000, paymentMethod: "bank_transfer" }
                        │
                        ▼
        ┌───────────────────────────────┐
        │ Validate:                     │
        │ ✓ Amount >= 100 ETB           │
        │ ✓ Available balance >= 1000   │
        │ ✓ Payment details provided    │
        └───────────────────────────────┘
                        │
                        ▼
                ┌───────────────┐
                │ Payout Created│
                │ Status:       │
                │ pending       │
                │ Reference:    │
                │ PAY-123-ABC   │
                └───────────────┘

Step 5: Admin Processes Payout
┌───────┐
│ Admin │──► PUT /api/earnings/payout/:id/process
└───────┘    { action: "approve" }
                        │
                        ▼
                ┌───────────────┐
                │ Payout Status:│
                │ processing    │
                └───────────────┘
                        │
                        ▼
┌───────┐
│ Admin │──► PUT /api/earnings/payout/:id/process
└───────┘    { action: "complete", referenceNumber: "TXN123" }
                        │
                        ▼
        ┌───────────────────────────────┐
        │ Create Transaction            │
        │ Type: payout                  │
        │ Amount: -1000                 │
        │ Status: completed             │
        └───────────────────────────────┘
                        │
                        ▼
                ┌───────────────┐
                │ Update Driver │
                │ Balance:      │
                │ -1000 ETB     │
                │               │
                │ New Balance:  │
                │ 127.50 ETB    │
                └───────────────┘
                        │
                        ▼
                ┌───────────────┐
                │ Payout Status:│
                │ completed     │
                │ Reference:    │
                │ TXN123        │
                └───────────────┘
```

---

## 4. Scheduled Tasks Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    SCHEDULED TASKS FLOW                      │
└─────────────────────────────────────────────────────────────┘

Daily Reset (Midnight)
┌──────────────┐
│ Cron Job     │──► 0 0 * * *
│ (Midnight)   │
└──────────────┘
        │
        ▼
┌───────────────────────────────┐
│ resetEarnings('daily')        │
│                               │
│ Update all drivers:           │
│ earnings.today = 0            │
└───────────────────────────────┘

Weekly Reset (Monday Midnight)
┌──────────────┐
│ Cron Job     │──► 0 0 * * 1
│ (Monday)     │
└──────────────┘
        │
        ▼
┌───────────────────────────────┐
│ resetEarnings('weekly')       │
│                               │
│ Update all drivers:           │
│ earnings.thisWeek = 0         │
└───────────────────────────────┘

Monthly Reset (1st of Month)
┌──────────────┐
│ Cron Job     │──► 0 0 1 * *
│ (1st Day)    │
└──────────────┘
        │
        ▼
┌───────────────────────────────┐
│ resetEarnings('monthly')      │
│                               │
│ Update all drivers:           │
│ earnings.thisMonth = 0        │
└───────────────────────────────┘

Note: earnings.total is NEVER reset
```

---

## 5. System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SYSTEM ARCHITECTURE                       │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│                      Mobile App (Flutter)                     │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │   Driver   │  │   Rider    │  │   Admin    │             │
│  │   Screens  │  │   Screens  │  │   Panel    │             │
│  └────────────┘  └────────────┘  └────────────┘             │
└──────────────────────────────────────────────────────────────┘
        │                   │                   │
        │ HTTP/REST         │ HTTP/REST         │ HTTP/REST
        │ Socket.io         │ Socket.io         │
        │                   │                   │
        ▼                   ▼                   ▼
┌──────────────────────────────────────────────────────────────┐
│                    Express.js Server                          │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                    Middleware                          │  │
│  │  • CORS  • Helmet  • Morgan  • JWT Auth               │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                    Routes                              │  │
│  │  /api/users  /api/rides  /api/driver                  │  │
│  │  /api/registration  /api/earnings                     │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                   Controllers                          │  │
│  │  userController  rideController  driverController      │  │
│  │  registrationController  earningsController           │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                    Services                            │  │
│  │  • socketService (Socket.io)                          │  │
│  │  • Cron Jobs (node-cron)                              │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                    MongoDB Database                           │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │   Users    │  │   Rides    │  │   Driver   │             │
│  │            │  │            │  │  Documents │             │
│  └────────────┘  └────────────┘  └────────────┘             │
│                                                               │
│  ┌────────────┐  ┌────────────┐                              │
│  │Transaction │  │  Payouts   │                              │
│  │            │  │            │                              │
│  └────────────┘  └────────────┘                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 6. Data Flow Example: Complete Ride Journey

```
┌─────────────────────────────────────────────────────────────┐
│              COMPLETE RIDE JOURNEY DATA FLOW                 │
└─────────────────────────────────────────────────────────────┘

1. Rider creates ride
   POST /api/rides
   ↓
   Ride document created (status: requested)
   ↓
   Socket.io broadcasts to all drivers
   ↓
   
2. Driver accepts ride
   PUT /api/driver/rides/:id/accept
   ↓
   Ride updated (status: accepted, driverId set)
   ↓
   Socket.io notifies rider
   ↓
   
3. Driver starts ride
   PUT /api/driver/rides/:id/start
   ↓
   Ride updated (status: in_progress, startTime set)
   ↓
   Socket.io notifies rider
   ↓
   
4. Driver sends location updates
   socket.emit('driver:location:update')
   ↓
   Socket.io forwards to rider
   ↓
   
5. Driver completes ride
   PUT /api/driver/rides/:id/complete { fare: 150 }
   ↓
   Ride updated (status: completed, endTime set, fare set)
   ↓
   Socket.io notifies rider
   ↓
   
6. Process earnings
   POST /api/earnings/process { rideId, totalFare: 150 }
   ↓
   Calculate commission (15% = 22.50)
   ↓
   Create Transaction 1 (ride_earning: +127.50)
   Create Transaction 2 (commission: -22.50)
   ↓
   Update driver balance (+127.50)
   Update driver earnings (today, week, month)
   ↓
   
7. Driver requests payout
   POST /api/earnings/payout/request { amount: 1000 }
   ↓
   Validate balance
   Create Payout document (status: pending)
   ↓
   
8. Admin processes payout
   PUT /api/earnings/payout/:id/process { action: "complete" }
   ↓
   Create Transaction (payout: -1000)
   Update driver balance (-1000)
   Update Payout (status: completed)
```

---

## Legend

```
┌─────┐
│ Box │  = Process or Entity
└─────┘

  │
  ▼     = Data Flow Direction

──►     = Action or Request

◄──►    = Bidirectional Communication

┌───┴───┐
│   │   │ = Decision or Branch
▼   ▼   ▼
```

---

## Notes

- All HTTP requests require JWT authentication (except registration/login)
- Socket.io connections also require JWT authentication
- Real-time events are asynchronous and non-blocking
- Database operations are atomic for financial transactions
- Scheduled tasks run independently of user requests
