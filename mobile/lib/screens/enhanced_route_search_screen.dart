import 'package:flutter/material.dart';
// Removed Google Places imports
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';
import '../services/ride_service.dart';
import '../models/ride.dart';
import '../models/school_contract.dart' as models;
import 'available_rides_screen.dart';

// Add this class for Geoapify response
class GeoapifyPrediction {
  final String placeId;
  final String name;
  final String formatted;
  final double lat;
  final double lng;

  GeoapifyPrediction({
    required this.placeId,
    required this.name,
    required this.formatted,
    required this.lat,
    required this.lng,
  });

  factory GeoapifyPrediction.fromJson(Map<String, dynamic> json) {
    return GeoapifyPrediction(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? json['formatted'] ?? '',
      formatted: json['formatted'] ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lon'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class EnhancedRouteSearchScreen extends StatefulWidget {
  const EnhancedRouteSearchScreen({super.key});

  @override
  State<EnhancedRouteSearchScreen> createState() => _EnhancedRouteSearchScreenState();
}

class _EnhancedRouteSearchScreenState extends State<EnhancedRouteSearchScreen> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final RideService _rideService = RideService();
  
  models.Location? _origin;
  models.Location? _destination;
  bool _isLoading = false;
  String? _selectedVehicleType;
  
  final List<String> _vehicleTypes = ['bus', 'taxi', 'minibus', 'private_car'];
  final List<String> _recentSearches = []; // In a real app, this would be persisted

  // Add these for Geoapify autocomplete
  List<GeoapifyPrediction> _originPredictions = [];
  List<GeoapifyPrediction> _destinationPredictions = [];
  bool _isOriginSearching = false;
  bool _isDestinationSearching = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);
      final location = await LocationService.getCurrentLocation();
      setState(() {
        _origin = location;
        _originController.text = location?.address ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add this method for Geoapify autocomplete
  Future<List<GeoapifyPrediction>> _getPlacePredictions(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // Use LocationService for autocomplete
      final predictions = await LocationService.getPlacePredictions(query);
      
      return predictions.map((prediction) {
        // We need to fetch place details to get lat/lng
        // For now, return a basic prediction that can be used with getPlaceDetails
        return GeoapifyPrediction(
          placeId: prediction.placeId,
          name: prediction.description,
          formatted: prediction.description,
          lat: 0.0,
          lng: 0.0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _searchRides() async {
    if (_origin == null || _destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both origin and destination')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      // Add to recent searches
      final searchKey = '${_origin!.address} → ${_destination!.address}';
      if (!_recentSearches.contains(searchKey)) {
        _recentSearches.insert(0, searchKey);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      }

      // Navigate to available rides screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AvailableRidesScreen(
            origin: _origin!,
            destination: _destination!,
            vehicleType: _selectedVehicleType,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to search rides: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _swapLocations() {
    final tempLocation = _origin;
    final tempController = _originController.text;
    
    setState(() {
      _origin = _destination;
      _destination = tempLocation;
      _originController.text = _destinationController.text;
      _destinationController.text = tempController;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Ride'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Origin input
                  _buildLocationInput(
                    controller: _originController,
                    label: 'From',
                    icon: Icons.my_location,
                    predictions: _originPredictions,
                    isSearching: _isOriginSearching,
                    onTextChanged: (text) {
                      _onTextChanged(text, true);
                    },
                    onPlaceSelected: (models.Location location) {
                      setState(() => _origin = location);
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Swap button
                  Center(
                    child: IconButton(
                      onPressed: _swapLocations,
                      icon: const Icon(Icons.swap_vert),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Destination input
                  _buildLocationInput(
                    controller: _destinationController,
                    label: 'To',
                    icon: Icons.location_on,
                    predictions: _destinationPredictions,
                    isSearching: _isDestinationSearching,
                    onTextChanged: (text) {
                      _onTextChanged(text, false);
                    },
                    onPlaceSelected: (models.Location location) {
                      setState(() => _destination = location);
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Vehicle type selection
                  _buildVehicleTypeSelector(),
                  
                  const SizedBox(height: 24),
                  
                  // Search button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _origin != null && _destination != null ? _searchRides : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Search Rides',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Recent searches
                  if (_recentSearches.isNotEmpty) ...[
                    const Text(
                      'Recent Searches',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._recentSearches.map((search) => _buildRecentSearchItem(search)),
                  ],
                ],
              ),
            ),
    );
  }

  // Modified location input with Geoapify autocomplete
  Widget _buildLocationInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<GeoapifyPrediction> predictions,
    required bool isSearching,
    required Function(String) onTextChanged,
    required Function(models.Location) onPlaceSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: const OutlineInputBorder(),
          ),
          onChanged: onTextChanged,
        ),
        if (isSearching)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(),
            ),
          ),
        if (predictions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: predictions.length,
              itemBuilder: (context, index) {
                final prediction = predictions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                  title: Text(prediction.name),
                  subtitle: Text(prediction.formatted, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    try {
                      // Fetch full place details if placeId is available
                      if (prediction.placeId.isNotEmpty) {
                        final location = await LocationService.getPlaceDetails(prediction.placeId);
                        controller.text = location.address;
                        onPlaceSelected(location);
                      } else {
                        // Fallback: geocode the address
                        final location = await LocationService.geocodeAddress(prediction.formatted);
                        controller.text = location.address;
                        onPlaceSelected(location);
                      }
                      
                      // Clear predictions
                      setState(() {
                        if (label == 'From') {
                          _originPredictions = [];
                          _isOriginSearching = false;
                        } else {
                          _destinationPredictions = [];
                          _isDestinationSearching = false;
                        }
                      });
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to get place details: $e')),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // Add this method to handle text changes
  void _onTextChanged(String text, bool isOrigin) async {
    if (text.isEmpty) {
      setState(() {
        if (isOrigin) {
          _originPredictions = [];
          _isOriginSearching = false;
        } else {
          _destinationPredictions = [];
          _isDestinationSearching = false;
        }
      });
      return;
    }

    setState(() {
      if (isOrigin) {
        _isOriginSearching = true;
      } else {
        _isDestinationSearching = true;
      }
    });

    // Add a small delay to avoid too many API calls
    await Future.delayed(const Duration(milliseconds: 300));

    final predictions = await _getPlacePredictions(text);
    
    setState(() {
      if (isOrigin) {
        _originPredictions = predictions;
        _isOriginSearching = false;
      } else {
        _destinationPredictions = predictions;
        _isDestinationSearching = false;
      }
    });
  }

  Widget _buildVehicleTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Type (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _vehicleTypes.map((type) {
            final isSelected = _selectedVehicleType == type;
            return FilterChip(
              label: Text(_getVehicleTypeLabel(type)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedVehicleType = selected ? type : null;
                });
              },
              selectedColor: Colors.blue[100],
              checkmarkColor: Colors.blue[600],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentSearchItem(String search) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(search),
        onTap: () async {
          // Parse and set the search
          final parts = search.split(' → ');
          if (parts.length == 2) {
            try {
              setState(() => _isLoading = true);
              
              // Geocode addresses to get real coordinates using Geoapify
              final origin = await LocationService.geocodeAddress(parts[0]);
              final destination = await LocationService.geocodeAddress(parts[1]);
              
              setState(() {
                _originController.text = parts[0];
                _destinationController.text = parts[1];
                _origin = origin;
                _destination = destination;
                _isLoading = false;
              });
            } catch (e) {
              setState(() => _isLoading = false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load recent search: $e')),
                );
              }
            }
          }
        },
      ),
    );
  }

  String _getVehicleTypeLabel(String type) {
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

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}