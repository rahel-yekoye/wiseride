import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/rider_home_screen.dart';
import 'screens/parent_home_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/admin_home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthService()..initialize(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiseRide',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authService.currentUser != null) {
      // Navigate to role-specific home screen
      switch (authService.currentUser!.role) {
        case 'rider':
          return const RiderHomeScreen();
        case 'parent':
          return const ParentHomeScreen();
        case 'driver':
          return const DriverHomeScreen();
        case 'admin':
          return const AdminHomeScreen();
        default:
          return const RiderHomeScreen(); // Default to rider screen
      }
    }

    return const LoginScreen();
  }
}