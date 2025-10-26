import 'school_contract.dart';

class Ride {
  final String? id;
  final String type;
  final String? riderId;
  final String? driverId;
  final Location origin;
  final Location destination;
  final double? fare;
  final String status;
  final String? vehicleType;
  final List<Location>? route; // Add this field
  final DateTime? createdAt; // Add this field

  Ride({
    this.id,
    required this.type,
    this.riderId,
    this.driverId,
    required this.origin,
    required this.destination,
    this.fare,
    this.status = 'requested',
    this.vehicleType,
    this.route, // Add this parameter
    this.createdAt, // Add this parameter
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'riderId': riderId,
      'driverId': driverId,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'fare': fare,
      'status': status,
      'vehicleType': vehicleType,
      'route': route?.map((location) => location.toJson()).toList(), // Add this line
      'createdAt': createdAt?.toIso8601String(), // Add this line
    };
  }

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['_id'],
      type: json['type'] ?? 'public',
      riderId: json['riderId'],
      driverId: json['driverId'],
      origin: Location.fromJson(json['origin'] ?? {}),
      destination: Location.fromJson(json['destination'] ?? {}),
      fare: json['fare']?.toDouble(),
      status: json['status'] ?? 'requested',
      vehicleType: json['vehicleType'],
      route: (json['route'] as List?)
          ?.map((item) => Location.fromJson(item))
          .toList(), // Add this line
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null, // Add this line
    );
  }
}