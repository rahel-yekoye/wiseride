import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';
import 'driver_ride_tracking_screen.dart';

class DriverAvailableRidesScreen extends StatefulWidget {
  const DriverAvailableRidesScreen({super.key});

  @override
  State<DriverAvailableRidesScreen> createState() => _DriverAvailableRidesScreenState();
}

class _DriverAvailableRidesScreenState extends State<DriverAvailableRidesScreen> {
  final RideService _rideService = RideService();
  final WebSocketService _webSocketService = WebSocketService();
  final NotificationService _notificationService = NotificationService();
  
  List<Ride> _availableRides = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableRides();
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    // Listen for new ride requests
    _webSocketService.rideUpdatesStream.listen((event) {
      if (event['type'] == 'new_ride_request') {
        _loadAvailableRides(); // Refresh the list
      }
    });
  }

  Future<void> _loadAvailableRides() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final rides = await _rideService.getAvailableRides();
      
      setState(() {
        _availableRides = rides;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load available rides: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRide(Ride ride) async {
    try {
      await _rideService.acceptRide(ride.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride accepted successfully!')),
        );
        
        // Show notification
        await _notificationService.showDriverNotification(
          title: 'Ride Accepted',
          body: 'You have accepted a ride request',
          rideId: ride.id!,
        );
        
        // Navigate to ride tracking screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DriverRideTrackingScreen(ride: ride),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept ride: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableRides,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAvailableRides,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Available Rides',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage.isNotEmpty)
                Center(
                  child: Column(
                    children: [
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAvailableRides,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (_availableRides.isEmpty)
                const Center(
                  child: Text(
                    'No available rides at the moment.\nCheck back later!',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _availableRides.length,
                    itemBuilder: (context, index) {
                      final ride = _availableRides[index];
                      return _buildRideCard(ride);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatVehicleType(ride.vehicleType ?? 'bus'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (ride.fare != null)
                  Text(
                    '${ride.fare!.toStringAsFixed(2)} ETB',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.origin.address,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                    ride.destination.address,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatStatus(ride.status),
                  style: TextStyle(
                    fontSize: 14,
                    color: _getStatusColor(ride.status),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _acceptRide(ride),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Accept Ride'),
                ),
              ],
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
      case 'requested':
        return 'Available';
      case 'accepted':
        return 'Accepted';
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
      case 'requested':
        return Colors.green;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
