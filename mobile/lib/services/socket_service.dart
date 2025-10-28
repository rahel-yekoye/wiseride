import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'auth_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final _authService = AuthService();
  
  // Callbacks for different events
  Function(Map<String, dynamic>)? onNewRideRequest;
  Function(Map<String, dynamic>)? onRideAccepted;
  Function(Map<String, dynamic>)? onRideStarted;
  Function(Map<String, dynamic>)? onRideCompleted;
  Function(Map<String, dynamic>)? onRideCancelled;
  Function(Map<String, dynamic>)? onDriverLocationUpdated;

  bool get isConnected => _socket?.connected ?? false;

  // Connect to Socket.io server
  Future<void> connect() async {
    if (_socket?.connected ?? false) {
      debugPrint('Socket already connected');
      return;
    }

    try {
      final token = _authService.token;
      if (token == null) {
        debugPrint('No token available for socket connection');
        return;
      }

      _socket = IO.io(
        'http://localhost:4000',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );

      _setupEventListeners();
      
      debugPrint('Socket.io connecting...');
    } catch (e) {
      debugPrint('Error connecting to socket: $e');
    }
  }

  // Setup event listeners
  void _setupEventListeners() {
    _socket?.onConnect((_) {
      debugPrint('✅ Socket.io connected');
    });

    _socket?.onDisconnect((_) {
      debugPrint('❌ Socket.io disconnected');
    });

    _socket?.onConnectError((error) {
      debugPrint('Socket connection error: $error');
    });

    _socket?.onError((error) {
      debugPrint('Socket error: $error');
    });

    // Driver events
    _socket?.on('ride:new_request', (data) {
      debugPrint('🚗 New ride request: $data');
      if (onNewRideRequest != null) {
        onNewRideRequest!(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('ride:cancelled', (data) {
      debugPrint('❌ Ride cancelled: $data');
      if (onRideCancelled != null) {
        onRideCancelled!(Map<String, dynamic>.from(data));
      }
    });

    // Rider events
    _socket?.on('ride:accepted', (data) {
      debugPrint('✅ Ride accepted: $data');
      if (onRideAccepted != null) {
        onRideAccepted!(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('ride:started', (data) {
      debugPrint('🚀 Ride started: $data');
      if (onRideStarted != null) {
        onRideStarted!(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('ride:completed', (data) {
      debugPrint('🏁 Ride completed: $data');
      if (onRideCompleted != null) {
        onRideCompleted!(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('driver:location:updated', (data) {
      debugPrint('📍 Driver location updated: $data');
      if (onDriverLocationUpdated != null) {
        onDriverLocationUpdated!(Map<String, dynamic>.from(data));
      }
    });
  }

  // Emit driver location update
  void emitDriverLocationUpdate({
    required double lat,
    required double lng,
    String? riderId,
    String? eta,
  }) {
    if (!isConnected) {
      debugPrint('Socket not connected, cannot emit location');
      return;
    }

    _socket?.emit('driver:location:update', {
      'location': {'lat': lat, 'lng': lng},
      'riderId': riderId,
      'eta': eta,
    });
  }

  // Emit driver status update
  void emitDriverStatusUpdate(bool isOnline) {
    if (!isConnected) return;
    
    _socket?.emit('driver:status:update', {
      'isOnline': isOnline,
    });
  }

  // Emit ride acceptance
  void emitRideAccept({
    required String rideId,
    required String riderId,
    required Map<String, dynamic> driverInfo,
    required DateTime estimatedArrival,
  }) {
    if (!isConnected) return;

    _socket?.emit('ride:accept', {
      'rideId': rideId,
      'riderId': riderId,
      'driverInfo': driverInfo,
      'estimatedArrival': estimatedArrival.toIso8601String(),
    });
  }

  // Emit ride start
  void emitRideStart({
    required String rideId,
    required String riderId,
  }) {
    if (!isConnected) return;

    _socket?.emit('ride:start', {
      'rideId': rideId,
      'riderId': riderId,
      'startTime': DateTime.now().toIso8601String(),
    });
  }

  // Emit ride completion
  void emitRideComplete({
    required String rideId,
    required String riderId,
    required double fare,
  }) {
    if (!isConnected) return;

    _socket?.emit('ride:complete', {
      'rideId': rideId,
      'riderId': riderId,
      'fare': fare,
      'endTime': DateTime.now().toIso8601String(),
    });
  }

  // Emit ride cancellation
  void emitRideCancel({
    required String rideId,
    String? riderId,
    String? driverId,
    String? reason,
  }) {
    if (!isConnected) return;

    _socket?.emit('ride:cancel', {
      'rideId': rideId,
      'riderId': riderId,
      'driverId': driverId,
      'reason': reason ?? 'Cancelled',
    });
  }

  // Disconnect socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint('Socket.io disconnected');
  }

  // Dispose
  void dispose() {
    disconnect();
  }
}
