import 'api_service.dart';

class RegistrationService {
  final _apiService = ApiService();

  // Start driver registration
  Future<Map<String, dynamic>> startRegistration({
    required Map<String, dynamic> vehicleInfo,
    Map<String, dynamic>? bankDetails,
    Map<String, dynamic>? mobileMoneyDetails,
    List<String>? serviceAreas,
    Map<String, dynamic>? availabilitySchedule,
  }) async {
    final response = await _apiService.post(
      '/registration/start',
      body: {
        'vehicleInfo': vehicleInfo,
        if (bankDetails != null) 'bankDetails': bankDetails,
        if (mobileMoneyDetails != null) 'mobileMoneyDetails': mobileMoneyDetails,
        if (serviceAreas != null) 'serviceAreas': serviceAreas,
        if (availabilitySchedule != null) 'availabilitySchedule': availabilitySchedule,
      },
    );
    return response;
  }

  // Upload document
  Future<Map<String, dynamic>> uploadDocument({
    required String documentType,
    required String documentUrl,
    String? documentNumber,
    DateTime? expiryDate,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _apiService.post(
      '/registration/documents',
      body: {
        'documentType': documentType,
        'documentUrl': documentUrl,
        if (documentNumber != null) 'documentNumber': documentNumber,
        if (expiryDate != null) 'expiryDate': expiryDate.toIso8601String(),
        if (metadata != null) 'metadata': metadata,
      },
    );
    return response;
  }

  // Get uploaded documents
  Future<List<dynamic>> getDocuments() async {
    final response = await _apiService.get('/registration/documents');
    return response as List<dynamic>;
  }

  // Submit for review
  Future<Map<String, dynamic>> submitForReview() async {
    final response = await _apiService.post('/registration/submit');
    return response;
  }

  // Get registration status
  Future<Map<String, dynamic>> getRegistrationStatus() async {
    final response = await _apiService.get('/registration/status');
    return response;
  }
}
