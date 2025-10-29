import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'driver_dashboard_screen.dart';
import 'driver_available_rides_screen.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return const DriverDashboardScreen();
      },
    );
  }
}