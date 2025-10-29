import 'package:flutter/material.dart';
import '../services/ride_service.dart';
import '../services/location_service.dart';
import '../models/ride.dart';
import '../models/school_contract.dart' as models;
import 'booking_confirmation_screen.dart';

class AvailableRidesScreen extends StatefulWidget {
  final models.Location origin;
  final models.Location destination;
  final String? vehicleType;

  const AvailableRidesScreen({
    super.key,
    required this.origin,
    required this.destination,
    this.vehicleType,
  });

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  final RideService _rideService = RideService();
  List<Ride> _availableRides = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchAvailableRides();
  }

  Future<void> _searchAvailableRides() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final rides = await _rideService.searchAvailableRides(
        origin: widget.origin,
        destination: widget.destination,
        vehicleType: widget.vehicleType,
      );

      setState(() {
        _availableRides = rides;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _availableRides.isEmpty
                  ? _buildNoRidesWidget()
                  : _buildRidesList(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading rides',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _searchAvailableRides,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRidesWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_bus, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No rides available',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('Try adjusting your search criteria'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildRidesList() {
    return Column(
      children: [
        // Route summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.origin.address,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.destination.address,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_availableRides.length} ride${_availableRides.length == 1 ? '' : 's'} found',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        
        // Rides list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _availableRides.length,
            itemBuilder: (context, index) {
              final ride = _availableRides[index];
              return _buildRideCard(ride);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard(Ride ride) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _selectRide(ride),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle type and fare
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getVehicleIcon(ride.vehicleType),
                        color: Colors.blue[600],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getVehicleTypeLabel(ride.vehicleType),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (ride.fare != null)
                    Text(
                      'ETB ${ride.fare!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Route info
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Estimated time: ${_calculateEstimatedTime(ride)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Distance
              Row(
                children: [
                  const Icon(Icons.straighten, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Distance: ${_calculateDistance(ride)} km',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Select button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _selectRide(ride),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Select This Ride'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRide(Ride ride) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(
          ride: ride,
          origin: widget.origin,
          destination: widget.destination,
        ),
      ),
    );
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
  }

  String _calculateEstimatedTime(Ride ride) {
    try {
      // Simple calculation based on distance
      final distance = LocationService.calculateDistance(ride.origin, ride.destination);
      final estimatedMinutes = (distance * 2).round(); // Rough estimate: 2 minutes per km
      return '$estimatedMinutes min';
    } catch (e) {
      debugPrint('Error calculating estimated time: $e');
      return 'N/A';
    }
  }

  String _calculateDistance(Ride ride) {
    try {
      final distance = LocationService.calculateDistance(ride.origin, ride.destination);
      return distance.toStringAsFixed(1);
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return 'N/A';
    }
  }
}
