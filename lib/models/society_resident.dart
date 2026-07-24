class SocietyResident {
  final String id;
  final String? name;
  final String? phoneNumber;
  final String? flatNumber;
  final String? role;

  const SocietyResident({required this.id, this.name, this.phoneNumber, this.flatNumber, this.role});

  factory SocietyResident.fromJson(Map<String, dynamic> json) => SocietyResident(
        id: json['_id'] as String,
        name: json['name'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        flatNumber: json['flatNumber'] as String?,
        role: json['role'] as String?,
      );
}
