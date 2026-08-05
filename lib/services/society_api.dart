import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/society.dart';
import '../models/society_bill.dart';
import '../models/society_complaint.dart';
import '../models/society_notice.dart';
import '../models/society_flat.dart';
import '../models/society_join_request.dart';
import '../models/society_resident.dart';
import '../models/society_search_result.dart';
import 'api_config.dart';
import 'auth_service.dart';

class SocietyApi {
  SocietyApi._();

  static Future<Society?> fetchMySociety() async {
    final response = await _get('/society/me');
    final society = _decode(response)['society'];
    return society == null ? null : Society.fromJson(society as Map<String, dynamic>);
  }

  static Future<Society> createSociety({
    required String name,
    required String address,
    required String pincode,
    required String area,
    required String city,
    required String state,
  }) async {
    final response = await _post('/society', {
      'name': name,
      'address': address,
      'pincode': pincode,
      'area': area,
      'city': city,
      'state': state,
    });
    return Society.fromJson(_decode(response)['society'] as Map<String, dynamic>);
  }

  /// All societies created by the signed-in apartment association.
  static Future<List<Society>> fetchMine() async {
    final response = await _get('/society/mine');
    final societies = _decode(response)['societies'] as List;
    return societies.map((j) => Society.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<Society> switchSociety(String societyId) async {
    final response = await _post('/society/switch', {'societyId': societyId});
    return Society.fromJson(_decode(response)['society'] as Map<String, dynamic>);
  }

  /// Becomes a co-manager of a society you didn't create, via its invite code.
  static Future<Society> enterSociety(String code) async {
    final response = await _post('/society/enter', {'code': code});
    return Society.fromJson(_decode(response)['society'] as Map<String, dynamic>);
  }

  /// Same as [enterSociety], but for a society found via [searchSocieties].
  static Future<Society> enterSocietyBySearch(String societyId) async {
    final response = await _post('/society/enter-by-search', {'societyId': societyId});
    return Society.fromJson(_decode(response)['society'] as Map<String, dynamic>);
  }

  static Future<Society> joinSociety({required String code, required String flatId}) async {
    final response = await _post('/society/join', {'code': code, 'flatId': flatId});
    return Society.fromJson(_decode(response)['society'] as Map<String, dynamic>);
  }

  /// Finds societies by name/area/city for residents who don't have the invite code.
  static Future<List<SocietySearchResult>> searchSocieties(String query) async {
    final response = await _get('/society/search?q=${Uri.encodeQueryComponent(query)}');
    final societies = _decode(response)['societies'] as List;
    return societies.map((j) => SocietySearchResult.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<void> createJoinRequest({required String societyId}) async {
    _decode(await _post('/society/join-requests', {'societyId': societyId}));
  }

  static Future<List<SocietyJoinRequest>> fetchJoinRequests() async {
    final response = await _get('/society/join-requests');
    final requests = _decode(response)['joinRequests'] as List;
    return requests.map((j) => SocietyJoinRequest.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<SocietyJoinRequest?> fetchMyJoinRequest() async {
    final response = await _get('/society/join-requests/mine');
    final joinRequest = _decode(response)['joinRequest'];
    return joinRequest == null ? null : SocietyJoinRequest.fromJson(joinRequest as Map<String, dynamic>);
  }

  static Future<void> respondToJoinRequest(String id, {required bool approve}) async {
    _decode(await _patch('/society/join-requests/$id', {'status': approve ? 'approved' : 'rejected'}));
  }

  static Future<void> dismissJoinRequest(String id) async {
    _decode(await _post('/society/join-requests/$id/dismiss', {}));
  }

  static Future<void> leaveSociety() async {
    _decode(await _post('/society/leave', {}));
  }

  /// Full flat list of the caller's active society, including who lives where.
  static Future<List<SocietyFlat>> fetchFlats() async {
    final response = await _get('/society/flats');
    final flats = _decode(response)['flats'] as List;
    return flats.map((j) => SocietyFlat.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Browsable flat list for a society the caller hasn't joined yet, by id.
  static Future<List<SocietyFlat>> fetchPublicFlats({required String societyId}) async {
    final response = await _get('/society/flats/public?societyId=${Uri.encodeQueryComponent(societyId)}');
    final flats = _decode(response)['flats'] as List;
    return flats.map((j) => SocietyFlat.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Same as [fetchPublicFlats], but resolved via invite code - also returns the society name.
  static Future<({String societyName, List<SocietyFlat> flats})> fetchFlatsForCode(String code) async {
    final response = await _get('/society/flats/public?code=${Uri.encodeQueryComponent(code)}');
    final data = _decode(response);
    final flats = (data['flats'] as List).map((j) => SocietyFlat.fromJson(j as Map<String, dynamic>)).toList();
    final societyName = (data['society'] as Map<String, dynamic>)['name'] as String;
    return (societyName: societyName, flats: flats);
  }

  static Future<SocietyFlat> addFlat(String flatNumber) async {
    final response = await _post('/society/flats', {'flatNumber': flatNumber});
    return SocietyFlat.fromJson(_decode(response)['flat'] as Map<String, dynamic>);
  }

  static Future<void> expressInterest(String flatId) async {
    _decode(await _post('/society/flats/$flatId/interest', {}));
  }

  static Future<({int created, int skipped})> addFlatsBulk(List<String> flatNumbers) async {
    final response = await _post('/society/flats/bulk', {'flatNumbers': flatNumbers});
    final data = _decode(response);
    return (created: data['created'] as int, skipped: data['skipped'] as int);
  }

  static Future<SocietyFlat> setFlatStatus(String id, FlatStatus status) async {
    final response = await _patch('/society/flats/$id', {'status': status.wireValue});
    return SocietyFlat.fromJson(_decode(response)['flat'] as Map<String, dynamic>);
  }

  static Future<void> deleteFlat(String id) async {
    _decode(await _delete('/society/flats/$id'));
  }

  static Future<List<SocietyResident>> fetchResidents() async {
    final response = await _get('/society/residents');
    final residents = _decode(response)['residents'] as List;
    return residents.map((j) => SocietyResident.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<List<SocietyNotice>> fetchNotices() async {
    final response = await _get('/society/notices');
    final notices = _decode(response)['notices'] as List;
    return notices.map((j) => SocietyNotice.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<SocietyNotice> createNotice({required String title, required String message}) async {
    final response = await _post('/society/notices', {'title': title, 'message': message});
    return SocietyNotice.fromJson(_decode(response)['notice'] as Map<String, dynamic>);
  }

  static Future<void> deleteNotice(String id) async {
    _decode(await _delete('/society/notices/$id'));
  }

  static Future<List<SocietyComplaint>> fetchComplaints() async {
    final response = await _get('/society/complaints');
    final complaints = _decode(response)['complaints'] as List;
    return complaints.map((j) => SocietyComplaint.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<SocietyComplaint> createComplaint({
    required String title,
    required String description,
    required ComplaintCategory category,
    required ComplaintPriority priority,
  }) async {
    final response = await _post('/society/complaints', {
      'title': title,
      'description': description,
      'category': category.wireValue,
      'priority': priority.wireValue,
    });
    return SocietyComplaint.fromJson(_decode(response)['complaint'] as Map<String, dynamic>);
  }

  static Future<SocietyComplaint> updateComplaintStatus(String id, ComplaintStatus status) async {
    final response = await _patch('/society/complaints/$id', {'status': status.wireValue});
    return SocietyComplaint.fromJson(_decode(response)['complaint'] as Map<String, dynamic>);
  }

  static Future<List<SocietyBill>> fetchBills() async {
    final response = await _get('/society/bills');
    final bills = _decode(response)['bills'] as List;
    return bills.map((j) => SocietyBill.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<int> generateBills({required int month, required int year, required num amount}) async {
    final response = await _post('/society/bills/generate', {'month': month, 'year': year, 'amount': amount});
    return _decode(response)['created'] as int;
  }

  static Future<SocietyBill> markBillPaid(String id, {String? paymentId}) async {
    final response = await _patch('/society/bills/$id/paid', {
      'status': 'paid',
      if (paymentId != null) 'paymentId': paymentId,
    });
    return SocietyBill.fromJson(_decode(response)['bill'] as Map<String, dynamic>);
  }

  static Future<SocietyBill> setBillStatus(String id, bool paid) async {
    final response = await _patch('/society/bills/$id/paid', {'status': paid ? 'paid' : 'unpaid'});
    return SocietyBill.fromJson(_decode(response)['bill'] as Map<String, dynamic>);
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
