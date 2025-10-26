import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
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
  static const String _geoapifyApiKey = 'f4d95417cd5045a5abcdd07cb182e643';

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

      String address =
          await _reverseGeocode(position.latitude, position.longitude);

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

  // Geocode address to coordinates (Geoapify)
  static Future<models.Location> geocodeAddress(String address) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v1/geocode/search?text=${Uri.encodeComponent(address)}&apiKey=$_geoapifyApiKey',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['features'] != null && data['features'].isNotEmpty) {
        final location = data['features'][0]['geometry']['coordinates'];
        final props = data['features'][0]['properties'];

        return models.Location(
          lat: location[1].toDouble(),
          lng: location[0].toDouble(),
          address: props['formatted'] ?? address,
        );
      } else {
        throw Exception('Address not found');
      }
    } catch (e) {
      debugPrint('Geoapify geocode error: $e');
      return models.Location(
        lat: 9.0367,
        lng: 38.7412,
        address: address,
      );
    }
  }

  // Reverse geocode coordinates to address (Geoapify)
  static Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v1/geocode/reverse?lat=$lat&lon=$lng&apiKey=$_geoapifyApiKey',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['features'] != null && data['features'].isNotEmpty) {
        return data['features'][0]['properties']['formatted'] ??
            'Unknown location';
      } else {
        return 'Unknown location';
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
      return 'Unknown location';
    }
  }

  // Calculate straight-line distance
  static double calculateDistance(
      models.Location location1, models.Location location2) {
    return Geolocator.distanceBetween(
          location1.lat,
          location1.lng,
          location2.lat,
          location2.lng,
        ) /
        1000;
  }

  // Calculate driving distance using Geoapify Routing API
  static Future<Map<String, dynamic>> calculateDrivingDistance(
      models.Location origin, models.Location destination) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v1/routing?waypoints=${origin.lat},${origin.lng}|${destination.lat},${destination.lng}&mode=drive&apiKey=$_geoapifyApiKey',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['features'] != null && data['features'].isNotEmpty) {
        final props = data['features'][0]['properties'];
        final distance = props['distance'] / 1000; // km
        final duration = props['time'] / 60; // minutes

        return {
          'distance': distance,
          'duration': duration,
          'status': 'success',
        };
      } else {
        return {
          'distance': calculateDistance(origin, destination),
          'duration': 0,
          'status': 'fallback',
        };
      }
    } catch (e) {
      debugPrint('Routing error: $e');
      return {
        'distance': calculateDistance(origin, destination),
        'duration': 0,
        'status': 'error',
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
      final distance = distanceData['distance'] as double;

      const baseFares = {
        'bus': 2.50,
        'taxi': 5.00,
        'minibus': 4.00,
        'private_car': 6.00,
      };

      const perKmRates = {
        'bus': 0.50,
        'taxi': 1.20,
        'minibus': 0.80,
        'private_car': 1.50,
      };

      final baseFare = baseFares[vehicleType] ?? 5.00;
      final perKmRate = perKmRates[vehicleType] ?? 1.00;

      final effectiveDistance = distance < 1.0 ? 1.0 : distance;
      final totalFare = baseFare + (effectiveDistance * perKmRate);

      return totalFare;
    } catch (e) {
      debugPrint('Fare calculation error: $e');
      final distance = calculateDistance(origin, destination);
      return 5.00 + (distance * 1.00);
    }
  }

  // Get directions (polyline waypoints)
  static Future<List<models.Location>> getDirections(
      models.Location origin, models.Location destination) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v1/routing?waypoints=${origin.lat},${origin.lng}|${destination.lat},${destination.lng}&mode=drive&apiKey=$_geoapifyApiKey',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['features'] != null && data['features'].isNotEmpty) {
        final coords = data['features'][0]['geometry']['coordinates'][0];
        List<models.Location> waypoints = coords
            .map<models.Location>((c) => models.Location(
                  lat: c[1].toDouble(),
                  lng: c[0].toDouble(),
                  address: '',
                ))
            .toList();
        return waypoints;
      } else {
        return [origin, destination];
      }
    } catch (e) {
      debugPrint('Directions error: $e');
      return [origin, destination];
    }
  }

  // Autocomplete places (Geoapify)
  static Future<List<Prediction>> getPlacePredictions(String query) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v1/geocode/autocomplete?text=${Uri.encodeComponent(query)}&apiKey=$_geoapifyApiKey',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['features'] != null && data['features'].isNotEmpty) {
        return (data['features'] as List)
            .map((f) => Prediction(
                  placeId: f['properties']['place_id'] ?? '',
                  description: f['properties']['formatted'] ?? '',
                ))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Autocomplete error: $e');
      return [];
    }
  }

  // Get place details (Geoapify)
  static Future<models.Location> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://api.geoapify.com/v2/place-details?id=$placeId&apiKey=$_geoapifyApiKey',
      );

      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['features'] != null && data['features'].isNotEmpty) {
        final feature = data['features'][0];
        final coords = feature['geometry']['coordinates'];
        final props = feature['properties'];

        return models.Location(
          lat: coords[1].toDouble(),
          lng: coords[0].toDouble(),
          address: props['formatted'] ?? 'Unknown place',
        );
      } else {
        throw Exception('Place not found');
      }
    } catch (e) {
      debugPrint('Place details error: $e');
      return models.Location(
        lat: 9.0367,
        lng: 38.7412,
        address: 'Addis Ababa, Ethiopia',
      );
    }
  }
}
