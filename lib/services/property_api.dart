import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/property_listing.dart';
import '../models/property_unit.dart';
import '../models/rent_payment.dart';
import '../models/tenant.dart';
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

  // --- Vacancy management ---

  /// Adds one or more floors to the property. Safe to call with floors that
  /// already exist - the backend dedupes.
  static Future<List<String>> addFloors(String propertyId, List<String> floors) async {
    final response = await _post('/properties/$propertyId/floors', {'floors': floors});
    return (_decode(response)['floors'] as List).cast<String>();
  }

  static Future<VacancySummary> fetchVacancySummary(String propertyId) async {
    final response = await _get('/properties/$propertyId/vacancy');
    return VacancySummary.fromJson(_decode(response));
  }

  /// Creates individual trackable units from stepper rows (a row with
  /// count: 3 becomes 3 separate vacant units on that floor).
  static Future<List<PropertyUnit>> addUnits(String propertyId, {required String floor, required List<UnitRowInput> rows}) async {
    final response = await _post('/properties/$propertyId/units', {
      'floor': floor,
      'rows': rows.map((r) => r.toJson()).toList(),
    });
    final units = _decode(response)['units'] as List;
    return units.map((j) => PropertyUnit.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<PropertyUnit>> fetchUnits(String propertyId, {String? floor}) async {
    final query = floor != null ? '?floor=${Uri.encodeQueryComponent(floor)}' : '';
    final response = await _get('/properties/$propertyId/units$query');
    final units = _decode(response)['units'] as List;
    return units.map((j) => PropertyUnit.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<PropertyUnit> updateUnitStatus(String propertyId, String unitId, String status) async {
    final response = await _patch('/properties/$propertyId/units/$unitId', {'status': status});
    return PropertyUnit.fromJson(_decode(response)['unit'] as Map<String, dynamic>);
  }

  static Future<DateTime> publishVacancy(String propertyId) async {
    final response = await _post('/properties/$propertyId/publish-vacancy', {});
    return DateTime.parse(_decode(response)['vacancyPublishedAt'] as String);
  }

  // --- Tenant management ---

  /// Tenants the signed-in owner has added for one of their properties.
  static Future<List<Tenant>> fetchTenants(String propertyId) async {
    final response = await _get('/properties/$propertyId/tenants');
    final tenants = _decode(response)['tenants'] as List;
    return tenants.map((j) => Tenant.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<Tenant> addTenant(
    String propertyId, {
    required String name,
    required String phone,
    String? email,
    String? roomNumber,
    required num monthlyRent,
    required DateTime moveInDate,
  }) async {
    final response = await _post('/properties/$propertyId/tenants', {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (roomNumber != null && roomNumber.isNotEmpty) 'roomNumber': roomNumber,
      'monthlyRent': monthlyRent,
      'moveInDate': moveInDate.toIso8601String(),
    });
    return Tenant.fromJson(_decode(response)['tenant'] as Map<String, dynamic>);
  }

  // --- Rent collection (owner side) ---

  /// One tenant's full rent picture — which months are due, and paid history.
  static Future<TenantRentDetail> fetchTenantRent(String propertyId, String tenantId) async {
    final response = await _get('/properties/$propertyId/tenants/$tenantId/rent');
    return TenantRentDetail.fromJson(_decode(response));
  }

  /// Owner records rent they collected themselves (cash/UPI/bank transfer).
  static Future<RentPaymentRecord> collectRentManually(
    String propertyId,
    String tenantId, {
    required int month,
    required int year,
    required String method,
  }) async {
    final response = await _patch('/properties/$propertyId/tenants/$tenantId/rent', {
      'month': month,
      'year': year,
      'method': method,
    });
    return RentPaymentRecord.fromJson(_decode(response)['payment'] as Map<String, dynamic>);
  }

  /// Dashboard-level rent aggregate for one property.
  static Future<RentSummary> fetchRentSummary(String propertyId) async {
    final response = await _get('/properties/$propertyId/rent-summary');
    return RentSummary.fromJson(_decode(response));
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
