class Society {
  final String id;
  final String name;
  final String address;
  final String pincode;
  final String area;
  final String city;
  final String state;
  final String code;

  const Society({
    required this.id,
    required this.name,
    required this.address,
    required this.pincode,
    required this.area,
    required this.city,
    required this.state,
    required this.code,
  });

  factory Society.fromJson(Map<String, dynamic> json) => Society(
        id: json['_id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        pincode: json['pincode'] as String? ?? '',
        area: json['area'] as String? ?? '',
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        code: json['code'] as String,
      );
}
