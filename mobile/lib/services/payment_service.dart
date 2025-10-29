import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'api_service.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ApiService _apiService = ApiService();
  
  // Initialize Stripe
  static Future<void> initialize() async {
    StripePayment.setOptions(
      StripeOptions(
        publishableKey: "pk_test_YOUR_STRIPE_PUBLISHABLE_KEY", // Replace with actual key
        merchantId: "YOUR_MERCHANT_ID",
        androidPayMode: 'test',
      ),
    );
  }

  // Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    String? rideId,
  }) async {
    try {
      final response = await _apiService.post(
        '/payments/create-intent',
        body: {
          'amount': (amount * 100).round(), // Convert to cents
          'currency': currency,
          'rideId': rideId,
        },
      );

      return response;
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }

  // Process payment with card
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String currency,
    String? rideId,
  }) async {
    try {
      // Create payment intent
      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: currency,
        rideId: rideId,
      );

      // For the stripe_payment package, we need to use paymentRequestWithCardForm
      // or create a token with card details first
      final creditCard = CreditCard();
      final token = await StripePayment.createTokenWithCard(creditCard);

      // Confirm payment with Stripe using the token
      final paymentResult = await StripePayment.confirmPaymentIntent(
        PaymentIntent(
          clientSecret: paymentIntent['client_secret'],
          paymentMethodId: token.tokenId, // Using tokenId as paymentMethodId
        ),
      );

      if (paymentResult.status == 'succeeded') {
        // Update ride payment status
        if (rideId != null) {
          await _updateRidePaymentStatus(rideId, 'paid', paymentResult.paymentIntentId);
        }

        return {
          'success': true,
          'paymentIntentId': paymentResult.paymentIntentId,
          'status': 'succeeded',
        };
      } else {
        throw Exception('Payment failed: ${paymentResult.status}');
      }
    } catch (e) {
      throw Exception('Payment processing failed: $e');
    }
  }

  // Add payment method
  Future<Map<String, dynamic>> addPaymentMethod({
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvc,
  }) async {
    try {
      // Create a credit card object
      final creditCard = CreditCard(
        number: cardNumber,
        expMonth: expiryMonth,
        expYear: expiryYear,
        cvc: cvc,
      );
      
      // Create a token with the card
      final token = await StripePayment.createTokenWithCard(creditCard);

      // Save payment method to backend
      final response = await _apiService.post(
        '/payments/methods',
        body: {
          'paymentMethodId': token.tokenId,
          'type': 'card',
        },
      );

      return response;
    } catch (e) {
      throw Exception('Failed to add payment method: $e');
    }
  }

  // Get saved payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final response = await _apiService.get('/payments/methods');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get payment methods: $e');
    }
  }

  // Delete payment method
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      await _apiService.delete('/payments/methods/$paymentMethodId');
    } catch (e) {
      throw Exception('Failed to delete payment method: $e');
    }
  }

  // Process refund
  Future<Map<String, dynamic>> processRefund({
    required String paymentIntentId,
    double? amount,
    String? reason,
  }) async {
    try {
      final response = await _apiService.post(
        '/payments/refund',
        body: {
          'paymentIntentId': paymentIntentId,
          'amount': amount,
          'reason': reason,
        },
      );

      return response;
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final response = await _apiService.get('/payments/history');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get payment history: $e');
    }
  }

  // Update ride payment status
  Future<void> _updateRidePaymentStatus(
    String rideId,
    String status,
    String? transactionId,
  ) async {
    try {
      await _apiService.put(
        '/rides/$rideId/payment',
        body: {
          'paymentStatus': status,
          'transactionId': transactionId,
        },
      );
    } catch (e) {
      debugPrint('Failed to update ride payment status: $e');
    }
  }

  // Validate card number
  bool validateCardNumber(String cardNumber) {
    // Remove spaces and non-digits
    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    // Check length
    if (cleaned.length < 13 || cleaned.length > 19) {
      return false;
    }

    // Luhn algorithm
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int digit = int.parse(cleaned[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }

  // Validate expiry date
  bool validateExpiryDate(int month, int year) {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    
    if (year < currentYear) return false;
    if (year == currentYear && month < currentMonth) return false;
    if (month < 1 || month > 12) return false;
    
    return true;
  }

  // Validate CVC
  bool validateCVC(String cvc) {
    final cleaned = cvc.replaceAll(RegExp(r'\D'), '');
    return cleaned.length >= 3 && cleaned.length <= 4;
  }

  // Format card number
  String formatCardNumber(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleaned[i]);
    }
    
    return buffer.toString();
  }

  // Get card type
  String getCardType(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    if (cleaned.startsWith('4')) return 'Visa';
    if (cleaned.startsWith('5') || cleaned.startsWith('2')) return 'Mastercard';
    if (cleaned.startsWith('3')) return 'American Express';
    if (cleaned.startsWith('6')) return 'Discover';
    
    return 'Unknown';
  }
}