import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final BehaviorSubject<String?> _notificationController = BehaviorSubject<String?>();
  
  factory NotificationService() => _instance;
  NotificationService._internal();

  Stream<String?> get onNotificationClicked => _notificationController.stream;

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  // Notification details
  static const AndroidNotificationDetails _androidNotificationDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.high,
    priority: Priority.high,
    ticker: 'ticker',
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidNotificationDetails,
  );

  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Request notification permissions
    if (Platform.isIOS) {
      await _requestIOSPermissions();
    } else if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }
    
    // Initialize notification plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: (id, title, body, payload) {
        _notificationController.add(payload);
      },
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    // Initialize the plugin
    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _notificationController.add(response.payload);
      },
    );
    
    // Create notification channel for Android 8.0+
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  Future<void> _requestAndroidPermissions() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }
  
  Future<void> _requestIOSPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }
  
  Future<void> showDriverNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _notificationDetails,
      payload: payload,
    );
  }

  // Get notification launch details
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async {
    return await _notifications.getNotificationAppLaunchDetails();
  }
  
  void dispose() {
    _notificationController.close();
  }
}