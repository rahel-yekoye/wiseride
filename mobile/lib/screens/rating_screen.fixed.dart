import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';

class RatingScreen extends StatefulWidget {
  final Ride ride;
  final bool isDriver;
  final String? driverName;
  final String? driverPhoto;

  const RatingScreen({
    super.key,
    required this.ride,
    this.isDriver = false,
    this.driverName,
    this.driverPhoto,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _rating = 0.0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;
  
  final Map<String, double> _categoryRatings = {
    'cleanliness': 5.0,
    'punctuality': 5.0,
    'driving': 5.0,
    'communication': 5.0,
  };

  final Map<String, IconData> _categoryIcons = {
    'cleanliness': Icons.cleaning_services,
    'punctuality': Icons.access_time,
    'driving': Icons.drive_eta,
    'communication': Icons.chat_bubble,
  };

  final Map<String, String> _categoryLabels = {
    'cleanliness': 'Cleanliness',
    'punctuality': 'Punctuality',
    'driving': 'Driving',
    'communication': 'Communication',
  };

  final RideService _rideService = RideService();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      setState(() => _error = 'Please select a rating');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _rideService.submitRating(
        rideId: widget.ride.id!,
        rating: _rating,
        review: _reviewController.text.isNotEmpty ? _reviewController.text : null,
        categoryRatings: _categoryRatings,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _error = 'Failed to submit rating. Please try again.');
      debugPrint('Error submitting rating: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDriver ? 'Rate Rider' : 'Rate Driver'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // User Info
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: widget.driverPhoto != null
                  ? NetworkImage(widget.driverPhoto!)
                  : null,
              child: widget.driverPhoto == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.driverName ?? (widget.isDriver ? 'Rider' : 'Driver'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Overall Rating
            const Text(
              'How was your ride?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                  _error = null;
                });
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 32),

            // Category Ratings
            const Text(
              'Rate your experience in each category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._categoryRatings.keys.map((category) => _buildCategoryRating(category)),
            const SizedBox(height: 24),

            // Review
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                labelText: 'Add a review (optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Rating',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRating(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(_categoryIcons[category], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(_categoryLabels[category] ?? category),
          ),
          RatingBar.builder(
            initialRating: _categoryRatings[category] ?? 5.0,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemSize: 24,
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) {
              setState(() {
                _categoryRatings[category] = rating;
              });
            },
          ),
        ],
      ),
    );
  }

  String _getVehicleTypeLabel(String? vehicleType) {
    switch (vehicleType) {
      case 'bus':
        return 'Bus';
      case 'taxi':
        return 'Taxi';
      case 'minibus':
        return 'Minibus';
      case 'private_car':
        return 'Private Car';
      default:
        return 'Vehicle';
    }
  }
}
