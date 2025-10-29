import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../models/ride.dart';
import '../models/school_contract.dart' as models;
import 'api_service.dart';

class Prediction {
  final String placeId;
  final String description;

  Prediction({required this.placeId, required this.description});

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class LocationService {
  static const String _geoapifyApiKey = 'f4d95417cd5045a5abcdd07cb182e643';
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Initialize location service
  /// This method should be called during app startup
  static Future<void> initialize() async {
    try {
      // Request location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are disabled, we can't continue
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately 
        return;
      }

      // If we got here, permissions are granted and we can get the location
      await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error initializing location service: $e');
      // Don't throw, let the app continue without location services
    }
  }

  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;
  Timer? _updateTimer;
  bool _isTracking = false;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  // Start location tracking
  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Start position stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(
        _onLocationUpdate,
        onError: (error) {
          debugPrint('Location error: $error');
        },
      );

      _isTracking = true;
      debugPrint('Location tracking started');
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      rethrow;
    }
  }

  // Stop location tracking
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _updateTimer?.cancel();
    _isTracking = false;
    debugPrint('Location tracking stopped');
  }

  // Handle location updates
  void _onLocationUpdate(Position position) {
    _currentPosition = position;
    
    // Update location on server every 30 seconds
    _updateTimer?.cancel();
    _updateTimer = Timer(const Duration(seconds: 30), () {
      _updateLocationOnServer(position);
    });
  }

  // Update location on server
  Future<void> _updateLocationOnServer(Position position) async {
    try {
      final apiService = ApiService();
      await apiService.put('/driver/location', body: {
        'lat': position.latitude,
        'lng': position.longitude,
        'address': await _getAddressFromPosition(position),
      });
      debugPrint('Location updated on server');
    } catch (e) {
      debugPrint('Error updating location on server: $e');
    }
  }

  // Get current location
  static Future<models.Location?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address = await _reverseGeocode(position.latitude, position.longitude);

      return models.Location(
        lat: position.latitude,
        lng: position.longitude,
        address: address,
      );
    } catch (e) {
      debugPrint('Failed to get current location: $e');
      return null;
    }
  }

  // Get address from position
  static Future<String> _getAddressFromPosition(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final parts = <String>[];
        
        if (placemark.street != null && placemark.street!.isNotEmpty) {
          parts.add(placemark.street!);
        }
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          parts.add(placemark.locality!);
        }
        if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
          parts.add(placemark.administrativeArea!);
        }
        
        return parts.isNotEmpty ? parts.join(', ') : 'Unknown location';
      }
      return 'Unknown location';
    } catch (e) {
      debugPrint('Error getting address: $e');
      return 'Unknown location';
    }
  }

  // Geocode address to coordinates (Geoapify)
  static Future<models.Location> geocodeAddress(String address) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(address)}&apiKey=$_geoapifyApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final properties = feature['properties'];
          
          return models.Location(
            lat: properties['lat'],
            lng: properties['lon'],
            address: properties['formatted'],
          );
        }
      }
      throw Exception('Failed to geocode address');
    } catch (e) {
      debugPrint('Geocoding error: $e');
      rethrow;
    }
  }

  // Reverse geocode coordinates to address (Geoapify)
  static Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.geoapify.com/v1/geocode/reverse?lat=$lat&lon=$lng&apiKey=$_geoapifyApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          return data['features'][0]['properties']['formatted'];
        }
      }
      return 'Unknown location';
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      return 'Unknown location';
    }
  }

  // Calculate distance between two points in meters
  // Can be called with either individual coordinates or Location objects
  static double calculateDistance(dynamic origin, dynamic destination, [double? lat2, double? lng2]) {
    // If origin is a Location object and destination is a Location object
    if (origin is models.Location && destination is models.Location) {
      return Geolocator.distanceBetween(
        origin.lat,
        origin.lng,
        destination.lat,
        destination.lng,
      );
    }
    // If origin and destination are strings (addresses)
    else if (origin is String && destination is String) {
      // This would need to be implemented with geocoding
      throw UnimplementedError('Distance calculation between addresses not implemented');
    }
    // If individual coordinates are provided
    else if (origin is double && destination is double && lat2 != null && lng2 != null) {
      return Geolocator.distanceBetween(origin, destination, lat2, lng2);
    }
    // If origin is a Location and destination is a string (address)
    else if (origin is models.Location && destination is String) {
      // This would need geocoding implementation
      throw UnimplementedError('Distance calculation between location and address not implemented');
    }
    
    throw ArgumentError('Invalid arguments provided to calculateDistance');
  }

  // Deprecated: Use calculateDistance with Location objects instead
  @Deprecated('Use calculateDistance with Location objects instead')
  static double calculateDistanceBetweenLocations(
      models.Location location1, models.Location location2) {
    return calculateDistance(location1, location2);
  }

  // Calculate driving distance using Geoapify Routing API
  static Future<double> calculateDrivingDistance(
      models.Location origin, models.Location destination) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.geoapify.com/v1/routing?waypoints=${origin.lat},${origin.lng}|${destination.lat},${destination.lng}&mode=drive&apiKey=$_geoapifyApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null &&
            data['features'].isNotEmpty &&
            data['features'][0]['properties']['distance'] != null) {
          return data['features'][0]['properties']['distance'].toDouble();
        }
      }
      throw Exception('Failed to calculate driving distance');
    } catch (e) {
      debugPrint('Error calculating driving distance: $e');
      // Fallback to straight-line distance
      return calculateDistanceBetweenLocations(origin, destination);
    }
  }

  // Calculate dynamic fare
  static Future<double> calculateDynamicFare(
    models.Location origin,
    models.Location destination,
    String vehicleType,
  ) async {
    try {
      // Get driving distance
      double distance = await calculateDrivingDistance(origin, destination);
      
      // Convert meters to kilometers
      double distanceKm = distance / 1000;
      
      // Base fare and per km rate based on vehicle type
      double baseFare;
      double perKmRate;
      
      switch (vehicleType.toLowerCase()) {
        case 'premium':
          baseFare = 50.0;
          perKmRate = 15.0;
          break;
        case 'xl':
          baseFare = 40.0;
          perKmRate = 12.0;
          break;
        default: // standard
          baseFare = 30.0;
          perKmRate = 10.0;
      }
      
      // Calculate fare
      double fare = baseFare + (distanceKm * perKmRate);
      
      // Add minimum fare check
      return fare < baseFare * 1.5 ? baseFare * 1.5 : fare;
    } catch (e) {
      debugPrint('Error calculating fare: $e');
      // Return a default fare if calculation fails
      return 50.0;
    }
  }

  // Get directions (polyline waypoints)
  static Future<List<Map<String, double>>> getDirections(
      models.Location origin, models.Location destination) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.geoapify.com/v1/routing?waypoints=${origin.lat},${origin.lng}|${destination.lat},${destination.lng}&mode=drive&apiKey=$_geoapifyApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final coordinates = data['features'][0]['geometry']['coordinates'];
          return List<Map<String, double>>.from(
            coordinates.map((coord) => {'lat': coord[1], 'lng': coord[0]}),
          );
        }
      }
      throw Exception('Failed to get directions');
    } catch (e) {
      debugPrint('Error getting directions: $e');
      return [];
    }
  }

  // Autocomplete places (Geoapify)
  static Future<List<Prediction>> autocompletePlaces(String query) async {
    try {
      if (query.isEmpty) return [];

      final response = await http.get(
        Uri.parse(
          'https://api.geoapify.com/v1/geocode/autocomplete?text=${Uri.encodeComponent(query)}&apiKey=$_geoapifyApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null) {
          return (data['features'] as List)
              .map((feature) => Prediction(
                    placeId: feature['properties']['place_id'],
                    description: feature['properties']['formatted'],
                  ))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error in autocomplete: $e');
      return [];
    }
  }

  // Get place details (Geoapify)
  static Future<models.Location?> getPlaceDetails(String placeId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.geoapify.com/v1/geocode/search?text=place:${Uri.encodeComponent(placeId)}&apiKey=$_geoapifyApiKey',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final properties = feature['properties'];
          
          return models.Location(
            lat: properties['lat'],
            lng: properties['lon'],
            address: properties['formatted'],
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting place details: $e');
      return null;
    }
  }

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get location permission status
  static Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  // Dispose resources
  void dispose() {
    stopTracking();
  }
}
