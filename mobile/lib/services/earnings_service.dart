import 'api_service.dart';

class EarningsService {
  final _apiService = ApiService();

  // Process ride earnings
  Future<Map<String, dynamic>> processRideEarnings({
    required String rideId,
    required double totalFare,
  }) async {
    final response = await _apiService.post(
      '/earnings/process',
      body: {
        'rideId': rideId,
        'totalFare': totalFare,
      },
    );
    return response;
  }

  // Get earnings summary
  Future<Map<String, dynamic>> getEarningsSummary() async {
    final response = await _apiService.get('/earnings/summary');
    return response;
  }

  // Get transaction history
  Future<Map<String, dynamic>> getTransactionHistory({
    int page = 1,
    int limit = 20,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (type != null) 'type': type,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final response = await _apiService.get(
      '/earnings/transactions',
      queryParams: queryParams,
    );
    return response;
  }

  // Request payout
  Future<Map<String, dynamic>> requestPayout({
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? bankDetails,
    Map<String, dynamic>? mobileMoneyDetails,
  }) async {
    final response = await _apiService.post(
      '/earnings/payout/request',
      body: {
        'amount': amount,
        'paymentMethod': paymentMethod,
        if (bankDetails != null) 'bankDetails': bankDetails,
        if (mobileMoneyDetails != null) 'mobileMoneyDetails': mobileMoneyDetails,
      },
    );
    return response;
  }

  // Get payout history
  Future<Map<String, dynamic>> getPayoutHistory({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    };

    final response = await _apiService.get(
      '/earnings/payout/history',
      queryParams: queryParams,
    );
    return response;
  }
}
