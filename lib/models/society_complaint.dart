enum ComplaintCategory {
  plumbing,
  electrical,
  cleaning,
  security,
  parking,
  noise,
  other;

  String get wireValue => name;

  String get label => switch (this) {
        ComplaintCategory.plumbing => 'Plumbing',
        ComplaintCategory.electrical => 'Electrical',
        ComplaintCategory.cleaning => 'Cleaning',
        ComplaintCategory.security => 'Security',
        ComplaintCategory.parking => 'Parking',
        ComplaintCategory.noise => 'Noise',
        ComplaintCategory.other => 'Other',
      };

  static ComplaintCategory fromWire(String value) =>
      ComplaintCategory.values.firstWhere((c) => c.name == value, orElse: () => ComplaintCategory.other);
}

enum ComplaintStatus {
  open,
  inProgress,
  resolved;

  String get wireValue => switch (this) {
        ComplaintStatus.open => 'open',
        ComplaintStatus.inProgress => 'in_progress',
        ComplaintStatus.resolved => 'resolved',
      };

  String get label => switch (this) {
        ComplaintStatus.open => 'Open',
        ComplaintStatus.inProgress => 'In Progress',
        ComplaintStatus.resolved => 'Resolved',
      };

  static ComplaintStatus fromWire(String value) => switch (value) {
        'in_progress' => ComplaintStatus.inProgress,
        'resolved' => ComplaintStatus.resolved,
        _ => ComplaintStatus.open,
      };
}

enum ComplaintPriority {
  normal,
  urgent;

  String get wireValue => name;
  String get label => this == ComplaintPriority.urgent ? 'Urgent' : 'Normal';

  static ComplaintPriority fromWire(String value) => value == 'urgent' ? ComplaintPriority.urgent : ComplaintPriority.normal;
}

class SocietyComplaint {
  final String id;
  final String title;
  final String description;
  final ComplaintCategory category;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final String? flatNumber;
  final DateTime createdAt;

  const SocietyComplaint({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.flatNumber,
    required this.createdAt,
  });

  factory SocietyComplaint.fromJson(Map<String, dynamic> json) => SocietyComplaint(
        id: json['_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: ComplaintCategory.fromWire(json['category'] as String),
        status: ComplaintStatus.fromWire(json['status'] as String),
        priority: ComplaintPriority.fromWire(json['priority'] as String),
        flatNumber: json['flatNumber'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
