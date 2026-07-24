import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

enum UserRole {
  apartmentAssociation,
  pgOwner,
  propertyOwner,
  tenant,
  serviceProvider;

  String get wireValue => switch (this) {
        UserRole.apartmentAssociation => 'apartment_association',
        UserRole.pgOwner => 'pg_owner',
        UserRole.propertyOwner => 'property_owner',
        UserRole.tenant => 'tenant',
        UserRole.serviceProvider => 'service_provider',
      };

  static UserRole? fromWire(String? value) => switch (value) {
        'apartment_association' => UserRole.apartmentAssociation,
        'pg_owner' => UserRole.pgOwner,
        'property_owner' => UserRole.propertyOwner,
        'tenant' => UserRole.tenant,
        'service_provider' => UserRole.serviceProvider,
        _ => null,
      };
}

enum ServiceType {
  plumber,
  electrician;

  String get wireValue => name;

  static ServiceType? fromWire(String? value) => switch (value) {
        'plumber' => ServiceType.plumber,
        'electrician' => ServiceType.electrician,
        _ => null,
      };
}

class AuthUser {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? photoURL;
  final UserRole? role;
  final ServiceType? serviceType;

  const AuthUser({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.photoURL,
    this.role,
    this.serviceType,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        name: json['name'] as String?,
        email: json['email'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        photoURL: json['photoURL'] as String?,
        role: UserRole.fromWire(json['role'] as String?),
        serviceType: ServiceType.fromWire(json['serviceType'] as String?),
      );
}

class AuthService {
  AuthService._();

  /// Verifies the signed-in Firebase user with the backend, creating a
  /// matching MongoDB record on first sign-in.
  static Future<AuthUser> syncCurrentUser() async {
    final response = await _get('/auth/me');
    return AuthUser.fromJson(_decode(response)['user'] as Map<String, dynamic>);
  }

  /// Saves the role chosen on the role-selection screen.
  static Future<AuthUser> updateRole({required UserRole role, ServiceType? serviceType}) async {
    final response = await _patch('/auth/role', {
      'role': role.wireValue,
      if (serviceType != null) 'serviceType': serviceType.wireValue,
    });
    return AuthUser.fromJson(_decode(response)['user'] as Map<String, dynamic>);
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
          .get(
            Uri.parse('$apiBaseUrl$path'),
            headers: {'Authorization': 'Bearer $idToken'},
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
}
