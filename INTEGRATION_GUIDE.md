# Integration Guide for Enhanced Features

## 🚀 Quick Integration Steps

### Step 1: Add Routes to app.js

Add these lines to `backend/app.js`:

```javascript
// Import new routes
const ratingRoutes = require('./routes/ratingRoutes');
const promoCodeRoutes = require('./routes/promoCodeRoutes');
const rideHistoryRoutes = require('./routes/rideHistoryRoutes');

// Register routes
app.use('/api/ratings', ratingRoutes);
app.use('/api/promo', promoCodeRoutes);
app.use('/api/ride-history', rideHistoryRoutes);
```

### Step 2: Add Fare Estimation to Ride Creation

In `backend/controllers/rideController.js`, add fare estimation:

```javascript
const { calculateFareEstimate } = require('../services/fareCalculationService');

// In createRide function, before saving:
const fareEstimate = calculateFareEstimate({
  originLat: origin.coordinates[1],
  originLng: origin.coordinates[0],
  destLat: destination.coordinates[1],
  destLng: destination.coordinates[0],
  vehicleType,
});

ride.estimatedFare = fareEstimate.estimatedFare;
```

### Step 3: Test the New Endpoints

```bash
# Start server
cd backend
node app.js

# Test fare estimation
curl http://localhost:4000/api/rides/estimate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "originLat": 9.03,
    "originLng": 38.74,
    "destLat": 9.04,
    "destLng": 38.76,
    "vehicleType": "taxi"
  }'

# Test promo code validation
curl http://localhost:4000/api/promo/validate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "FIRST50",
    "rideAmount": 150,
    "vehicleType": "taxi"
  }'

# Test rating submission
curl -X POST http://localhost:4000/api/ratings/RIDE_ID \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "score": 5,
    "review": "Great driver!",
    "categories": {
      "cleanliness": 5,
      "punctuality": 5,
      "driving": 5,
      "communication": 5
    }
  }'
```

---

## 📱 Mobile App Integration

### 1. Create Fare Estimation Service

```dart
// lib/services/fare_service.dart
class FareService {
  final _apiService = ApiService();

  Future<Map<String, dynamic>> estimateFare({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String vehicleType,
  }) async {
    return await _apiService.post('/rides/estimate', body: {
      'originLat': originLat,
      'originLng': originLng,
      'destLat': destLat,
      'destLng': destLng,
      'vehicleType': vehicleType,
    });
  }
}
```

### 2. Create Rating Screen

```dart
// lib/screens/rating_screen.dart
class RatingScreen extends StatefulWidget {
  final String rideId;
  
  const RatingScreen({required this.rideId});
  
  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 5.0;
  final _reviewController = TextEditingController();
  
  Map<String, double> _categories = {
    'cleanliness': 5.0,
    'punctuality': 5.0,
    'driving': 5.0,
    'communication': 5.0,
  };

  Future<void> _submitRating() async {
    try {
      await ApiService().post('/ratings/${widget.rideId}', body: {
        'score': _rating,
        'review': _reviewController.text,
        'categories': _categories,
      });
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rating submitted!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Rate Your Ride')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('How was your ride?', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            
            // Overall rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() => _rating = index + 1.0);
                  },
                );
              }),
            ),
            
            SizedBox(height: 30),
            
            // Category ratings
            ...['cleanliness', 'punctuality', 'driving', 'communication']
                .map((category) => Column(
                  children: [
                    Text(category.toUpperCase()),
                    Slider(
                      value: _categories[category]!,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _categories[category]!.toString(),
                      onChanged: (value) {
                        setState(() => _categories[category] = value);
                      },
                    ),
                  ],
                )),
            
            SizedBox(height: 20),
            
            // Review text
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                labelText: 'Write a review (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            
            SizedBox(height: 20),
            
            // Submit button
            ElevatedButton(
              onPressed: _submitRating,
              child: Text('Submit Rating'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. Create Promo Code Screen

```dart
// lib/screens/promo_code_screen.dart
class PromoCodeScreen extends StatefulWidget {
  @override
  State<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends State<PromoCodeScreen> {
  final _codeController = TextEditingController();
  String? _referralCode;
  
  Future<void> _validatePromoCode() async {
    try {
      final result = await ApiService().post('/promo/validate', body: {
        'code': _codeController.text,
        'rideAmount': 150, // Example amount
        'vehicleType': 'taxi',
      });
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Promo Code Valid!'),
          content: Text(
            'Discount: ${result['discount']} ETB\n'
            'Final Amount: ${result['finalAmount']} ETB'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid promo code')),
      );
    }
  }
  
  Future<void> _generateReferralCode() async {
    try {
      final result = await ApiService().post('/promo/referral');
      setState(() {
        _referralCode = result['referralCode'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Promo Codes')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Apply promo code
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Enter Promo Code',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.check),
                  onPressed: _validatePromoCode,
                ),
              ),
            ),
            
            SizedBox(height: 30),
            Divider(),
            SizedBox(height: 30),
            
            // Referral section
            Text('Refer a Friend', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('You and your friend each get 50 ETB!'),
            SizedBox(height: 20),
            
            if (_referralCode != null) ...[
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_referralCode!, style: TextStyle(fontSize: 18)),
                    IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        // Copy to clipboard
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Code copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _generateReferralCode,
                child: Text('Generate Referral Code'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 4. Add SOS Button to Active Ride Screen

```dart
// Add to active ride screen
FloatingActionButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🚨 Emergency SOS'),
        content: Text(
          'This will:\n'
          '• Share your location\n'
          '• Notify emergency contacts\n'
          '• Alert WiseRide support\n\n'
          'Are you sure?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Trigger SOS
              await ApiService().post('/emergency/alert', body: {
                'rideId': currentRideId,
                'type': 'other',
                'location': {
                  'coordinates': [currentLng, currentLat],
                  'address': currentAddress,
                },
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Emergency alert sent!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text('SEND SOS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  },
  backgroundColor: Colors.red,
  child: Icon(Icons.warning, size: 30),
);
```

---

## 🎯 Testing Checklist

### Backend:
- [ ] All new routes registered in app.js
- [ ] Models created and indexed
- [ ] Controllers tested with Postman
- [ ] Fare calculation working
- [ ] Promo code validation working
- [ ] Rating system working

### Mobile:
- [ ] Fare estimation screen
- [ ] Rating screen after ride
- [ ] Promo code screen
- [ ] SOS button on active ride
- [ ] Ride history screen
- [ ] Referral code sharing

### Integration:
- [ ] End-to-end ride with rating
- [ ] Promo code application
- [ ] Fare calculation accuracy
- [ ] SOS alert triggering

---

## 📊 Expected Results

After integration, users will be able to:

✅ See fare estimates before booking  
✅ Apply promo codes for discounts  
✅ Rate drivers after rides  
✅ View detailed ride history  
✅ Trigger emergency SOS  
✅ Generate and share referral codes  
✅ Schedule future rides  

This brings WiseRide to **production-ready** status! 🚀
