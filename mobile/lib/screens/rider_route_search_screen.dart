import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../models/user.dart';
import '../models/school_contract.dart';
import 'rider_available_rides_screen.dart';

class RiderRouteSearchScreen extends StatefulWidget {
  const RiderRouteSearchScreen({super.key});

  @override
  State<RiderRouteSearchScreen> createState() => _RiderRouteSearchScreenState();
}

class _RiderRouteSearchScreenState extends State<RiderRouteSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  String? _selectedVehicleType;
  bool _isLoading = false;

  final List<Map<String, String>> _vehicleTypes = [
    {'type': 'bus', 'icon': '🚌', 'name': 'Bus'},
    {'type': 'taxi', 'icon': '🚕', 'name': 'Taxi'},
    {'type': 'minibus', 'icon': '🚐', 'name': 'Minibus'},
    {'type': 'private_car', 'icon': '🚗', 'name': 'Private Car'},
  ];

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _searchRoutes() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get current user
        final authService = Provider.of<AuthService>(context, listen: false);
        final User? currentUser = authService.currentUser;

        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Show loading message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Searching for available rides...')),
          );
        }

        // Geocode addresses to get real coordinates using Geoapify
        final origin = await LocationService.geocodeAddress(_originController.text);
        final destination = await LocationService.geocodeAddress(_destinationController.text);

        // Navigate to available rides screen where the actual search will happen
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RiderAvailableRidesScreen(
                origin: origin,
                destination: destination,
                vehicleType: _selectedVehicleType,
              ),
            ),
          );
        }
        
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error searching rides: ${e.toString()}')),
          );
        }
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
              // AppBar with gradient
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Book a Ride',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Find your perfect ride',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
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
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Origin card
                          _buildLocationCard(
                            title: 'From',
                            controller: _originController,
                            icon: Icons.location_on,
                            color: Colors.green,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter origin';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Destination card
                          _buildLocationCard(
                            title: 'To',
                            controller: _destinationController,
                            icon: Icons.flag,
                            color: Colors.red,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter destination';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          // Vehicle type selection
                          Text(
                            'Vehicle Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _vehicleTypes.length,
                            itemBuilder: (context, index) {
                              final vehicle = _vehicleTypes[index];
                              final isSelected = _selectedVehicleType == vehicle['type'];
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedVehicleType = vehicle['type'];
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blue[50]
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue[600]!
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        vehicle['icon']!,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        vehicle['name']!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? Colors.blue[700]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                          // Search button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _searchRoutes,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.search, size: 24),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Find Rides',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
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

  Widget _buildLocationCard({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    required String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
              hintText: title == 'From' ? 'Enter your starting location' : 'Enter your destination',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
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
}