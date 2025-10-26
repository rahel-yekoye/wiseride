import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ride.dart';
import '../services/ride_service.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';

class RiderRideTrackingScreen extends StatefulWidget {
  final Ride ride;
  
  const RiderRideTrackingScreen({super.key, required this.ride});

  @override
  State<RiderRideTrackingScreen> createState() => _RiderRideTrackingScreenState();
}

class _RiderRideTrackingScreenState extends State<RiderRideTrackingScreen> {
  late Ride _ride;
  bool _isLoading = false;
  String _errorMessage = '';
  final WebSocketService _webSocketService = WebSocketService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
    _setupWebSocketListeners();
    _joinRideRoom();
  }

  void _setupWebSocketListeners() {
    // Listen for ride updates
    _webSocketService.rideUpdatesStream.listen((event) {
      if (mounted) {
        setState(() {
          // Update ride status based on WebSocket events
          if (event['type'] == 'ride_accepted') {
            _ride = Ride.fromJson(event['data']);
            _showNotification('Ride Accepted', 'Your ride has been accepted by a driver');
          } else if (event['type'] == 'ride_started') {
            _ride = Ride.fromJson(event['data']);
            _showNotification('Ride Started', 'Your driver is on the way');
          } else if (event['type'] == 'ride_completed') {
            _ride = Ride.fromJson(event['data']);
            _showNotification('Ride Completed', 'Thank you for using WiseRide!');
          }
        });
      }
    });

    // Listen for driver location updates
    _webSocketService.driverLocationStream.listen((event) {
      if (mounted) {
        // Update driver location on map
        debugPrint('Driver location update: ${event['data']}');
      }
    });
  }

  void _joinRideRoom() {
    if (_ride.id != null) {
      _webSocketService.joinRideRoom(_ride.id!);
    }
  }

  void _showNotification(String title, String body) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $body'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    if (_ride.id != null) {
      _webSocketService.leaveRideRoom(_ride.id!);
    }
    super.dispose();
  }

  Future<void> _refreshRide() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final rideService = RideService();
      final updatedRide = await rideService.getRideById(_ride.id!);
      
      setState(() {
        _ride = updatedRide;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to refresh ride: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelRide() async {
    // Show confirmation dialog
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this ride?'),
            const SizedBox(height: 16),
            const Text(
              'Cancellation Reason:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...['Change of plans', 'Driver issues', 'Other'].map((reason) {
              return RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: null,
                onChanged: (value) {
                  Navigator.pop(context, true);
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Ride'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Ride'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final rideService = RideService();
      final updatedRide = await rideService.cancelRide(_ride.id!);
      
      setState(() {
        _ride = updatedRide;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel ride: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeRide() async {
    try {
      final rideService = RideService();
      final updatedRide = await rideService.updateRideStatus(_ride.id!, 'completed');
      
      setState(() {
        _ride = updatedRide;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete ride: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _viewMap() async {
    try {
      // Create a Google Maps URL with the route
      final originLat = _ride.origin.lat;
      final originLng = _ride.origin.lng;
      final destLat = _ride.destination.lat;
      final destLng = _ride.destination.lng;
      
      // Try to open in Google Maps
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving',
      );
      
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open maps: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[600]!,
              Colors.blue[400]!,
              Colors.blue[300]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ride Tracking',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _formatStatus(_ride.status),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _refreshRide,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status card
                          _buildStatusCard(),
                          const SizedBox(height: 24),
                          // Route card
                          _buildRouteCard(),
                          const SizedBox(height: 24),
                          // Driver info
                          if (_ride.driverId != null) ...[
                            _buildDriverCard(),
                            const SizedBox(height: 24),
                          ],
                          // Action buttons
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(_ride.status).withOpacity(0.1),
            _getStatusColor(_ride.status).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(_ride.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(_ride.status),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _getStatusIcon(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatStatus(_ride.status),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                if (_ride.fare != null)
                  Text(
                    '${_ride.fare!.toStringAsFixed(0)} ETB',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon() {
    switch (_ride.status) {
      case 'requested':
        return const Icon(Icons.hourglass_empty, color: Colors.white, size: 32);
      case 'accepted':
        return const Icon(Icons.check_circle, color: Colors.white, size: 32);
      case 'in_progress':
        return const Icon(Icons.directions_car, color: Colors.white, size: 32);
      case 'completed':
        return const Icon(Icons.done_all, color: Colors.white, size: 32);
      case 'cancelled':
        return const Icon(Icons.cancel, color: Colors.white, size: 32);
      default:
        return const Icon(Icons.info, color: Colors.white, size: 32);
    }
  }

  Widget _buildRouteCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 24, color: Colors.green[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _ride.origin.address,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(left: 12),
              width: 2,
              height: 30,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.flag, size: 24, color: Colors.red[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _ride.destination.address,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Driver Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'John Doe'),
            _buildInfoRow(Icons.directions_car, 'Toyota Camry'),
            _buildInfoRow(Icons.confirmation_number, 'AA 1234'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _viewMap,
            icon: const Icon(Icons.map),
            label: const Text(
              'View on Map',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        if (_ride.status == 'requested' || _ride.status == 'accepted') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _cancelRide,
              icon: const Icon(Icons.cancel),
              label: const Text(
                'Cancel Ride',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
        if (_ride.status == 'in_progress') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _completeRide,
              icon: const Icon(Icons.check_circle),
              label: const Text(
                'Complete Ride',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
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
        return 'Requested';
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
        return Colors.orange;
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