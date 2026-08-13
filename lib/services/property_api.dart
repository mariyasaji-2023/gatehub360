import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/property_announcement.dart';
import '../models/property_complaint.dart';
import '../models/property_join_request.dart';
import '../models/property_listing.dart';
import '../models/property_unit.dart';
import '../models/rent_payment.dart';
import '../models/tenant.dart';
import '../models/visitor.dart';
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
    String address = '',
    required String price,
    String rentAmount = '',
    String deposit = '',
    required String bhk,
    required String sqft,
    required String about,
    required String contact,
    bool active = true,
    List<String> images = const [],
    String? videoUrl,
    List<String> amenities = const [],
  }) async {
    final response = await _post('/properties', {
      'type': type,
      'mode': mode,
      'title': title,
      'location': location,
      'address': address,
      'price': price,
      'rentAmount': rentAmount,
      'deposit': deposit,
      'bhk': bhk,
      'sqft': sqft,
      'about': about,
      'contact': contact,
      'active': active,
      'images': images,
      'videoUrl': videoUrl,
      'amenities': amenities,
    });
    return MyPropertyListing.fromJson(_decode(response)['property'] as Map<String, dynamic>);
  }

  static Future<MyPropertyListing> update(
    String id, {
    String? type,
    String? mode,
    String? title,
    String? location,
    String? address,
    String? price,
    String? rentAmount,
    String? deposit,
    String? bhk,
    String? sqft,
    String? about,
    String? contact,
    bool? active,
    List<String>? images,
    // videoUrl needs to distinguish "leave it as-is" (omit the argument)
    // from "the owner removed their video" (pass null explicitly) - a plain
    // nullable param can't tell those apart, so this flag does.
    String? videoUrl,
    bool updateVideoUrl = false,
    List<String>? amenities,
  }) async {
    final response = await _patch('/properties/$id', {
      if (type != null) 'type': type,
      if (mode != null) 'mode': mode,
      if (title != null) 'title': title,
      if (location != null) 'location': location,
      if (address != null) 'address': address,
      if (price != null) 'price': price,
      if (rentAmount != null) 'rentAmount': rentAmount,
      if (deposit != null) 'deposit': deposit,
      if (bhk != null) 'bhk': bhk,
      if (sqft != null) 'sqft': sqft,
      if (about != null) 'about': about,
      if (contact != null) 'contact': contact,
      if (active != null) 'active': active,
      if (images != null) 'images': images,
      if (updateVideoUrl) 'videoUrl': videoUrl,
      if (amenities != null) 'amenities': amenities,
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
    num? maintenanceAmount,
    required DateTime moveInDate,
    String? altPhone,
    DateTime? moveOutDate,
    String? stayType,
    int? lockInMonths,
    int? noticePeriodDays,
    int? agreementPeriodMonths,
    int? rentDueDay,
    num? securityDeposit,
    String? referredBy,
    String? remarks,
    String? tenantType,
    String? otherDetails,
  }) async {
    final response = await _post('/properties/$propertyId/tenants', {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (roomNumber != null && roomNumber.isNotEmpty) 'roomNumber': roomNumber,
      'monthlyRent': monthlyRent,
      if (maintenanceAmount != null) 'maintenanceAmount': maintenanceAmount,
      'moveInDate': moveInDate.toIso8601String(),
      if (altPhone != null && altPhone.isNotEmpty) 'altPhone': altPhone,
      if (moveOutDate != null) 'moveOutDate': moveOutDate.toIso8601String(),
      if (stayType != null) 'stayType': stayType,
      if (lockInMonths != null) 'lockInMonths': lockInMonths,
      if (noticePeriodDays != null) 'noticePeriodDays': noticePeriodDays,
      if (agreementPeriodMonths != null) 'agreementPeriodMonths': agreementPeriodMonths,
      if (rentDueDay != null) 'rentDueDay': rentDueDay,
      if (securityDeposit != null) 'securityDeposit': securityDeposit,
      if (referredBy != null && referredBy.isNotEmpty) 'referredBy': referredBy,
      if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      if (tenantType != null && tenantType.isNotEmpty) 'tenantType': tenantType,
      if (otherDetails != null && otherDetails.isNotEmpty) 'otherDetails': otherDetails,
    });
    return Tenant.fromJson(_decode(response)['tenant'] as Map<String, dynamic>);
  }

  /// Covers marking a tenant moved out (status + moveOutDate) and
  /// attaching/replacing their KYC document or rental agreement. The
  /// `updateX` flags exist because these fields need to distinguish "leave
  /// as-is" (omit) from "clear it" (pass null explicitly) - a plain
  /// nullable param can't tell those apart.
  static Future<Tenant> updateTenant(
    String propertyId,
    String tenantId, {
    DateTime? moveOutDate,
    bool updateMoveOutDate = false,
    String? status,
    num? maintenanceAmount,
    bool updateMaintenanceAmount = false,
    String? kycDocumentUrl,
    bool updateKycDocumentUrl = false,
    String? rentalAgreementUrl,
    bool updateRentalAgreementUrl = false,
  }) async {
    final response = await _patch('/properties/$propertyId/tenants/$tenantId', {
      if (updateMoveOutDate) 'moveOutDate': moveOutDate?.toIso8601String(),
      if (status != null) 'status': status,
      if (updateMaintenanceAmount) 'maintenanceAmount': maintenanceAmount,
      if (updateKycDocumentUrl) 'kycDocumentUrl': kycDocumentUrl,
      if (updateRentalAgreementUrl) 'rentalAgreementUrl': rentalAgreementUrl,
    });
    return Tenant.fromJson(_decode(response)['tenant'] as Map<String, dynamic>);
  }

  static Future<void> deleteTenant(String propertyId, String tenantId) async {
    final response = await _delete('/properties/$propertyId/tenants/$tenantId');
    _decode(response);
  }

  // --- Join requests (owner side) - see backend/public/invite.html for
  // the public form these come from. ---

  static Future<List<PropertyJoinRequest>> fetchJoinRequests(String propertyId) async {
    final response = await _get('/properties/$propertyId/join-requests');
    final requests = _decode(response)['joinRequests'] as List;
    return requests.map((j) => PropertyJoinRequest.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Approving returns the newly-created [Tenant] (with its join code) so
  /// the caller can jump straight into sharing it; rejecting returns null.
  static Future<Tenant?> respondToJoinRequest(String propertyId, String requestId, {required bool approve, num? monthlyRent}) async {
    final response = await _patch('/properties/$propertyId/join-requests/$requestId', {
      'status': approve ? 'approved' : 'rejected',
      if (monthlyRent != null) 'monthlyRent': monthlyRent,
    });
    final data = _decode(response);
    return data['tenant'] != null ? Tenant.fromJson(data['tenant'] as Map<String, dynamic>) : null;
  }

  // --- Complaints (maintenance tickets) ---

  static Future<List<PropertyComplaint>> fetchComplaints(String propertyId) async {
    final response = await _get('/properties/$propertyId/complaints');
    final complaints = _decode(response)['complaints'] as List;
    return complaints.map((j) => PropertyComplaint.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Count of not-yet-resolved complaints — powers the dashboard's
  /// "Active Complaints" stat tile.
  static Future<int> fetchOpenComplaintsCount(String propertyId) async {
    final response = await _get('/properties/$propertyId/complaints/count');
    return _decode(response)['count'] as int;
  }

  static Future<PropertyComplaint> createComplaint(
    String propertyId, {
    required String description,
    required ComplaintCategory category,
    ComplaintLocation? location,
    bool urgent = false,
    String? tenantId,
  }) async {
    final response = await _post('/properties/$propertyId/complaints', {
      'description': description,
      'category': category.wireValue,
      if (location != null) 'location': location.wireValue,
      'urgent': urgent,
      if (tenantId != null) 'tenantId': tenantId,
    });
    return PropertyComplaint.fromJson(_decode(response)['complaint'] as Map<String, dynamic>);
  }

  static Future<PropertyComplaint> updateComplaintStatus(String propertyId, String complaintId, ComplaintStatus status) async {
    final response = await _patch('/properties/$propertyId/complaints/$complaintId', {'status': status.wireValue});
    return PropertyComplaint.fromJson(_decode(response)['complaint'] as Map<String, dynamic>);
  }

  // --- Visitor management ---

  /// Every visitor ever logged for this property, most recent first -
  /// doubles as "history"; one with no exitTime yet is still inside.
  static Future<List<Visitor>> fetchVisitors(String propertyId) async {
    final response = await _get('/properties/$propertyId/visitors');
    final visitors = _decode(response)['visitors'] as List;
    return visitors.map((j) => Visitor.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<Visitor> logVisitorEntry(
    String propertyId, {
    required String name,
    String? phone,
    String? purpose,
    String? meetingName,
  }) async {
    final response = await _post('/properties/$propertyId/visitors', {
      'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
      if (meetingName != null && meetingName.isNotEmpty) 'meetingName': meetingName,
    });
    return Visitor.fromJson(_decode(response)['visitor'] as Map<String, dynamic>);
  }

  static Future<Visitor> markVisitorExit(String propertyId, String visitorId) async {
    final response = await _patch('/properties/$propertyId/visitors/$visitorId/exit', {});
    return Visitor.fromJson(_decode(response)['visitor'] as Map<String, dynamic>);
  }

  // --- Announcements (owner side) ---

  static Future<List<PropertyAnnouncement>> fetchAnnouncements(String propertyId) async {
    final response = await _get('/properties/$propertyId/announcements');
    final announcements = _decode(response)['announcements'] as List;
    return announcements.map((j) => PropertyAnnouncement.fromJson(j as Map<String, dynamic>)).toList();
  }

  static Future<PropertyAnnouncement> createAnnouncement(String propertyId, {required String title, required String message}) async {
    final response = await _post('/properties/$propertyId/announcements', {'title': title, 'message': message});
    return PropertyAnnouncement.fromJson(_decode(response)['announcement'] as Map<String, dynamic>);
  }

  static Future<void> deleteAnnouncement(String propertyId, String announcementId) async {
    final response = await _delete('/properties/$propertyId/announcements/$announcementId');
    _decode(response);
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

  // --- Maintenance collection (owner side) — same shapes as rent, just
  // against a separate maintenance amount/ledger. Reuses TenantRentDetail/
  // RentSummary since the JSON shape is identical. ---

  static Future<TenantRentDetail> fetchTenantMaintenance(String propertyId, String tenantId) async {
    final response = await _get('/properties/$propertyId/tenants/$tenantId/maintenance');
    return TenantRentDetail.fromJson(_decode(response));
  }

  static Future<RentPaymentRecord> collectMaintenanceManually(
    String propertyId,
    String tenantId, {
    required int month,
    required int year,
    required String method,
  }) async {
    final response = await _patch('/properties/$propertyId/tenants/$tenantId/maintenance', {
      'month': month,
      'year': year,
      'method': method,
    });
    return RentPaymentRecord.fromJson(_decode(response)['payment'] as Map<String, dynamic>);
  }

  /// Dashboard-level maintenance aggregate for one property.
  static Future<RentSummary> fetchMaintenanceSummary(String propertyId) async {
    final response = await _get('/properties/$propertyId/maintenance-summary');
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
