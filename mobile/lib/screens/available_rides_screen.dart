import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'ride_details_screen.dart';
import '../widgets/sos_button.dart';

class AvailableRidesScreen extends StatefulWidget {
  const AvailableRidesScreen({super.key});

  @override
  State<AvailableRidesScreen> createState() => _AvailableRidesScreenState();
}

class _AvailableRidesScreenState extends State<AvailableRidesScreen> {
  List<dynamic> _availableRides = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  double? _driverLat;
  double? _driverLng;

  @override
  void initState() {
    super.initState();
    _loadAvailableRides();
  }

  // Haversine distance in kilometers
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);

  Future<void> _loadAvailableRides() async {
    try {
      final apiService = ApiService();
      final locationService = LocationService();
      final pos = await locationService.getCurrentLocation();
      final lat = pos?.latitude ?? 9.0192; // Fallback Addis Ababa
      final lng = pos?.longitude ?? 38.7525;

      final rides = await apiService.get('/driver/rides/nearby', queryParams: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': '10'
      });
      if (!mounted) return;
      setState(() {
        _availableRides = rides;
        _isLoading = false;
        _driverLat = lat;
        _driverLng = lng;
      });
    } catch (e) {
      // Fallback to mock data if backend is not available
      if (!mounted) return;
      setState(() {
        _availableRides = [
          {
            '_id': '1',
            'riderId': {'name': 'Sarah Johnson', 'phone': '+251911234567'},
            'origin': {
              'address': 'Bole Airport, Addis Ababa',
              // Optional coordinates format [lng, lat]
              'coordinates': [38.7950, 8.9779]
            },
            'destination': {'address': 'Meskel Square, Addis Ababa'},
            'vehicleType': 'taxi',
            'status': 'requested',
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            '_id': '2',
            'riderId': {'name': 'Michael Chen', 'phone': '+251922345678'},
            'origin': {
              'address': 'Addis Ababa University, Addis Ababa',
              'coordinates': [38.7995, 9.0405]
            },
            'destination': {'address': 'Sheraton Addis, Addis Ababa'},
            'vehicleType': 'bus',
            'status': 'requested',
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            '_id': '3',
            'riderId': {'name': 'Alem Gebre', 'phone': '+251933456789'},
            'origin': {
              'address': 'Mercato, Addis Ababa',
              'coordinates': [38.7380, 9.0320]
            },
            'destination': {'address': 'Bole Road, Addis Ababa'},
            'vehicleType': 'minibus',
            'status': 'requested',
            'createdAt': DateTime.now().toIso8601String(),
          },
        ];
        _isLoading = false;
        _driverLat = 9.0192;
        _driverLng = 38.7525;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using offline mode: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _acceptRide(String rideId) async {
    try {
      final apiService = ApiService();
      await apiService.put('/driver/rides/$rideId/accept');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadAvailableRides(); // Refresh the list to remove the accepted ride
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting ride: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      // Soft refresh to sync statuses if ride just got accepted by someone else
      await _loadAvailableRides();
    }
  }

  List<dynamic> get _filteredRides {
    if (_selectedFilter == 'all') return _availableRides;
    return _availableRides.where((ride) => ride['vehicleType'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Rides'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableRides,
          ),
        ],
      ),
      floatingActionButton: const SOSButton(),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('taxi', 'Taxi'),
                  const SizedBox(width: 8),
                  _buildFilterChip('bus', 'Bus'),
                  const SizedBox(width: 8),
                  _buildFilterChip('minibus', 'Minibus'),
                ],
              ),
            ),
          ),
          
          // Rides list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRides.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.directions_car_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No rides available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check back later for new ride requests',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAvailableRides,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRides.length,
                          itemBuilder: (context, index) {
                            final ride = _filteredRides[index];
                            return _buildRideCard(ride);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    // Compute pickup distance if coordinates available
    final pickCoords = ride['origin']?['coordinates'];
    double? distanceKm;
    if (pickCoords is List && pickCoords.length == 2 && _driverLat != null && _driverLng != null) {
      final lng = (pickCoords[0] as num).toDouble();
      final lat = (pickCoords[1] as num).toDouble();
      distanceKm = _haversineKm(_driverLat!, _driverLng!, lat, lng);
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getVehicleIcon(ride['vehicleType']),
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride['riderId']['name'] ?? 'Unknown Rider',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ride['vehicleType']?.toString().toUpperCase() ?? 'UNKNOWN',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Route information
            Row(
              children: [
                const Icon(Icons.my_location, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride['origin']['address'] ?? 'Unknown origin',
                    style: const TextStyle(fontSize: 14),
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
                    ride['destination']['address'] ?? 'Unknown destination',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Distance to pickup (if available)
            if (distanceKm != null) ...[
              Row(
                children: [
                  const Icon(Icons.route, color: Colors.blueGrey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pickup distance: ${distanceKm.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Map preview placeholder (replace with Google Maps later)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Map preview (add Google Maps later)')
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RideDetailsScreen(ride: ride),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptRide(ride['_id']),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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

  IconData _getVehicleIcon(String? vehicleType) {
    switch (vehicleType?.toLowerCase()) {
      case 'taxi':
        return Icons.local_taxi;
      case 'bus':
        return Icons.directions_bus;
      case 'minibus':
        return Icons.airport_shuttle;
      default:
        return Icons.directions_car;
    }
  }
}
