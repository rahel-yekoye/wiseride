import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum ContentType { json, formData, multipart }

class ApiService {
  static const String baseUrl = 'http://localhost:4000/api';
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get request with query parameters
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
    String? customBaseUrl,
  }) async {
    return await _request(
      'GET',
      endpoint,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
      customBaseUrl: customBaseUrl,
    );
  }

  // Post request with body
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
    ContentType contentType = ContentType.json,
    String? customBaseUrl,
  }) async {
    return await _request(
      'POST',
      endpoint,
      body: body,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
      contentType: contentType,
      customBaseUrl: customBaseUrl,
    );
  }

  // Put request
  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
    ContentType contentType = ContentType.json,
  }) async {
    return await _request(
      'PUT',
      endpoint,
      body: body,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
      contentType: contentType,
    );
  }

  // Delete request
  Future<dynamic> delete(
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    return await _request(
      'DELETE',
      endpoint,
      body: body,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
    );
  }

  // Main request handler
  Future<dynamic> _request(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
    ContentType contentType = ContentType.json,
    String? customBaseUrl,
  }) async {
    // Build URL
    final uri = _buildUri(endpoint, queryParams, customBaseUrl);
    
    // Prepare headers
    final headers = await _buildHeaders(requiresAuth, contentType);
    
    // Log request
    _logRequest(method, uri, headers, body);
    
    try {
      // Make the request
      final response = await _makeRequest(
        method,
        uri,
        headers,
        body,
        contentType,
      ).timeout(
        const Duration(milliseconds: connectTimeout),
      );

      // Handle response
      return _handleResponse(response);
    } catch (e) {
      _logError(e);
      rethrow;
    }
  }

  // Build URI with query parameters
  Uri _buildUri(
    String endpoint, 
    Map<String, dynamic>? queryParams,
    String? customBaseUrl,
  ) {
    final base = customBaseUrl ?? baseUrl;
    final uri = Uri.parse('$base$endpoint');
    
    if (queryParams != null) {
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParams.map((key, value) => MapEntry(key, value.toString())),
      });
    }
    
    return uri;
  }

  // Build request headers
  Future<Map<String, String>> _buildHeaders(
    bool requiresAuth, 
    ContentType contentType,
  ) async {
    final headers = Map<String, String>.from(_defaultHeaders);
    
    // Set content type
    switch (contentType) {
      case ContentType.json:
        headers['Content-Type'] = 'application/json';
        break;
      case ContentType.formData:
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
        break;
      case ContentType.multipart:
        // Content-Type will be set automatically for multipart requests
        headers.remove('Content-Type');
        break;
    }
    
    // Add auth token if required
    if (requiresAuth) {
      final token = await _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  // Make the actual HTTP request
  Future<http.Response> _makeRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    dynamic body,
    ContentType contentType,
  ) async {
    if (contentType == ContentType.multipart && body is http.MultipartRequest) {
      // Handle multipart requests (for file uploads)
      return http.Response.fromStream(await body.send());
    }

    // Handle other request types
    switch (method) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: contentType == ContentType.json ? jsonEncode(body) : body,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: contentType == ContentType.json ? jsonEncode(body) : body,
        );
      case 'DELETE':
        return await http.delete(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    _logResponse(response);
    
    final statusCode = response.statusCode;
    final responseBody = response.body;
    
    // Handle empty response
    if (responseBody.isEmpty) {
      return null;
    }
    
    // Parse JSON response
    final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
    
    // Handle success responses (2xx)
    if (statusCode >= 200 && statusCode < 300) {
      return jsonResponse;
    }
    
    // Handle error responses
    final errorMessage = jsonResponse['message'] ?? 'Request failed with status: $statusCode';
    
    switch (statusCode) {
      case 400:
        throw BadRequestException(errorMessage);
      case 401:
        throw UnauthorizedException(errorMessage);
      case 403:
        throw ForbiddenException(errorMessage);
      case 404:
        throw NotFoundException(errorMessage);
      case 422:
        throw ValidationException(errorMessage, jsonResponse['errors']);
      case 500:
        throw ServerException(errorMessage);
      default:
        throw ApiException('Request failed with status: $statusCode');
    }
  }

  // Get auth token from secure storage
  Future<String?> _getAuthToken() async {
    // In a real app, you might want to use a secure storage solution
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Logging helpers
  void _logRequest(String method, Uri uri, Map<String, String> headers, dynamic body) {
    if (!kDebugMode) return;
    
    log('\n=== API Request ===', name: 'API');
    log('$method $uri', name: 'API');
    log('Headers: $headers', name: 'API');
    
    if (body != null) {
      if (body is Map || body is List) {
        log('Body: ${const JsonEncoder.withIndent('  ').convert(body)}', name: 'API');
      } else {
        log('Body: $body', name: 'API');
      }
    }
  }

  void _logResponse(http.Response response) {
    if (!kDebugMode) return;
    
    final statusCode = response.statusCode;
    final isSuccess = statusCode >= 200 && statusCode < 300;
    final emoji = isSuccess ? '✅' : '❌';
    
    log('\n=== API Response $emoji ===', name: 'API');
    log('Status: $statusCode', name: 'API');
    
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      log('Body: ${const JsonEncoder.withIndent('  ').convert(json)}', name: 'API');
    } catch (e) {
      log('Body: ${response.body}', name: 'API');
    }
  }

  void _logError(dynamic error) {
    if (!kDebugMode) return;
    
    log('\n=== API Error ===', name: 'API');
    log('Error: $error', name: 'API');
    if (error is Error) {
      log('Stack trace: ${error.stackTrace}', name: 'API');
    }
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}

class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class ValidationException extends ApiException {
  final dynamic errors;
  
  ValidationException(super.message, this.errors);
  
  @override
  String toString() => 'ValidationException: $message\nErrors: $errors';
}

class ServerException extends ApiException {
  ServerException(super.message);
}
