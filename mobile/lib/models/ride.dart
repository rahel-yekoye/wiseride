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

  Ride({
    this.id,
    required this.type,
    this.riderId,
    this.driverId,
    required this.origin,
    required this.destination,
    this.fare,
    this.status = 'requested',
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
    );
  }
}
