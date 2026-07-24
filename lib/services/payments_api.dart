import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';

class RazorpayOrder {
  final String orderId;
  final int amountPaise;
  final String currency;
  final String keyId;

  const RazorpayOrder({
    required this.orderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
  });

  factory RazorpayOrder.fromJson(Map<String, dynamic> json) => RazorpayOrder(
        orderId: json['orderId'] as String,
        amountPaise: json['amount'] as int,
        currency: json['currency'] as String,
        keyId: json['keyId'] as String,
      );
}

class PaymentsApi {
  PaymentsApi._();

  /// Creates a Razorpay order for the given rupee amount.
  static Future<RazorpayOrder> createOrder({required double amountRupees, String? receipt}) async {
    final response = await _post('/payments/order', {
      'amount': amountRupees,
      if (receipt != null) 'receipt': receipt,
    });
    return RazorpayOrder.fromJson(_decode(response));
  }

  /// Verifies a completed payment's signature with the backend.
  static Future<bool> verify({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await _post('/payments/verify', {
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
    });
    return _decode(response)['verified'] as bool? ?? false;
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(data['message'] as String? ?? 'Something went wrong. Please try again.');
    }
    return data;
  }

  static Future<String> _idToken() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw ApiException('Not signed in');
    }
    return (await firebaseUser.getIdToken())!;
  }

  static Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    try {
      final idToken = await _idToken();
      return await http
          .post(
            Uri.parse('$apiBaseUrl$path'),
            headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection and try again.');
    }
  }
}
