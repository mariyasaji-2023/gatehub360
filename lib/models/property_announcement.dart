/// A property owner's broadcast message to their tenants — same idea as
/// [SocietyNotice], but scoped to a property. Only ever fetched for tenants
/// who've actually joined that property (linked their account with the
/// owner-shared join code), so seeing one already implies membership.
class PropertyAnnouncement {
  final String id;
  final String title;
  final String message;
  final String? propertyTitle;
  final DateTime createdAt;

  const PropertyAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    this.propertyTitle,
    required this.createdAt,
  });

  factory PropertyAnnouncement.fromJson(Map<String, dynamic> json) {
    // `property` is only a populated object on the tenant-side endpoint
    // (which aggregates across properties, so needs the title to label
    // each card) - the owner-side endpoint just returns raw announcements
    // for a single already-known property.
    final property = json['property'] is Map<String, dynamic> ? json['property'] as Map<String, dynamic> : null;
    return PropertyAnnouncement(
      id: json['_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      propertyTitle: property?['title'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
