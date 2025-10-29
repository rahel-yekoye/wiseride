import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/school_contract.dart' as models;

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
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const String _geoapifyApiKey = 'f4d95417cd5045a5abcdd07cb182e643';
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          throw Exception('Location permissions are denied');
        }
      }

      _isTracking = true;
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Update every 10 meters
        ),
      ).listen(_onLocationUpdate);
    } catch (e) {
      _isTracking = false;
      rethrow;
    }
  }

  // Stop location tracking
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _updateTimer?.cancel();
    _updateTimer = null;
    _isTracking = false;
  }

  // Handle location updates
  void _onLocationUpdate(Position position) {
    _currentPosition = position;
    _updateLocationOnServer(position);
  }

  // Update location on server
  Future<void> _updateLocationOnServer(Position position) async {
    try {
      // Update the timer to throttle server updates
      _updateTimer?.cancel();
      _updateTimer = Timer(const Duration(seconds: 10), () async {
        await ApiService().post('/users/update-location', body: {
          'lat': position.latitude,
          'lng': position.longitude,
          'heading': position.heading,
          'speed': position.speed,
        });
      });
    } catch (e) {
      debugPrint('Error updating location on server: $e');
    }
  }

  // Get current location once
  Future<Position> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          throw Exception('Location permissions are denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentPosition = position;
      return position;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      rethrow;
    }
  }

  // Get address from position
  Future<String> getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}, ${place.country}';
      }
      return '${position.latitude}, ${position.longitude}';
    } catch (e) {
      debugPrint('Error getting address from position: $e');
      return '${position.latitude}, ${position.longitude}';
    }
  }

  // Calculate distance between two points
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  // Calculate distance between two Location objects
  static double calculateDistanceBetweenLocations(
    models.Location location1,
    models.Location location2,
  ) {
    return Geolocator.distanceBetween(
      location1.lat,
      location1.lng,
      location2.lat,
      location2.lng,
    );
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get location permission status
  Future<LocationPermission> getLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  // Calculate driving distance using Geoapify Routing API
  static Future<Map<String, dynamic>> calculateDrivingDistance(
    models.Location origin,
    models.Location destination,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v1/routing?waypoints=${origin.lat},${origin.lng}|${destination.lat},${destination.lng}&mode=drive&apiKey=$_geoapifyApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final properties = data['features'][0]['properties'];
          return {
            'distance': properties['distance']?.toDouble(),
            'duration': properties['time']?.toDouble(),
          };
        }
      }
      throw Exception('Failed to calculate driving distance');
    } catch (e) {
      debugPrint('Error calculating driving distance: $e');
      // Fallback to direct distance calculation
      final distance = calculateDistanceBetweenLocations(origin, destination);
      return {
        'distance': distance,
        'duration': (distance / 10000) * 900, // Estimate 10km/h speed
      };
    }
  }

  // Calculate dynamic fare
  static Future<double> calculateDynamicFare(
    models.Location origin,
    models.Location destination,
    String vehicleType,
  ) async {
    try {
      final distanceData = await calculateDrivingDistance(origin, destination);
      final distance = distanceData['distance'] ?? 0.0;
      
      // Base fare + (distance in km * rate per km)
      double baseFare;
      double ratePerKm;
      
      switch (vehicleType.toLowerCase()) {
        case 'bus':
          baseFare = 15.0;
          ratePerKm = 5.0;
          break;
        case 'minibus':
          baseFare = 30.0;
          ratePerKm = 10.0;
          break;
        case 'taxi':
        default:
          baseFare = 50.0;
          ratePerKm = 20.0;
      }
      
      return baseFare + ((distance / 1000) * ratePerKm);
    } catch (e) {
      debugPrint('Error calculating dynamic fare: $e');
      // Return a default fare if calculation fails
      return 50.0;
    }
  }

  // Get directions (polyline waypoints)
  static Future<List<models.Location>> getDirections(
    models.Location origin,
    models.Location destination,
  ) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v1/routing?waypoints=${origin.lat},${origin.lng}|${destination.lat},${destination.lng}&mode=drive&apiKey=$_geoapifyApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final coordinates = data['features'][0]['geometry']['coordinates'];
          return coordinates.map<models.Location>((coord) {
            return models.Location(lat: coord[1], lng: coord[0]);
          }).toList();
        }
      }
      throw Exception('Failed to get directions');
    } catch (e) {
      debugPrint('Error getting directions: $e');
      // Return a straight line between points as fallback
      return [origin, destination];
    }
  }

  // Autocomplete places (Geoapify)
  static Future<List<Prediction>> autocompletePlaces(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final url = Uri.parse(
        'https://api.geoapify.com/v1/geocode/autocomplete?text=$query&apiKey=$_geoapifyApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null) {
          return (data['features'] as List)
              .map((feature) => Prediction.fromJson(feature['properties']))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error autocompleting places: $e');
      return [];
    }
  }

  // Get place details (Geoapify)
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v1/geocode/search?text=$placeId&apiKey=$_geoapifyApiKey',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          return data['features'][0]['properties'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting place details: $e');
      return null;
    }
  }

  // Dispose resources
  void dispose() {
    stopTracking();
  }
}
