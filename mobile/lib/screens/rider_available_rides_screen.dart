import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ride.dart';
import '../models/school_contract.dart';
import '../services/ride_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'rider_ride_tracking_screen.dart';
import 'booking_confirmation_screen.dart';

class RiderAvailableRidesScreen extends StatefulWidget {
  final Location? origin;
  final Location? destination;
  final String? vehicleType;
  
  const RiderAvailableRidesScreen({
    super.key,
    this.origin,
    this.destination,
    this.vehicleType,
  });

  @override
  State<RiderAvailableRidesScreen> createState() => _RiderAvailableRidesScreenState();
}

class _RiderAvailableRidesScreenState extends State<RiderAvailableRidesScreen> {
  List<Ride> _availableRides = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final Map<String, Map<String, dynamic>> _rideCalculations = {};

  @override
  void initState() {
    super.initState();
    _loadAvailableRides();
  }

  Future<void> _loadAvailableRides() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final rideService = RideService();
      final rides = await rideService.searchAvailableRides(
        origin: widget.origin,
        destination: widget.destination,
        vehicleType: widget.vehicleType,
      );
      
      setState(() {
        _availableRides = rides;
        _isLoading = false;
      });

      // Calculate real-time data for each ride
      _calculateRideData();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load available rides: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _calculateRideData() async {
    for (final ride in _availableRides) {
      if (ride.id != null) {
        try {
          final distanceData = await LocationService.calculateDrivingDistance(
            ride.origin,
            ride.destination,
          );

          final dynamicFare = await LocationService.calculateDynamicFare(
            ride.origin,
            ride.destination,
            ride.vehicleType ?? 'bus',
          );

          setState(() {
            _rideCalculations[ride.id!] = {
              'distance': distanceData['distance'],
              'duration': distanceData['duration'],
              'fare': dynamicFare,
            };
          });
        } catch (e) {
          debugPrint('Error calculating data for ride ${ride.id}: $e');
        }
      }
    }
  }

  Future<void> _refreshRides() async {
    await _loadAvailableRides();
  }

  Future<void> _bookRide(Ride ride) async {
    try {
      // Navigate to booking confirmation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationScreen(
            ride: ride,
            origin: widget.origin!,
            destination: widget.destination!,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book ride: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _createRideRequest() async {
    try {
      final rideService = RideService();
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Create a new ride request
      final newRide = Ride(
        type: 'public',
        origin: widget.origin!,
        destination: widget.destination!,
        vehicleType: widget.vehicleType ?? 'bus',
        status: 'requested',
      );

      final createdRide = await rideService.createRide(newRide);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride request created successfully!')),
        );
        
        // Reload the rides list
        _loadAvailableRides();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create ride request: ${e.toString()}')),
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
                            'Available Rides',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (widget.origin != null || widget.destination != null)
                            Text(
                              '${widget.origin?.address ?? ''} → ${widget.destination?.address ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                    onRefresh: _refreshRides,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage.isNotEmpty
                            ? _buildErrorWidget()
                            : _availableRides.isEmpty
                                ? _buildNoRidesWidget()
                                : _buildRidesList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAvailableRides,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRidesWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bus, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No rides available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to request a ride on this route!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _createRideRequest,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Create Ride Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadAvailableRides,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableRides.length,
      itemBuilder: (context, index) {
        final ride = _availableRides[index];
        return _buildRideCard(ride);
      },
    );
  }

  Widget _buildRideCard(Ride ride) {
    final vehicleIcon = _getVehicleIcon(ride.vehicleType ?? 'bus');
    final fare = ride.id != null && _rideCalculations.containsKey(ride.id!)
        ? _rideCalculations[ride.id!]!['fare']
        : ride.fare;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        children: [
          // Header with vehicle type and price
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vehicleIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatVehicleType(ride.vehicleType ?? 'bus'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        _formatStatus(ride.status),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(ride.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (fare != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${fare.toStringAsFixed(0)} ETB',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Route info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, size: 20, color: Colors.green[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ride.origin.address,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
                  child: Container(
                    width: 2,
                    height: 20,
                    color: Colors.grey[300],
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 20, color: Colors.red[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ride.destination.address,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Distance and duration
                if (ride.id != null && _rideCalculations.containsKey(ride.id!)) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(
                        Icons.straighten,
                        '${_rideCalculations[ride.id!]!['distance'].toStringAsFixed(1)} km',
                        Colors.blue,
                      ),
                      _buildInfoChip(
                        Icons.access_time,
                        '${_rideCalculations[ride.id!]!['duration'].round()} min',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                // Book button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _bookRide(ride),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text(
                      'Book This Ride',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  String _getVehicleIcon(String type) {
    switch (type) {
      case 'bus':
        return '🚌';
      case 'taxi':
        return '🚕';
      case 'minibus':
        return '🚐';
      case 'private_car':
        return '🚗';
      default:
        return '🚗';
    }
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