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

  // --- Stay details - all optional, filled in on the "Stay Details" tab
  // of AddTenantScreen (see backend/models/Tenant.js) ---
  final String? altPhone;
  final String stayType; // 'long' | 'short'
  final int? lockInMonths;
  final int? noticePeriodDays;
  final int? agreementPeriodMonths;
  final String rentalFrequency; // only 'monthly' is supported today
  final int? rentDueDay;
  final num? securityDeposit;
  final String? referredBy;
  final String? remarks;
  final String? tenantType;
  final String? otherDetails;

  // --- KYC + rental agreement - both hosted on Cloudinary; only the URL
  // lives here (see lib/services/cloudinary_api.dart) ---
  final String? kycDocumentUrl;
  final String? rentalAgreementUrl;

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
    this.altPhone,
    this.stayType = 'long',
    this.lockInMonths,
    this.noticePeriodDays,
    this.agreementPeriodMonths,
    this.rentalFrequency = 'monthly',
    this.rentDueDay,
    this.securityDeposit,
    this.referredBy,
    this.remarks,
    this.tenantType,
    this.otherDetails,
    this.kycDocumentUrl,
    this.rentalAgreementUrl,
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
        altPhone: json['altPhone'] as String?,
        stayType: json['stayType'] as String? ?? 'long',
        lockInMonths: json['lockInMonths'] as int?,
        noticePeriodDays: json['noticePeriodDays'] as int?,
        agreementPeriodMonths: json['agreementPeriodMonths'] as int?,
        rentalFrequency: json['rentalFrequency'] as String? ?? 'monthly',
        rentDueDay: json['rentDueDay'] as int?,
        securityDeposit: json['securityDeposit'] as num?,
        referredBy: json['referredBy'] as String?,
        remarks: json['remarks'] as String?,
        tenantType: json['tenantType'] as String?,
        otherDetails: json['otherDetails'] as String?,
        kycDocumentUrl: json['kycDocumentUrl'] as String?,
        rentalAgreementUrl: json['rentalAgreementUrl'] as String?,
      );
}
