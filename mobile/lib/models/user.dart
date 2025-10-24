class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final bool? driverVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.driverVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'] as String?,
      driverVerified: json['driverVerified'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
    };
  }
}