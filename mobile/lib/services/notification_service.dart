import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    try {
      // Request notification permission
      final status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        debugPrint('Notification permission denied');
        return;
      }

      // Initialize Android settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Initialize iOS settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
    _handleNotificationNavigation(response.payload);
  }

  // Handle navigation based on notification payload
  void _handleNotificationNavigation(String? payload) {
    if (payload == null) return;

    switch (payload) {
      case 'new_ride':
        // Navigate to available rides screen
        break;
      case 'ride_accepted':
        // Navigate to ride details
        break;
      case 'ride_started':
        // Navigate to active ride screen
        break;
      default:
        break;
    }
  }

  // Show new ride notification
  Future<void> showNewRideNotification({
    required String riderName,
    required String pickupLocation,
    required String destination,
    required String rideId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ride_requests',
      'Ride Requests',
      channelDescription: 'Notifications for new ride requests',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      rideId.hashCode,
      'New Ride Request',
      '$riderName wants a ride from $pickupLocation to $destination',
      details,
      payload: 'new_ride',
    );
  }

  // Show ride accepted notification
  Future<void> showRideAcceptedNotification({
    required String driverName,
    required String vehicleInfo,
    required String rideId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ride_updates',
      'Ride Updates',
      channelDescription: 'Notifications for ride status updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      rideId.hashCode,
      'Ride Accepted',
      '$driverName is coming to pick you up in $vehicleInfo',
      details,
      payload: 'ride_accepted',
    );
  }

  // Show ride started notification
  Future<void> showRideStartedNotification({
    required String driverName,
    required String rideId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ride_updates',
      'Ride Updates',
      channelDescription: 'Notifications for ride status updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      rideId.hashCode,
      'Ride Started',
      'Your ride with $driverName has started',
      details,
      payload: 'ride_started',
    );
  }

  // Show ride completed notification
  Future<void> showRideCompletedNotification({
    required String fare,
    required String rideId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ride_updates',
      'Ride Updates',
      channelDescription: 'Notifications for ride status updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      rideId.hashCode,
      'Ride Completed',
      'Your ride has been completed. Fare: ETB $fare',
      details,
      payload: 'ride_completed',
    );
  }

  // Show earnings notification
  Future<void> showEarningsNotification({
    required String todayEarnings,
    required String totalRides,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'earnings',
      'Earnings',
      channelDescription: 'Notifications for daily earnings',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch,
      'Daily Earnings',
      'You earned ETB $todayEarnings from $totalRides rides today!',
      details,
      payload: 'earnings',
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Dispose resources
  void dispose() {}
}
