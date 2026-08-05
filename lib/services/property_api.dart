import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/property_listing.dart';
import 'api_config.dart';
import 'auth_service.dart';

class PropertyApi {
  PropertyApi._();

  /// Active listings, optionally filtered by type, visible to any signed-in user.
  static Future<List<MyPropertyListing>> fetchAll({String? type}) async {
    final query = (type != null && type != 'All') ? '?type=${Uri.encodeQueryComponent(type)}' : '';
    final response = await _get('/properties$query');
    final properties = _decode(response)['properties'] as List;
    return properties.map((j) => MyPropertyListing.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// The signed-in owner's own listings (active and hidden).
  static Future<List<MyPropertyListing>> fetchMine() async {
    final response = await _get('/properties/mine');
    final properties = _decode(response)['properties'] as List;
    return properties.map((j) => MyPropertyListing.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<MyPropertyListing> create({
    required String type,
    required String mode,
    required String title,
    required String location,
    required String price,
    required String bhk,
    required String sqft,
    required String about,
    required String contact,
    bool active = true,
  }) async {
    final response = await _post('/properties', {
      'type': type,
      'mode': mode,
      'title': title,
      'location': location,
      'price': price,
      'bhk': bhk,
      'sqft': sqft,
      'about': about,
      'contact': contact,
      'active': active,
    });
    return MyPropertyListing.fromJson(_decode(response)['property'] as Map<String, dynamic>);
  }

  static Future<MyPropertyListing> update(
    String id, {
    String? type,
    String? mode,
    String? title,
    String? location,
    String? price,
    String? bhk,
    String? sqft,
    String? about,
    String? contact,
    bool? active,
  }) async {
    final response = await _patch('/properties/$id', {
      if (type != null) 'type': type,
      if (mode != null) 'mode': mode,
      if (title != null) 'title': title,
      if (location != null) 'location': location,
      if (price != null) 'price': price,
      if (bhk != null) 'bhk': bhk,
      if (sqft != null) 'sqft': sqft,
      if (about != null) 'about': about,
      if (contact != null) 'contact': contact,
      if (active != null) 'active': active,
    });
    return MyPropertyListing.fromJson(_decode(response)['property'] as Map<String, dynamic>);
  }

  static Future<void> delete(String id) async {
    final response = await _delete('/properties/$id');
    _decode(response);
  }

  /// Sends the client's phone number to the owner and triggers a push notification.
  static Future<void> sendEnquiry(String propertyId, String phone) async {
    final response = await _post('/properties/$propertyId/enquire', {'phone': phone});
    _decode(response);
  }

  /// Total unread contact requests across the signed-in owner's properties.
  static Future<int> fetchUnreadEnquiryCount() async {
    final response = await _get('/properties/enquiries/unread-count');
    return _decode(response)['count'] as int;
  }

  /// Contact requests left for the signed-in owner's properties.
  static Future<List<PropertyEnquiry>> fetchEnquiries() async {
    final response = await _get('/properties/enquiries/mine');
    final enquiries = _decode(response)['enquiries'] as List;
    return enquiries.map((j) => PropertyEnquiry.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Contact requests for one specific property the signed-in owner listed.
  static Future<List<PropertyEnquiry>> fetchEnquiriesForProperty(String propertyId) async {
    final response = await _get('/properties/$propertyId/enquiries');
    final enquiries = _decode(response)['enquiries'] as List;
    return enquiries.map((j) => PropertyEnquiry.fromJson(j as Map<String, dynamic>)).toList();
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

  static Future<http.Response> _patch(String path, Map<String, dynamic> body) {
    return sendWithRetry(() async {
      final idToken = await _idToken();
      return await http
          .patch(
            Uri.parse('$apiBaseUrl$path'),
            headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 40));
    });
  }

  static Future<http.Response> _delete(String path) {
    return sendWithRetry(() async {
      final idToken = await _idToken();
      return await http
          .delete(Uri.parse('$apiBaseUrl$path'), headers: {'Authorization': 'Bearer $idToken'})
          .timeout(const Duration(seconds: 40));
    });
  }
}
