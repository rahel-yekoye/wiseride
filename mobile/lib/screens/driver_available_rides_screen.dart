import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ride.dart';
import '../models/school_contract.dart';
import '../services/ride_service.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';
import 'driver_ride_tracking_screen.dart';
import '../models/user.dart';

class DriverAvailableRidesScreen extends StatefulWidget {
  const DriverAvailableRidesScreen({super.key});

  @override
  State<DriverAvailableRidesScreen> createState() => _DriverAvailableRidesScreenState();
}

class _DriverAvailableRidesScreenState extends State<DriverAvailableRidesScreen> {
  final RideService _rideService = RideService();
  final WebSocketService _webSocketService = WebSocketService();
  // NotificationService is used statically
  
  List<Ride> _availableRides = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, User> _userMap = {};

  @override
  void initState() {
    super.initState();
    _setupWebSocketListeners();
    _setupNotificationListeners();
    _loadAvailableRides();
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }


  void _setupWebSocketListeners() {
    // Listen for new ride requests
    _webSocketService.rideUpdatesStream.listen((event) async {
      debugPrint('Received WebSocket event: $event');
      
      if (event['type'] == 'new_ride_request') {
        // Show notification for new ride request
        if (mounted) {
          final notificationService = NotificationService();
          
          // Refresh the list of available rides
          _loadAvailableRides();
          await notificationService.showDriverNotification(
            title: 'New Ride Request',
            body: 'A new ride is available near you!',
            payload: event['rideId']?.toString() ?? '',
          );
          // Refresh the list of available rides
          if (mounted) {
            _loadAvailableRides();
          }
        }
      }
    });
  }

  void _setupNotificationListeners() {
    // Handle notification taps
    NotificationService().onNotificationClicked.listen((payload) {
      if (mounted && payload != null && payload.isNotEmpty) {
        // If notification has a rideId, navigate to ride details
        _loadAvailableRides();
      }
    });
  }

  // Get current location of the driver
  Future<Location?> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Reverse geocode to get address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = '${place.street}, ${place.locality}, ${place.country}';
        
        return Location(
          lat: position.latitude,
          lng: position.longitude,
          address: address,
        );
      }
      
      return Location(
        lat: position.latitude,
        lng: position.longitude,
        address: 'Current Location',
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  Future<void> _loadAvailableRides() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      // Get current location
      final currentLocation = await _getCurrentLocation();
      
      if (currentLocation == null) {
        throw Exception('Could not determine your current location');
      }
      
      // Fetch available rides from the server with current location
      final rideService = RideService();
      final rides = await rideService.getAvailableRides(
        lat: currentLocation.lat,
        lng: currentLocation.lng,
        maxDistance: 5000, // 5km radius
      );
      
      // For demo purposes, if no rides are available, show sample rides
      final demoRides = rides.isNotEmpty ? rides : [
        Ride(
          id: '1',
          type: 'public',
          riderId: 'passenger1',
          origin: Location(
            address: 'Nearby Location',
            lat: currentLocation.lat + 0.01, // 1km away
            lng: currentLocation.lng + 0.01,
            lng: 38.7578,
          ),
          destination: Location(
            address: 'Meskel Square',
            lat: 9.0185,
            lng: 38.7523,
          ),
          status: 'requested',
          fare: 150.0,
          vehicleType: 'taxi',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        Ride(
          id: '2',
          type: 'public',
          riderId: 'passenger2',
          origin: Location(
            address: 'Mexico Square',
            lat: 9.0231,
            lng: 38.7465,
          ),
          destination: Location(
            address: 'Arat Kilo',
            lat: 9.0300,
            lng: 38.7600,
          ),
          status: 'requested',
          fare: 120.0,
          vehicleType: 'minibus',
          createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      ];
      
      // Create a map to store user data for each ride
      final userMap = {
        'passenger1': User(
          id: 'passenger1', 
          name: 'Passenger 1', 
          email: 'passenger1@example.com',
          role: 'rider',
        ),
        'passenger2': User(
          id: 'passenger2', 
          name: 'Passenger 2', 
          email: 'passenger2@example.com',
          role: 'rider',
        ),
      };
      
      if (mounted) {
        setState(() {
          _availableRides = demoRides;
          _userMap = userMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load available rides: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptRide(Ride ride) async {
    try {
      await _rideService.acceptRide(ride.id!);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride accepted successfully!')),
        );
        
        // Navigate to ride tracking screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DriverRideTrackingScreen(ride: ride),
            ),
          );
        }
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
        title: const Text(
          'Available Rides',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableRides,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAvailableRides,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _availableRides.isEmpty
                  ? const Center(
                      child: Text(
                        'No available rides at the moment.\nCheck back later!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAvailableRides,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _availableRides.length,
                        itemBuilder: (context, index) {
                          final ride = _availableRides[index];
                          return _buildRideCard(ride);
                        },
                      ),
                    ),
    );
  }

  // Format vehicle type for display
  String _formatVehicleType(String type) {
    switch (type.toLowerCase()) {
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

  // Format status for display
  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'started':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  // Get color based on status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'started':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Build a location info row with icon and address
  Widget _buildLocationInfo(IconData icon, String label, Location location) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location.address,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build an info chip with icon and text
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Build a ride card widget
  Widget _buildRideCard(Ride ride) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ride #${ride.id?.substring(0, 6) ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatVehicleType(ride.vehicleType ?? 'bus'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildLocationInfo(
              Icons.my_location,
              'From',
              ride.origin,
            ),
            const SizedBox(height: 8),
            _buildLocationInfo(
              Icons.location_on,
              'To',
              ride.destination,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  Icons.person,
                  '1 passenger',
                ),
                _buildInfoChip(
                  Icons.attach_money,
                  'ETB ${ride.fare?.toStringAsFixed(2) ?? '0.00'}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _acceptRide(ride),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Accept Ride',
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

  // Build a location row with icon and text
  Widget _buildLocationRow(IconData icon, String title, String? subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
