# Smart Promo Code System for WiseRide

## 🎯 Problem Solved

For **buses** and **minibuses** with low fares (15-30 ETB), a fixed 50 ETB discount doesn't make sense.  
**Solution:** Use percentage-based discounts that adapt to the ride fare!

---

## 💡 Smart Promo Code Examples

### For Buses (Low Fare: 15-30 ETB):
```javascript
{
  code: "BUS20",
  description: "20% off bus rides",
  type: "percentage",
  value: 20,  // 20% discount
  maxDiscountAmount: 10,  // Max 10 ETB off
  applicableVehicleTypes: ["bus"],
  minRideAmount: 10
}

// Example: 20 ETB bus ride
// Discount: 20% of 20 = 4 ETB
// Final: 16 ETB ✅
```

### For Minibuses (Medium Fare: 30-50 ETB):
```javascript
{
  code: "MINIBUS15",
  description: "15% off minibus rides",
  type: "percentage",
  value: 15,  // 15% discount
  maxDiscountAmount: 15,  // Max 15 ETB off
  applicableVehicleTypes: ["minibus"],
  minRideAmount: 20
}

// Example: 40 ETB minibus ride
// Discount: 15% of 40 = 6 ETB
// Final: 34 ETB ✅
```

### For Taxis (Higher Fare: 50-200 ETB):
```javascript
{
  code: "TAXI50",
  description: "50 ETB off taxi rides",
  type: "fixed_amount",
  value: 50,  // Fixed 50 ETB
  applicableVehicleTypes: ["taxi", "private_car"],
  minRideAmount: 100
}

// Example: 150 ETB taxi ride
// Discount: 50 ETB
// Final: 100 ETB ✅
```

### Universal Discount (All Vehicles):
```javascript
{
  code: "RIDE10",
  description: "10% off any ride",
  type: "percentage",
  value: 10,  // 10% discount
  maxDiscountAmount: 30,  // Max 30 ETB off
  applicableVehicleTypes: [],  // All vehicles
  minRideAmount: 0
}

// Bus (20 ETB): 10% = 2 ETB off → 18 ETB ✅
// Taxi (150 ETB): 10% = 15 ETB off → 135 ETB ✅
// Private (200 ETB): 10% = 20 ETB off → 180 ETB ✅
```

---

## 📊 Fare Structure by Vehicle Type

| Vehicle | Base Fare | Multiplier | Typical Fare Range |
|---------|-----------|------------|-------------------|
| Bus | 15 ETB | 0.5x | 15-30 ETB |
| Minibus | 30 ETB | 0.8x | 30-60 ETB |
| Taxi | 50 ETB | 1.0x | 50-200 ETB |
| Private Car | 60 ETB | 1.2x | 60-250 ETB |

---

## 🎟️ Recommended Promo Codes for WiseRide

### 1. First Ride Discount (All Users)
```javascript
{
  code: "FIRST20",
  description: "20% off your first ride",
  type: "percentage",
  value: 20,
  maxDiscountAmount: 50,
  maxUsagePerUser: 1,
  applicableUserTypes: ["new_user"]
}
```

### 2. Bus Special (Public Transport)
```javascript
{
  code: "BUSRIDE",
  description: "15% off bus rides",
  type: "percentage",
  value: 15,
  maxDiscountAmount: 8,
  applicableVehicleTypes: ["bus"]
}
```

### 3. Weekend Deal (All Vehicles)
```javascript
{
  code: "WEEKEND10",
  description: "10% off weekend rides",
  type: "percentage",
  value: 10,
  maxDiscountAmount: 25,
  // Only valid on weekends (implement in controller)
}
```

### 4. Student Discount (Minibus/Bus)
```javascript
{
  code: "STUDENT25",
  description: "25% off for students",
  type: "percentage",
  value: 25,
  maxDiscountAmount: 20,
  applicableVehicleTypes: ["bus", "minibus"]
}
```

