import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';
import '../services/api_service.dart';

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

  Future<void> _submitRating() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      await ApiService().post('/ratings/${widget.rideId}', body: {
        'score': _overallRating,
        'review': _reviewController.text.trim(),
        'categories': _categoryRatings,
      });
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Close screen after short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
=======
  final RideService _rideService = RideService();
  final TextEditingController _feedbackController = TextEditingController();
  
  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0.0) {
      setState(() => _error = 'Please provide a rating');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final rideService = RideService();
      await rideService.submitRating(
        rideId: widget.ride.id,
        rating: _rating,
        review: _reviewController.text,
        categoryRatings: _categoryRatings,
        isDriver: widget.isDriver,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      setState(() => _error = 'Failed to submit rating: ${e.toString()}');
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
            const SizedBox(height: 8),
            Text(
              '${widget.ride.origin} to ${widget.ride.destination}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Rating Section
            _buildRatingSection(),

            // Review Section
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add a review (optional)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your experience...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error Message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],

            // Submit Button
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How was your experience?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rate by category:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._categoryRatings.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(
                      _categoryIcons[entry.key] ?? Icons.star,
                      size: 20,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key[0].toUpperCase() + entry.key.substring(1),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    RatingBar.builder(
                      initialRating: entry.value,
                      minRating: 1,
                      maxRating: 5,
                      itemSize: 20,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _categoryRatings[entry.key] = rating;
                        });
                      },
                    ),
                  ],
  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
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
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Submit Rating',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating == 0) return 'Tap to rate';
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent';
  }

  IconData _getVehicleIcon(String? vehicleType) {
    switch (vehicleType) {
      case 'bus':
        return Icons.directions_bus;
      case 'taxi':
        return Icons.local_taxi;
      case 'minibus':
        return Icons.airport_shuttle;
      case 'private_car':
        return Icons.directions_car;
      default:
        return Icons.directions_bus;
    }
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
>>>>>>> origin/rita
  }
}
