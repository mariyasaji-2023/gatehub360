/// A society as returned by search - deliberately excludes the invite code,
/// which stays private to the code-based join/enter flows.
class SocietySearchResult {
  final String id;
  final String name;
  final String address;
  final String area;
  final String city;
  final String state;

  const SocietySearchResult({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    required this.city,
    required this.state,
  });

  factory SocietySearchResult.fromJson(Map<String, dynamic> json) => SocietySearchResult(
        id: json['_id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        area: json['area'] as String? ?? '',
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
      );
}
