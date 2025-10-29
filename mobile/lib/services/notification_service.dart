import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
<<<<<<< HEAD
import 'package:permission_handler/permission_handler.dart';
=======

// Conditional import for Firebase messaging - only import on mobile platforms
// This should help avoid web compatibility issues
// import 'package:firebase_messaging/firebase_messaging.dart'
//    if (dart.library.io) 'package:firebase_messaging/firebase_messaging.dart'
//    if (dart.library.html) 'package:firebase_messaging/firebase_messaging.dart';
>>>>>>> origin/rita

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

<<<<<<< HEAD
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
=======
  // FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  final StreamController<Map<String, dynamic>> _notificationController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  // Initialize notification service
  Future<void> initialize() async {
    try {
      await _initializeLocalNotifications();
      // Only initialize Firebase messaging on mobile platforms
      // if (!kIsWeb) {
      //   await _initializeFirebaseMessaging();
      // }
>>>>>>> origin/rita
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

<<<<<<< HEAD
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
=======
  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Initialize Firebase messaging (skip on web for now)
  // Future<void> _initializeFirebaseMessaging() async {
  //   try {
  //     _firebaseMessaging = FirebaseMessaging.instance;
  //     
  //     // Request permission for iOS
  //     await _firebaseMessaging!.requestPermission(
  //       alert: true,
  //       badge: true,
  //       sound: true,
  //     );
  //
  //     // Get FCM token
  //     String? token = await _firebaseMessaging!.getToken();
  //     debugPrint('FCM Token: $token');
  //
  //     // Handle background messages
  //     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  //
  //     // Handle foreground messages
  //     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  //
  //     // Handle notification taps when app is in background
  //     FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  //   } catch (e) {
  //     debugPrint('Firebase messaging initialization error: $e');
  //   }
  // }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      _notificationController.add({'type': 'tap', 'payload': payload});
    }
  }

  // Handle foreground messages
  // Future<void> _handleForegroundMessage(RemoteMessage message) async {
  //   debugPrint('Received foreground message: ${message.messageId}');
  //   
  //   // Show local notification for foreground messages
  //   await _showLocalNotification(
  //     title: message.notification?.title ?? 'WiseRide',
  //     body: message.notification?.body ?? '',
  //     payload: message.data.toString(),
  //   );
  //
  //   // Add to stream
  //   _notificationController.add({
  //     'type': 'foreground',
  //     'data': message.data,
  //     'notification': message.notification?.toMap(),
  //   });
  // }

  // Handle notification tap
  // Future<void> _handleNotificationTap(RemoteMessage message) async {
  //   debugPrint('Notification tapped: ${message.messageId}');
  //   
  //   _notificationController.add({
  //     'type': 'tap',
  //     'data': message.data,
  //     'notification': message.notification?.toMap(),
  //   });
  // }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'wiseride_channel',
      'WiseRide Notifications',
      channelDescription: 'Notifications for ride updates',
>>>>>>> origin/rita
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

<<<<<<< HEAD
    const details = NotificationDetails(
=======
    const notificationDetails = NotificationDetails(
>>>>>>> origin/rita
      android: androidDetails,
      iOS: iosDetails,
    );

<<<<<<< HEAD
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
=======
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // In a real implementation, you would send this to your backend
    // which would then send the notification via FCM
    debugPrint('Sending notification to user $userId: $title');
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    // if (!kIsWeb && _firebaseMessaging != null) {
    //   try {
    //     await _firebaseMessaging!.subscribeToTopic(topic);
    //     debugPrint('Subscribed to topic: $topic');
    //   } catch (e) {
    //     debugPrint('Error subscribing to topic: $e');
    //   }
    // }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    // if (!kIsWeb && _firebaseMessaging != null) {
    //   try {
    //     await _firebaseMessaging!.unsubscribeFromTopic(topic);
    //     debugPrint('Unsubscribed from topic: $topic');
    //   } catch (e) {
    //     debugPrint('Error unsubscribing from topic: $e');
    //   }
    // }
  }

  // Get FCM token
  Future<String?> getToken() async {
    // if (!kIsWeb && _firebaseMessaging != null) {
    //   try {
    //     return await _firebaseMessaging!.getToken();
    //   } catch (e) {
    //     debugPrint('Error getting FCM token: $e');
    //     return null;
    //   }
    // }
    return null;
  }

  // Show ride status notification
  Future<void> showRideStatusNotification({
    required String status,
    required String rideId,
    String? driverName,
    String? vehicleInfo,
  }) async {
    String title;
    String body;

    switch (status) {
      case 'accepted':
        title = 'Ride Accepted!';
        body = driverName != null 
            ? 'Your ride has been accepted by $driverName'
            : 'Your ride has been accepted';
        break;
      case 'in_progress':
        title = 'Ride Started';
        body = 'Your driver is on the way to pick you up';
        break;
      case 'completed':
        title = 'Ride Completed';
        body = 'Thank you for using WiseRide!';
        break;
      case 'cancelled':
        title = 'Ride Cancelled';
        body = 'Your ride has been cancelled';
        break;
      default:
        title = 'Ride Update';
        body = 'Your ride status has been updated';
    }

    await _showLocalNotification(
      title: title,
      body: body,
      payload: 'ride_$rideId',
    );
  }

  // Show driver notification
  Future<void> showDriverNotification({
    required String title,
    required String body,
    required String rideId,
  }) async {
    await _showLocalNotification(
      title: title,
      body: body,
      payload: 'driver_$rideId',
    );
  }

  // Dispose
  void dispose() {
    _notificationController.close();
  }
}

// Background message handler
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   debugPrint('Handling background message: ${message.messageId}');
// }
>>>>>>> origin/rita
