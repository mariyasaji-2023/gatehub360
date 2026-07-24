import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../data/listings_data.dart';
import '../models/service_offering.dart';
import 'api_config.dart';
import 'auth_service.dart';

class ServicesApi {
  ServicesApi._();

  static MyServiceListing _fromJson(Map<String, dynamic> json) {
    final slug = json['categorySlug'] as String;
    final category = serviceOfferings.firstWhere(
      (c) => c.slug == slug,
      orElse: () => ServiceOffering(slug: slug, emoji: '🛠️', name: slug, price: '', rating: 0, jobs: '', desc: ''),
    );
    return MyServiceListing.fromJson(json, emoji: category.emoji, name: category.name);
  }

  /// Active listings for a category, visible to any signed-in user.
  static Future<List<MyServiceListing>> fetchForCategory(String categorySlug) async {
    final response = await _get('/services?category=$categorySlug');
    final services = _decode(response)['services'] as List;
    return services.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
  }

  /// The signed-in provider's own listings (active and hidden).
  static Future<List<MyServiceListing>> fetchMine() async {
    final response = await _get('/services/mine');
    final services = _decode(response)['services'] as List;
    return services.map((j) => _fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<MyServiceListing> create({
    required String categorySlug,
    required String price,
    required String desc,
    bool active = true,
  }) async {
    final response = await _post('/services', {
      'categorySlug': categorySlug,
      'price': price,
      'desc': desc,
      'active': active,
    });
    return _fromJson(_decode(response)['service'] as Map<String, dynamic>);
  }

  static Future<MyServiceListing> update(
    String id, {
    String? price,
    String? desc,
    bool? active,
  }) async {
    final response = await _patch('/services/$id', {
      if (price != null) 'price': price,
      if (desc != null) 'desc': desc,
      if (active != null) 'active': active,
    });
    return _fromJson(_decode(response)['service'] as Map<String, dynamic>);
  }

  static Future<void> delete(String id) async {
    final response = await _delete('/services/$id');
    _decode(response);
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

  static Future<http.Response> _get(String path) async {
    try {
      final idToken = await _idToken();
      return await http
          .get(Uri.parse('$apiBaseUrl$path'), headers: {'Authorization': 'Bearer $idToken'})
          .timeout(const Duration(seconds: 15));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection and try again.');
    }
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

  static Future<http.Response> _patch(String path, Map<String, dynamic> body) async {
    try {
      final idToken = await _idToken();
      return await http
          .patch(
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

  static Future<http.Response> _delete(String path) async {
    try {
      final idToken = await _idToken();
      return await http
          .delete(Uri.parse('$apiBaseUrl$path'), headers: {'Authorization': 'Bearer $idToken'})
          .timeout(const Duration(seconds: 15));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection and try again.');
    }
  }
}