### 5. Referral Reward
```javascript
{
  code: "REFJOHN123",
  description: "Referral from John",
  type: "percentage",
  value: 20,
  maxDiscountAmount: 50,
  isReferralCode: true,
  referralReward: {
    referrer: 50,  // Referrer gets 50 ETB
    referee: 50    // New user gets 50 ETB (or 20% off)
  }
}
```

---

## 🧮 How Discount Calculation Works

### Percentage Discount:
```javascript
discount = (rideAmount * percentage) / 100
if (discount > maxDiscountAmount) {
  discount = maxDiscountAmount
}
finalAmount = rideAmount - discount
```

### Fixed Amount Discount:
```javascript
discount = fixedValue
if (discount > rideAmount) {
  discount = rideAmount  // Can't discount more than fare
}
finalAmount = rideAmount - discount
```

### Examples:

**Bus Ride (20 ETB) with 20% discount:**
- Discount: 20 * 0.20 = 4 ETB
- Final: 16 ETB ✅

**Taxi Ride (150 ETB) with 50 ETB discount:**
- Discount: 50 ETB
- Final: 100 ETB ✅

**Minibus (40 ETB) with 15% discount (max 15 ETB):**
- Discount: 40 * 0.15 = 6 ETB (under max)
- Final: 34 ETB ✅

---

## 🎯 Best Practices

### 1. Use Percentage for Low-Fare Vehicles:
```javascript
// ✅ Good for buses
{ type: "percentage", value: 20, maxDiscountAmount: 10 }

// ❌ Bad for buses
{ type: "fixed_amount", value: 50 }  // More than the fare!
```

### 2. Use Fixed Amount for High-Fare Vehicles:
```javascript
// ✅ Good for taxis
{ type: "fixed_amount", value: 50, minRideAmount: 100 }

// ✅ Also good
{ type: "percentage", value: 20, maxDiscountAmount: 50 }
```

### 3. Always Set Max Discount:
```javascript
// ✅ Prevents abuse
{ type: "percentage", value: 50, maxDiscountAmount: 100 }

// ❌ Could give huge discounts
{ type: "percentage", value: 50, maxDiscountAmount: null }
```

### 4. Set Minimum Ride Amount:
```javascript
// ✅ Prevents misuse on very short rides
{ type: "fixed_amount", value: 50, minRideAmount: 100 }
```

---

## 📱 How It Works in the App

### User Flow:
1. User enters promo code "BUS20"
2. App validates code with backend
3. Backend checks:
   - Is code valid and active?
   - Is vehicle type eligible?
   - Has user used it before?
   - Is ride amount above minimum?
4. Backend calculates discount:
   - Bus ride: 20 ETB
   - Discount: 20% = 4 ETB
   - Final: 16 ETB
5. App shows: "✅ 4 ETB discount applied!"

---

## 🚀 Create Smart Promo Codes via API

### Create Percentage Discount:
```bash
POST /api/promo/create
{
  "code": "BUS20",
  "description": "20% off bus rides",
  "type": "percentage",
  "value": 20,
  "maxDiscountAmount": 10,
  "maxUsagePerUser": 5,
  "validFrom": "2025-01-01",
  "validUntil": "2025-12-31",
  "applicableVehicleTypes": ["bus"],
  "minRideAmount": 10,
  "isActive": true
}
```

### Create Fixed Discount:
```bash
POST /api/promo/create
{
  "code": "TAXI50",
  "description": "50 ETB off taxi rides",
  "type": "fixed_amount",
  "value": 50,
  "maxUsagePerUser": 1,
  "validFrom": "2025-01-01",
  "validUntil": "2025-12-31",
  "applicableVehicleTypes": ["taxi", "private_car"],
  "minRideAmount": 100,
  "isActive": true
}
```

---

## ✅ Summary

Your promo code system is **already smart**! It:

✅ Supports percentage discounts (perfect for buses)  
✅ Supports fixed amount discounts (perfect for taxis)  
✅ Has max discount limits (prevents abuse)  
✅ Has minimum ride amounts (prevents misuse)  
✅ Vehicle-specific codes (target different users)  
✅ Usage limits (control costs)  
✅ Referral system (viral growth)  

**The system automatically adapts to ride fares!** 🎉
