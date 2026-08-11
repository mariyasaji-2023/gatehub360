/// A tenant renting a unit from a property owner - distinct from the
/// `tenant` User role (which just means "someone who browses listings").
class Tenant {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? roomNumber;
  final num monthlyRent;
  final DateTime moveInDate;
  final DateTime? moveOutDate;
  final String status;
  // The code this tenant enters in-app to link their account (see
  // AddTenantScreen / TenantsScreen). Null once the backend stops sending
  // it for some reason, but always present on records this app created.
  final String? joinCode;
  // Whether a tenant has actually entered the code yet — null just means
  // "unknown" (an endpoint that doesn't populate linkedUser); true/false is
  // the real signal for "waiting to join" vs "joined".
  final bool? isLinked;
  // Only populated by the tenant *list* endpoint, which computes these
  // inline so the Collect Payment screen can show a status badge without a
  // follow-up call per tenant.
  final int? pendingMonths;
  final num? pendingAmount;

  const Tenant({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.roomNumber,
    required this.monthlyRent,
    required this.moveInDate,
    this.moveOutDate,
    required this.status,
    this.joinCode,
    this.isLinked,
    this.pendingMonths,
    this.pendingAmount,
  });

  bool get isFullyPaid => (pendingMonths ?? 0) == 0;

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
        id: json['_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String?,
        roomNumber: json['roomNumber'] as String?,
        monthlyRent: json['monthlyRent'] as num,
        moveInDate: DateTime.parse(json['moveInDate'] as String),
        moveOutDate: json['moveOutDate'] != null ? DateTime.parse(json['moveOutDate'] as String) : null,
        status: json['status'] as String,
        joinCode: json['joinCode'] as String?,
        isLinked: json.containsKey('linkedUser') ? json['linkedUser'] != null : null,
        pendingMonths: json['pendingMonths'] as int?,
        pendingAmount: json['pendingAmount'] as num?,
      );
}
