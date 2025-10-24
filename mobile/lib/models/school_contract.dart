class Child {
  final String name;
  final String grade;
  final Location? pickupPoint;
  final Location? dropPoint;

  Child({
    required this.name,
    required this.grade,
    this.pickupPoint,
    this.dropPoint,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grade': grade,
      'pickupPoint': pickupPoint?.toJson(),
      'dropPoint': dropPoint?.toJson(),
    };
  }

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      name: json['name'] ?? '',
      grade: json['grade'] ?? '',
      pickupPoint: json['pickupPoint'] != null ? Location.fromJson(json['pickupPoint']) : null,
      dropPoint: json['dropPoint'] != null ? Location.fromJson(json['dropPoint']) : null,
    );
  }
}

class Location {
  final double lat;
  final double lng;
  final String address;

  Location({required this.lat, required this.lng, required this.address});

  Map<String, dynamic> toJson() {
    return {'lat': lat, 'lng': lng, 'address': address};
  }

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      lat: json['lat']?.toDouble() ?? 0.0,
      lng: json['lng']?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
    );
  }
}

class Schedule {
  final List<String> days;
  final String pickupTime;
  final String returnTime;

  Schedule({
    required this.days,
    required this.pickupTime,
    required this.returnTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'pickupTime': pickupTime,
      'returnTime': returnTime,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      days: List<String>.from(json['days'] ?? []),
      pickupTime: json['pickupTime'] ?? '',
      returnTime: json['returnTime'] ?? '',
    );
  }
}

class SchoolContract {
  final String? id;
  final String parentId;
  final String? driverId;
  final List<Child> children;
  final Schedule schedule;
  final double monthlyFee;
  final String status;

  SchoolContract({
    this.id,
    required this.parentId,
    this.driverId,
    required this.children,
    required this.schedule,
    required this.monthlyFee,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'parentId': parentId,
      'driverId': driverId,
      'children': children.map((c) => c.toJson()).toList(),
      'schedule': schedule.toJson(),
      'monthlyFee': monthlyFee,
      'status': status,
    };
  }

  factory SchoolContract.fromJson(Map<String, dynamic> json) {
    return SchoolContract(
      id: json['_id'],
      parentId: json['parentId'] ?? '',
      driverId: json['driverId'],
      children: (json['children'] as List? ?? []).map((c) => Child.fromJson(c)).toList(),
      schedule: Schedule.fromJson(json['schedule'] ?? {}),
      monthlyFee: json['monthlyFee']?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
    );
  }
}
