/// A visitor logged against a property — [exitTime] stays null until
/// they're checked out, which is what distinguishes "currently inside"
/// from history.
class Visitor {
  final String id;
  final String name;
  final String? phone;
  final String? purpose;
  final String? meetingName;
  final DateTime entryTime;
  final DateTime? exitTime;

  const Visitor({
    required this.id,
    required this.name,
    this.phone,
    this.purpose,
    this.meetingName,
    required this.entryTime,
    this.exitTime,
  });

  bool get isInside => exitTime == null;

  factory Visitor.fromJson(Map<String, dynamic> json) => Visitor(
        id: json['_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        purpose: json['purpose'] as String?,
        meetingName: json['meetingName'] as String?,
        entryTime: DateTime.parse(json['entryTime'] as String),
        exitTime: json['exitTime'] != null ? DateTime.parse(json['exitTime'] as String) : null,
      );
}
