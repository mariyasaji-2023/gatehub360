import 'tenant.dart';

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// A calendar month with no paid RentPayment record yet for a tenant -
/// computed by the backend, not stored.
class DueMonth {
  final int month;
  final int year;
  final num amount;

  const DueMonth({required this.month, required this.year, required this.amount});

  String get label => '${_monthNames[month - 1]} $year';

  factory DueMonth.fromJson(Map<String, dynamic> json) =>
      DueMonth(month: json['month'] as int, year: json['year'] as int, amount: json['amount'] as num);
}

/// One month's rent that has actually been paid — either the owner recorded
/// collecting it in person, or the tenant paid through the app.
class RentPaymentRecord {
  final String id;
  final int month;
  final int year;
  final num amount;
  final String method;
  final DateTime paidAt;

  const RentPaymentRecord({
    required this.id,
    required this.month,
    required this.year,
    required this.amount,
    required this.method,
    required this.paidAt,
  });

  String get label => '${_monthNames[month - 1]} $year';

  String get methodLabel => switch (method) {
        'cash' => 'Cash',
        'upi' => 'UPI',
        'bank_transfer' => 'Bank Transfer',
        'online' => 'Paid Online',
        _ => method,
      };

  factory RentPaymentRecord.fromJson(Map<String, dynamic> json) => RentPaymentRecord(
        id: json['_id'] as String,
        month: json['month'] as int,
        year: json['year'] as int,
        amount: json['amount'] as num,
        method: json['method'] as String,
        paidAt: DateTime.parse(json['paidAt'] as String),
      );
}

/// One tenant's full rent picture, for the owner's "Collect Payment" detail
/// screen.
class TenantRentDetail {
  final Tenant tenant;
  final List<DueMonth> due;
  final List<RentPaymentRecord> payments;

  const TenantRentDetail({required this.tenant, required this.due, required this.payments});

  factory TenantRentDetail.fromJson(Map<String, dynamic> json) => TenantRentDetail(
        tenant: Tenant.fromJson(json['tenant'] as Map<String, dynamic>),
        due: (json['due'] as List).map((d) => DueMonth.fromJson(d as Map<String, dynamic>)).toList(),
        payments: (json['payments'] as List).map((p) => RentPaymentRecord.fromJson(p as Map<String, dynamic>)).toList(),
      );
}

/// Dashboard-level rent aggregate for one property.
class RentSummary {
  final num todayCollection;
  final num thisMonthCollection;
  final num thisMonthDues;
  final num allTimeDues;
  final int activeTenants;

  const RentSummary({
    required this.todayCollection,
    required this.thisMonthCollection,
    required this.thisMonthDues,
    required this.allTimeDues,
    required this.activeTenants,
  });

  factory RentSummary.fromJson(Map<String, dynamic> json) => RentSummary(
        todayCollection: json['todayCollection'] as num,
        thisMonthCollection: json['thisMonthCollection'] as num,
        thisMonthDues: json['thisMonthDues'] as num,
        allTimeDues: json['allTimeDues'] as num,
        activeTenants: json['activeTenants'] as int,
      );
}

/// One property a signed-in `tenant` role user is renting, matched by their
/// verified login phone number — the tenant-facing "My Rent" view.
class MyRental {
  final String tenantId;
  final String? propertyId;
  final String propertyTitle;
  final String propertyLocation;
  final String? roomNumber;
  final num monthlyRent;
  final List<DueMonth> due;
  final List<RentPaymentRecord> payments;

  const MyRental({
    required this.tenantId,
    this.propertyId,
    required this.propertyTitle,
    required this.propertyLocation,
    this.roomNumber,
    required this.monthlyRent,
    required this.due,
    required this.payments,
  });

  factory MyRental.fromJson(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>?;
    return MyRental(
      tenantId: json['tenantId'] as String,
      propertyId: property?['_id'] as String?,
      propertyTitle: property?['title'] as String? ?? 'Property',
      propertyLocation: property?['location'] as String? ?? '',
      roomNumber: json['roomNumber'] as String?,
      monthlyRent: json['monthlyRent'] as num,
      due: (json['due'] as List).map((d) => DueMonth.fromJson(d as Map<String, dynamic>)).toList(),
      payments: (json['payments'] as List).map((p) => RentPaymentRecord.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}
