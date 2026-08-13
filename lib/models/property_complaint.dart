enum ComplaintCategory {
  plumbing,
  electrical,
  cleaning,
  structural,
  appliance,
  pestControl,
  other;

  String get wireValue => switch (this) {
        ComplaintCategory.pestControl => 'pest_control',
        _ => name,
      };

  String get label => switch (this) {
        ComplaintCategory.plumbing => 'Plumbing',
        ComplaintCategory.electrical => 'Electrical',
        ComplaintCategory.cleaning => 'Cleaning',
        ComplaintCategory.structural => 'Structural',
        ComplaintCategory.appliance => 'Appliance',
        ComplaintCategory.pestControl => 'Pest Control',
        ComplaintCategory.other => 'Other',
      };

  static ComplaintCategory fromWire(String value) => switch (value) {
        'pest_control' => ComplaintCategory.pestControl,
        _ => ComplaintCategory.values.firstWhere((c) => c.name == value, orElse: () => ComplaintCategory.other),
      };
}

enum ComplaintLocation {
  room,
  bathroom,
  kitchen,
  commonArea,
  exterior,
  other;

  String get wireValue => switch (this) {
        ComplaintLocation.commonArea => 'common_area',
        _ => name,
      };

  String get label => switch (this) {
        ComplaintLocation.room => 'Room',
        ComplaintLocation.bathroom => 'Bathroom',
        ComplaintLocation.kitchen => 'Kitchen',
        ComplaintLocation.commonArea => 'Common Area',
        ComplaintLocation.exterior => 'Building Exterior',
        ComplaintLocation.other => 'Other',
      };

  static ComplaintLocation fromWire(String value) => switch (value) {
        'common_area' => ComplaintLocation.commonArea,
        _ => ComplaintLocation.values.firstWhere((l) => l.name == value, orElse: () => ComplaintLocation.other),
      };
}

enum ComplaintStatus {
  received,
  inProgress,
  resolved,
  closed;

  String get wireValue => switch (this) {
        ComplaintStatus.inProgress => 'in_progress',
        _ => name,
      };

  String get label => switch (this) {
        ComplaintStatus.received => 'Complaint Received',
        ComplaintStatus.inProgress => 'In Progress',
        ComplaintStatus.resolved => 'Resolved',
        ComplaintStatus.closed => 'Closed',
      };

  static ComplaintStatus fromWire(String value) => switch (value) {
        'in_progress' => ComplaintStatus.inProgress,
        'resolved' => ComplaintStatus.resolved,
        'closed' => ComplaintStatus.closed,
        _ => ComplaintStatus.received,
      };
}

/// A maintenance ticket raised against a property — separate from
/// [SocietyComplaint], which is scoped to a society instead.
class PropertyComplaint {
  final String id;
  final String description;
  final ComplaintLocation? location;
  final ComplaintCategory category;
  final bool urgent;
  final ComplaintStatus status;
  final String? tenantName;
  final String? tenantPhone;
  final DateTime createdAt;
  // Only populated on the tenant-facing "my complaints" endpoint, which
  // spans every property a tenant has linked - the owner-facing endpoints
  // are already scoped to one property, so they don't need it.
  final String? propertyTitle;

  const PropertyComplaint({
    required this.id,
    required this.description,
    this.location,
    required this.category,
    required this.urgent,
    required this.status,
    this.tenantName,
    this.tenantPhone,
    required this.createdAt,
    this.propertyTitle,
  });

  factory PropertyComplaint.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenant'] is Map<String, dynamic> ? json['tenant'] as Map<String, dynamic> : null;
    final property = json['property'] is Map<String, dynamic> ? json['property'] as Map<String, dynamic> : null;
    return PropertyComplaint(
      id: json['_id'] as String,
      description: json['description'] as String,
      location: json['location'] != null ? ComplaintLocation.fromWire(json['location'] as String) : null,
      category: ComplaintCategory.fromWire(json['category'] as String),
      urgent: json['urgent'] as bool? ?? false,
      status: ComplaintStatus.fromWire(json['status'] as String),
      tenantName: tenant?['name'] as String?,
      tenantPhone: tenant?['phone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      propertyTitle: property?['title'] as String?,
    );
  }
}
