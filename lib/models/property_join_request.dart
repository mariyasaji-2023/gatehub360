/// A prospective tenant's self-submitted request to join a property,
/// filled out on the public web form the "Invite Tenant" QR/link opens
/// (see backend/public/invite.html) — no sign-in required on their end.
/// The owner reviews it here; approving turns it into a real [Tenant].
class PropertyJoinRequest {
  final String id;
  final String name;
  final String phone;
  final String? altPhone;
  final String? roomNumber;
  final num? monthlyRent;
  final num? securityDeposit;
  final DateTime? moveInDate;
  final DateTime createdAt;

  const PropertyJoinRequest({
    required this.id,
    required this.name,
    required this.phone,
    this.altPhone,
    this.roomNumber,
    this.monthlyRent,
    this.securityDeposit,
    this.moveInDate,
    required this.createdAt,
  });

  factory PropertyJoinRequest.fromJson(Map<String, dynamic> json) => PropertyJoinRequest(
        id: json['_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        altPhone: json['altPhone'] as String?,
        roomNumber: json['roomNumber'] as String?,
        monthlyRent: json['monthlyRent'] as num?,
        securityDeposit: json['securityDeposit'] as num?,
        moveInDate: json['moveInDate'] != null ? DateTime.parse(json['moveInDate'] as String) : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
