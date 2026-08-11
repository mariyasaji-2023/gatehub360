import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/property_announcement.dart';
import '../models/rent_payment.dart';
import 'api_config.dart';
import 'auth_service.dart';

/// Tenant-side self-service rent endpoints — a signed-in `tenant` role user
/// only sees rentals for tenant records they've linked to their account by
/// entering the owner-shared join code (see backend/routes/rent.js).
class RentApi {
  RentApi._();

  static Future<List<MyRental>> fetchMyRentals() async {
    final response = await _get('/my-rent');
    final rentals = _decode(response)['rentals'] as List;
    return rentals.map((j) => MyRental.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Links the signed-in user's account to whichever tenant record the
  /// owner created with this join code. When `propertyId` is given (e.g.
  /// entered on a specific property's detail page), the backend rejects a
  /// code that belongs to a different property. Returns the property title
  /// so the caller can show a confirmation.
  static Future<String?> joinWithCode(String code, {String? propertyId}) async {
    final response = await _post('/my-rent/join', {
      'code': code,
      if (propertyId != null) 'propertyId': propertyId,
    });
    return _decode(response)['propertyTitle'] as String?;
  }

  /// Announcements posted by owners for properties this tenant has actually
  /// joined (linked their account to via join code) - a property they
  /// haven't joined never shows up here, same as it's excluded from
  /// [fetchMyRentals].
  static Future<List<PropertyAnnouncement>> fetchMyAnnouncements() async {
    final response = await _get('/my-rent/announcements');
    final announcements = _decode(response)['announcements'] as List;
    return announcements.map((j) => PropertyAnnouncement.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Records a rent payment already completed + signature-verified via
  /// PaymentsApi.createOrder/verify.
  static Future<void> payRent(String tenantId, {required int month, required int year, required String paymentId}) async {
    final response = await _post('/my-rent/$tenantId/pay', {
      'month': month,
      'year': year,
      'paymentId': paymentId,
    });
    _decode(response);
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException('Server error. Please try again.');
    }
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

  static Future<http.Response> _get(String path) {
    return sendWithRetry(() async {
      final idToken = await _idToken();
      return await http
          .get(Uri.parse('$apiBaseUrl$path'), headers: {'Authorization': 'Bearer $idToken'})
          .timeout(const Duration(seconds: 40));
    });
  }

  static Future<http.Response> _post(String path, Map<String, dynamic> body) {
    return sendWithRetry(() async {
      final idToken = await _idToken();
      return await http
          .post(
            Uri.parse('$apiBaseUrl$path'),
            headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 40));
    });
  }
}
