import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';

class DriverRideTrackingScreen extends StatefulWidget {
  final Ride ride;
  
  const DriverRideTrackingScreen({super.key, required this.ride});

  @override
  State<DriverRideTrackingScreen> createState() => _DriverRideTrackingScreenState();
}

class _DriverRideTrackingScreenState extends State<DriverRideTrackingScreen> {
  late Ride _ride;
  bool _isLoading = false;
  final String _errorMessage = '';
  final WebSocketService _webSocketService = WebSocketService();
  final NotificationService _notificationService = NotificationService();
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    _setupWebSocketListeners();
    _joinRideRoom();
    _startLocationTracking();
  }

  void _setupWebSocketListeners() {
    // Listen for ride updates
    _webSocketService.rideUpdatesStream.listen((event) {
      if (mounted) {
        setState(() {
          if (event['type'] == 'ride_cancelled') {
            _ride = Ride.fromJson(event['data']);
            _showNotification('Ride Cancelled', 'The ride has been cancelled');
          }
        });
      }
    });
  }

  void _joinRideRoom() {
    if (_ride.id != null) {
      _webSocketService.joinRideRoom(_ride.id!);
    }
  }

  void _startLocationTracking() {
    // Start sending location updates to the rider
    LocationService.getCurrentLocation().then((location) {
      if (location != null && _ride.id != null) {
        _webSocketService.sendDriverLocation(
          rideId: _ride.id!,
          latitude: location.lat,
          longitude: location.lng,
        );
      }
    });
  }

  void _showNotification(String title, String body) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $body'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _startRide() async {
    try {
      setState(() => _isLoading = true);
      
      final rideService = RideService();
      final updatedRide = await rideService.startRide(_ride.id!);
      
      setState(() {
        _ride = updatedRide;
        _isLoading = false;
      });

      await _notificationService.showDriverNotification(
        title: 'Ride Started',
        body: 'You have started the ride',
        rideId: _ride.id!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride started successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start ride: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _endRide() async {
    try {
      setState(() => _isLoading = true);
      
      final rideService = RideService();
      final updatedRide = await rideService.endRide(_ride.id!);
      
      setState(() {
        _ride = updatedRide;
        _isLoading = false;
      });

      await _notificationService.showDriverNotification(
        title: 'Ride Completed',
        body: 'You have completed the ride',
        rideId: _ride.id!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride completed successfully')),
        );
        
        // Navigate back to driver home
        Navigator.pushReplacementNamed(context, '/driver_home');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end ride: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_ride.id != null) {
      _webSocketService.leaveRideRoom(_ride.id!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Current Ride',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${_formatStatus(_ride.status)}',
              style: TextStyle(
                fontSize: 16,
                color: _getStatusColor(_ride.status),
              ),
            ),
            const SizedBox(height: 16),
            // Ride details card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatVehicleType(_ride.vehicleType ?? 'bus'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_ride.fare != null)
                          Text(
                            '${_ride.fare!.toStringAsFixed(2)} ETB',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _ride.origin.address,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _ride.destination.address,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rider Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        // In a real app, you would fetch rider details
                        Text('Rider: Jane Doe'),
                        Text('Phone: +251 9XX XXX XXX'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons based on ride status
            if (_ride.status == 'accepted')
              ElevatedButton(
                onPressed: _isLoading ? null : _startRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Start Ride',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            if (_ride.status == 'in_progress')
              ElevatedButton(
                onPressed: _isLoading ? null : _endRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'End Ride',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            if (_ride.status == 'completed')
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Ride completed successfully!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatVehicleType(String type) {
    switch (type) {
      case 'bus':
        return 'Bus';
      case 'taxi':
        return 'Taxi';
      case 'minibus':
        return 'Minibus';
      case 'private_car':
        return 'Private Car';
      default:
        return type;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted - Ready to Start';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
