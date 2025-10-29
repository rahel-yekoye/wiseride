import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _userId;
  
  // Stream controllers for different types of events
  final StreamController<Map<String, dynamic>> _rideUpdatesController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _driverLocationController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _generalUpdatesController = StreamController.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get rideUpdatesStream => _rideUpdatesController.stream;
  Stream<Map<String, dynamic>> get driverLocationStream => _driverLocationController.stream;
  Stream<Map<String, dynamic>> get generalUpdatesStream => _generalUpdatesController.stream;

  bool get isConnected => _isConnected;

  // Initialize WebSocket connection
  Future<void> initialize({required String userId}) async {
    _userId = userId;
    
    try {
      _socket = IO.io(
        'http://localhost:5000', // Replace with your backend URL
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      _setupEventListeners();
      
      // Connect to user-specific room
      _socket?.emit('join_user_room', {'userId': userId});
      
      _isConnected = true;
      debugPrint('WebSocket connected for user: $userId');
    } catch (e) {
      debugPrint('Failed to initialize WebSocket: $e');
      _isConnected = false;
    }
  }

  // Setup event listeners
  void _setupEventListeners() {
    _socket?.onConnect((_) {
      debugPrint('WebSocket connected');
      _isConnected = true;
      
      // Rejoin user room if userId is available
      if (_userId != null) {
        _socket?.emit('join_user_room', {'userId': _userId});
      }
    });

    _socket?.onDisconnect((_) {
      debugPrint('WebSocket disconnected');
      _isConnected = false;
    });

    _socket?.onConnectError((error) {
      debugPrint('WebSocket connection error: $error');
      _isConnected = false;
    });

    // Ride-related events
    _socket?.on('ride_accepted', (data) {
      debugPrint('Ride accepted: $data');
      _rideUpdatesController.add({
        'type': 'ride_accepted',
        'data': data,
      });
    });

    _socket?.on('ride_started', (data) {
      debugPrint('Ride started: $data');
      _rideUpdatesController.add({
        'type': 'ride_started',
        'data': data,
      });
    });

    _socket?.on('ride_completed', (data) {
      debugPrint('Ride completed: $data');
      _rideUpdatesController.add({
        'type': 'ride_completed',
        'data': data,
      });
    });

    _socket?.on('ride_cancelled', (data) {
      debugPrint('Ride cancelled: $data');
      _rideUpdatesController.add({
        'type': 'ride_cancelled',
        'data': data,
      });
    });

    // Driver location updates
    _socket?.on('driver_location_update', (data) {
      debugPrint('Driver location update: $data');
      _driverLocationController.add({
        'type': 'driver_location_update',
        'data': data,
      });
    });

    // General updates
    _socket?.on('general_update', (data) {
      debugPrint('General update: $data');
      _generalUpdatesController.add({
        'type': 'general_update',
        'data': data,
      });
    });

    // Error handling
    _socket?.onError((error) {
      debugPrint('WebSocket error: $error');
    });
  }

  // Send ride request
  Future<void> sendRideRequest({
    required String rideId,
    required Map<String, dynamic> rideData,
  }) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('ride_request', {
        'rideId': rideId,
        'data': rideData,
      });
      debugPrint('Ride request sent: $rideId');
    } else {
      debugPrint('WebSocket not connected, cannot send ride request');
    }
  }

  // Send driver location update
  Future<void> sendDriverLocation({
    required String rideId,
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
  }) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('driver_location_update', {
        'rideId': rideId,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'heading': heading,
          'speed': speed,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    }
  }

  // Send rider location update
  Future<void> sendRiderLocation({
    required String rideId,
    required double latitude,
    required double longitude,
  }) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('rider_location_update', {
        'rideId': rideId,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    }
  }

  // Join ride room for real-time updates
  Future<void> joinRideRoom(String rideId) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('join_ride_room', {'rideId': rideId});
      debugPrint('Joined ride room: $rideId');
    }
  }

  // Leave ride room
  Future<void> leaveRideRoom(String rideId) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave_ride_room', {'rideId': rideId});
      debugPrint('Left ride room: $rideId');
    }
  }

  // Send message to driver
  Future<void> sendMessageToDriver({
    required String rideId,
    required String message,
  }) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('message_to_driver', {
        'rideId': rideId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  // Send message to rider
  Future<void> sendMessageToRider({
    required String rideId,
    required String message,
  }) async {
    if (_socket != null && _isConnected) {
      _socket!.emit('message_to_rider', {
        'rideId': rideId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  // Listen for messages
  void listenForMessages(Function(Map<String, dynamic>) onMessage) {
    _socket?.on('message', (data) {
      onMessage(data);
    });
  }

  // Reconnect if disconnected
  Future<void> reconnect() async {
    if (_socket != null && !_isConnected) {
      _socket!.connect();
    }
  }

  // Disconnect
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      debugPrint('WebSocket disconnected and disposed');
    }
  }

  // Dispose all resources
  void dispose() {
    disconnect();
    _rideUpdatesController.close();
    _driverLocationController.close();
    _generalUpdatesController.close();
  }
}
