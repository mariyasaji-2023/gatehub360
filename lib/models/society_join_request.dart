enum JoinRequestStatus {
  pending,
  approved,
  rejected;

  String get wireValue => name;
  String get label => switch (this) {
        JoinRequestStatus.pending => 'Pending',
        JoinRequestStatus.approved => 'Approved',
        JoinRequestStatus.rejected => 'Declined',
      };

  static JoinRequestStatus fromWire(String value) => JoinRequestStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => JoinRequestStatus.pending,
      );
}

class SocietyJoinRequest {
  final String id;
  final String? requesterName;
  final String? requesterPhone;
  final String? flatNumber;
  final String? societyName;
  final JoinRequestStatus status;

  const SocietyJoinRequest({
    required this.id,
    this.requesterName,
    this.requesterPhone,
    this.flatNumber,
    this.societyName,
    required this.status,
  });

  factory SocietyJoinRequest.fromJson(Map<String, dynamic> json) {
    // requester/flat/society are only populated objects on some endpoints
    // (e.g. /join-requests/mine skips requester, since a tenant doesn't need
    // their own name) - otherwise they're just raw ObjectId strings.
    final requester = json['requester'] is Map<String, dynamic> ? json['requester'] as Map<String, dynamic> : null;
    final flat = json['flat'] is Map<String, dynamic> ? json['flat'] as Map<String, dynamic> : null;
    final society = json['society'] is Map<String, dynamic> ? json['society'] as Map<String, dynamic> : null;
    return SocietyJoinRequest(
      id: json['_id'] as String,
      requesterName: requester?['name'] as String?,
      requesterPhone: requester?['phoneNumber'] as String?,
      flatNumber: flat?['flatNumber'] as String?,
      societyName: society?['name'] as String?,
      status: JoinRequestStatus.fromWire(json['status'] as String),
    );
  }
}
