import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/hostel_listing.dart';
import 'api_config.dart';
import 'auth_service.dart';

class HostelApi {
  HostelApi._();

  /// Active listings, optionally filtered by type/gender, visible to any signed-in user.
  static Future<List<MyHostelListing>> fetchAll({String? type, String? gender}) async {
    final params = <String, String>{};
    if (type != null && type != 'All') params['type'] = type;
    if (gender != null && gender != 'All') params['gender'] = gender;
    final query = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    final response = await _get('/hostels$query');
    final hostels = _decode(response)['hostels'] as List;
    return hostels.map((j) => MyHostelListing.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// The signed-in owner's own listings (active and hidden).
  static Future<List<MyHostelListing>> fetchMine() async {
    final response = await _get('/hostels/mine');
    final hostels = _decode(response)['hostels'] as List;
    return hostels.map((j) => MyHostelListing.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<MyHostelListing> create({
    required String type,
    required String gender,
    required String title,
    required String location,
    required String about,
    required String contact,
    required List<String> amenities,
    required List<HostelRoomOption> rooms,
    bool active = true,
  }) async {
    final response = await _post('/hostels', {
      'type': type,
      'gender': gender,
      'title': title,
      'location': location,
      'about': about,
      'contact': contact,
      'amenities': amenities,
      'rooms': rooms.map((r) => r.toJson()).toList(),
      'active': active,
    });
    return MyHostelListing.fromJson(_decode(response)['hostel'] as Map<String, dynamic>);
  }

  static Future<MyHostelListing> update(
    String id, {
    String? type,
    String? gender,
    String? title,
    String? location,
    String? about,
    String? contact,
    List<String>? amenities,
    List<HostelRoomOption>? rooms,
    bool? active,
  }) async {
    final response = await _patch('/hostels/$id', {
      if (type != null) 'type': type,
      if (gender != null) 'gender': gender,
      if (title != null) 'title': title,
      if (location != null) 'location': location,
      if (about != null) 'about': about,
      if (contact != null) 'contact': contact,
      if (amenities != null) 'amenities': amenities,
      if (rooms != null) 'rooms': rooms.map((r) => r.toJson()).toList(),
      if (active != null) 'active': active,
    });
    return MyHostelListing.fromJson(_decode(response)['hostel'] as Map<String, dynamic>);
  }

  static Future<void> delete(String id) async {
    final response = await _delete('/hostels/$id');
    _decode(response);
  }

  /// Sends the client's phone number to the owner and triggers a push notification.
  static Future<void> sendEnquiry(String hostelId, String phone) async {
    final response = await _post('/hostels/$hostelId/enquire', {'phone': phone});
    _decode(response);
  }

  /// Total unread contact requests across the signed-in owner's listings.
  static Future<int> fetchUnreadEnquiryCount() async {
    final response = await _get('/hostels/enquiries/unread-count');
    return _decode(response)['count'] as int;
  }

  /// Contact requests left for the signed-in owner's listings.
  static Future<List<HostelEnquiry>> fetchEnquiries() async {
    final response = await _get('/hostels/enquiries/mine');
    final enquiries = _decode(response)['enquiries'] as List;
    return enquiries.map((j) => HostelEnquiry.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Contact requests for one specific listing the signed-in owner added.
  static Future<List<HostelEnquiry>> fetchEnquiriesForHostel(String hostelId) async {
    final response = await _get('/hostels/$hostelId/enquiries');
    final enquiries = _decode(response)['enquiries'] as List;
    return enquiries.map((j) => HostelEnquiry.fromJson(j as Map<String, dynamic>)).toList();
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
