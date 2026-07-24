class SocietyBill {
  final String id;
  final String? flatNumber;
  final int month;
  final int year;
  final num amount;
  final bool paid;

  const SocietyBill({
    required this.id,
    required this.flatNumber,
    required this.month,
    required this.year,
    required this.amount,
    required this.paid,
  });

  factory SocietyBill.fromJson(Map<String, dynamic> json) => SocietyBill(
        id: json['_id'] as String,
        flatNumber: json['flatNumber'] as String?,
        month: json['month'] as int,
        year: json['year'] as int,
        amount: json['amount'] as num,
        paid: json['status'] == 'paid',
      );

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String get periodLabel => '${_monthNames[month - 1]} $year';
}
