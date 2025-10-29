import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/location_service.dart';
import 'screens/login_screen.dart';
import 'screens/rider_home_screen.dart';
import 'screens/parent_home_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize services
    await _initializeServices();
    
    runApp(
      ChangeNotifierProvider(
        create: (context) => AuthService()..initialize(),
        child: const MyApp(),
      ),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
    runApp(const ErrorApp());
  }
}

Future<void> _initializeServices() async {
  try {
    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();
    
    // Handle notification taps
    final notificationAppLaunchDetails = await notificationService.getNotificationAppLaunchDetails();
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      // The notification tap will be handled by the onSelectNotification callback
    }
    
    // Initialize location service (skip on web)
    if (!kIsWeb) {
      await LocationService.initialize();
    }
  } catch (e) {
    debugPrint('Error initializing services: $e');
    // Continue running the app even if services fail to initialize
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Oops! Something went wrong.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Please try again later.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Try to restart the app
                  runApp(
                    ChangeNotifierProvider(
                      create: (context) => AuthService()..initialize(),
                      child: const MyApp(),
                    ),
                  );
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
      debugShowCheckedModeBanner: false, // Remove debug banner
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