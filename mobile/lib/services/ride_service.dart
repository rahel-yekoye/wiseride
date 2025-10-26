import '../models/ride.dart';
import '../models/school_contract.dart';
import 'api_service.dart';

class RideService {
  final ApiService _apiService = ApiService();

  // Create a new ride
  Future<Ride> createRide(Ride ride) async {
    try {
      final response = await _apiService.post(
        '/rides',
        body: ride.toJson(),
      );

      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create ride: $e');
    }
  }

  // Search for available rides
  Future<List<Ride>> searchAvailableRides({
    Location? origin,
    Location? destination,
    String? vehicleType,
  }) async {
    try {
      final response = await _apiService.post(
        '/rides/search',
        body: {
          if (origin != null) 'origin': origin.toJson(),
          if (destination != null) 'destination': destination.toJson(),
          if (vehicleType != null) 'vehicleType': vehicleType,
        },
      );

      if (response is List) {
        return response.map((ride) => Ride.fromJson(ride)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Failed to search available rides: $e');
    }
  }

  // Get all rides for the current user
  Future<List<Ride>> getUserRides() async {
    try {
      final response = await _apiService.get('/rides/user');

      if (response is List) {
        return response.map((ride) => Ride.fromJson(ride)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Failed to fetch user rides: $e');
    }
  }

  // Get ride by ID
  Future<Ride> getRideById(String id) async {
    try {
      final response = await _apiService.get('/rides/$id');
      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch ride: $e');
    }
  }

  // Update ride status
  Future<Ride> updateRideStatus(String rideId, String status) async {
    try {
      final response = await _apiService.put(
        '/rides/$rideId/status',
        body: {'status': status},
      );

      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update ride status: $e');
    }
  }

  // Cancel ride
  Future<Ride> cancelRide(String rideId) async {
    try {
      final response = await _apiService.put(
        '/rides/$rideId/cancel',
        body: {},
      );

      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to cancel ride: $e');
    }
  }

  // Get available rides (for drivers)
  Future<List<Ride>> getAvailableRides() async {
    try {
      final response = await _apiService.get('/rides/available');

      if (response is List) {
        return response.map((ride) => Ride.fromJson(ride)).toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Failed to fetch available rides: $e');
    }
  }

  // Accept ride (for drivers)
  Future<Ride> acceptRide(String rideId) async {
    try {
      final response = await _apiService.put(
        '/rides/$rideId/accept',
        body: {},
      );

      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to accept ride: $e');
    }
  }

  // Start ride (for drivers)
  Future<Ride> startRide(String rideId) async {
    try {
      final response = await _apiService.put(
        '/rides/$rideId/start',
        body: {},
      );

      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to start ride: $e');
    }
  }

  // End ride (for drivers)
  Future<Ride> endRide(String rideId) async {
    try {
      final response = await _apiService.put(
        '/rides/$rideId/end',
        body: {},
      );

      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to end ride: $e');
    }
  }

  // Rate ride
  Future<Ride> rateRide(String rideId, double rating, String feedback) async {
    try {
      final response = await _apiService.post(
        '/rides/$rideId/rate',
        body: {
          'rating': rating,
          'feedback': feedback,
        },
      );

      return Ride.fromJson(response);
    } catch (e) {
      throw Exception('Failed to rate ride: $e');
    }
  }

  // Get ride statistics
  Future<Map<String, dynamic>> getRideStats() async {
    try {
      final response = await _apiService.get('/rides/stats');
      return response;
    } catch (e) {
      throw Exception('Failed to fetch ride statistics: $e');
    }
  }
}