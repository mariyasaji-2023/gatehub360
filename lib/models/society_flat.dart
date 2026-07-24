enum FlatStatus {
  vacant,
  occupied;

  String get wireValue => name;
  String get label => this == FlatStatus.occupied ? 'Occupied' : 'Vacant';

  static FlatStatus fromWire(String value) => value == 'occupied' ? FlatStatus.occupied : FlatStatus.vacant;
}

class SocietyFlat {
  final String id;
  final String flatNumber;
  final FlatStatus status;
  final String? residentName;

  const SocietyFlat({
    required this.id,
    required this.flatNumber,
    required this.status,
    this.residentName,
  });

  factory SocietyFlat.fromJson(Map<String, dynamic> json) => SocietyFlat(
        id: json['_id'] as String,
        flatNumber: json['flatNumber'] as String,
        status: FlatStatus.fromWire(json['status'] as String),
        residentName: (json['resident'] as Map<String, dynamic>?)?['name'] as String?,
      );
}
