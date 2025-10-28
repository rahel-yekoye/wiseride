# WiseRide - Quick Reference Guide

## ✅ What's Working RIGHT NOW

### 1. **Promo Codes** 🎟️
- Tap purple button on dashboard
- Enter code or generate referral
- **Smart discounts:**
  - Bus (20 ETB): 20% = 4 ETB off
  - Taxi (150 ETB): 50 ETB off

### 2. **Ride History** 📊
- Tap orange button on dashboard
- See all past rides
- Filter by status
- View monthly stats

---

## 🔧 Quick Integration (5 min each)

### Add Rating Screen:
```dart
// After ride completion:
import '../screens/rating_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => RatingScreen(
      rideId: rideId,
      driverName: driverName,
    ),
  ),
);
```

### Add SOS Button:
```dart
// In active ride screen:
import '../widgets/sos_button.dart';

floatingActionButton: SOSButton(
  rideId: currentRideId,
  currentLat: latitude,
  currentLng: longitude,
  currentAddress: address,
),
```

---

## 📊 Smart Pricing

| Vehicle | Base | Multiplier | Example Fare |
|---------|------|------------|--------------|
| Bus | 15 ETB | 0.5x | 15-30 ETB |
| Minibus | 30 ETB | 0.8x | 30-60 ETB |
| Taxi | 50 ETB | 1.0x | 50-200 ETB |
| Private | 60 ETB | 1.2x | 60-250 ETB |

**Surge Pricing:**
- Peak hours (7-9 AM, 5-7 PM): 1.5x
- Night (10 PM-5 AM): 1.3x
- Weekends: 1.1x

---

## 🎟️ Create Promo Codes

### Percentage (For Buses):
```bash
POST /api/promo/create
{
  "code": "BUS20",
  "type": "percentage",
  "value": 20,
  "maxDiscountAmount": 10,
  "applicableVehicleTypes": ["bus"]
}
```

### Fixed Amount (For Taxis):
```bash
POST /api/promo/create
{
  "code": "TAXI50",
  "type": "fixed_amount",
  "value": 50,
  "minRideAmount": 100,
  "applicableVehicleTypes": ["taxi"]
}
```

---

## 📱 All API Endpoints

### Promo Codes:
- `POST /api/promo/validate` - Check code
- `POST /api/promo/referral` - Generate code
- `POST /api/promo/create` - Create (Admin)

### Ride History:
- `GET /api/ride-history` - Get rides
- `GET /api/ride-history/stats` - Statistics

### Ratings:
- `POST /api/ratings/:rideId` - Submit rating

### Emergency:
- `POST /api/emergency/alert` - Send SOS

### Fare:
- `POST /api/rides/estimate` - Calculate fare

---

## 🎯 Files You Need

### Mobile:
```
lib/screens/
  ├── promo_code_screen.dart ✅ Working
  ├── ride_history_screen.dart ✅ Working
  └── rating_screen.dart ✅ Ready

lib/widgets/
  └── sos_button.dart ✅ Ready
```

### Backend:
```
backend/
  ├── models/
  │   ├── PromoCode.js ✅
  │   ├── Rating.js ✅
  │   └── EmergencyAlert.js ✅
  ├── controllers/
  │   ├── promoCodeController.js ✅
  │   ├── ratingController.js ✅
  │   └── rideHistoryController.js ✅
  └── services/
      └── fareCalculationService.js ✅
```

---

## 🚀 Test Checklist

- [ ] Run app: `flutter run`
- [ ] Tap "Promo Codes" - Should open screen
- [ ] Tap "Ride History" - Should open screen
- [ ] Generate referral code - Should work
- [ ] Validate promo code - Should work
- [ ] View past rides - Should load
- [ ] Filter rides - Should filter

---

## 💡 Quick Tips

### Best Promo Codes:
- **Buses**: 15-20% (max 10 ETB)
- **Minibuses**: 10-15% (max 15 ETB)
- **Taxis**: 50 ETB fixed (min 100 ETB ride)
- **Universal**: 10% (max 30 ETB)

### When to Show Rating:
- After ride status = "completed"
- Before returning to dashboard
- Allow skip option

### When to Show SOS:
- During active ride
- As floating action button
- Always visible and accessible

---

## 🎉 You're Done!

**Everything is ready to use!**

Just add Rating & SOS to your ride screens and you're 100% complete! 🚀
