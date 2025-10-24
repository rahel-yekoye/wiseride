import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Current user state
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  
  // Getters
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Initialize auth service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      
      if (_token != null) {
        try {
          // Fetch current user data if token exists
          final userData = await _apiService.get('/users/me');
          _currentUser = User.fromJson(userData);
        } catch (e) {
          // If token is invalid, clear it
          await _clearAuthData();
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register a new user
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.post(
        '/users/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
        requiresAuth: false,
      );

      await _handleAuthResponse(response);
      return _currentUser!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login with email and password
  Future<User> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.post(
        '/users/login',
        body: {'email': email, 'password': password},
        requiresAuth: false,
      );

      await _handleAuthResponse(response);
      return _currentUser!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handle authentication response
  Future<void> _handleAuthResponse(Map<String, dynamic> response) async {
    _token = response['token'];
    _currentUser = User(
      id: response['_id'] ?? '',
      name: response['name'] ?? '',
      email: response['email'] ?? '',
      role: response['role'] ?? '',
    );
    
    // Save token to secure storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    
    notifyListeners();
  }

  // Logout the current user
  Future<void> logout() async {
    try {
      // Just clear local data since we don't have a backend logout endpoint
      await _clearAuthData();
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Still clear local data even if there's an error
      await _clearAuthData();
    }
  }

  // Clear all authentication data
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    _token = null;
    _currentUser = null;
    
    notifyListeners();
  }

  // Check authentication status with async verification
  Future<bool> checkAuthentication() async {
    if (_token != null) return true;
    
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.containsKey('auth_token');
    
    if (hasToken) {
      try {
        await refreshUser();
        return _currentUser != null;
      } catch (e) {
        await _clearAuthData();
        return false;
      }
    }
    
    return false;
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (_token == null) return;
    
    try {
      final userData = await _apiService.get('/users/me');
      _currentUser = User.fromJson(userData);
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
      await _clearAuthData();
    }
  }
}