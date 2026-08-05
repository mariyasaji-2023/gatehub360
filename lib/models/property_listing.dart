String emojiForPropertyType(String type) => switch (type) {
      'Apartment' => '🏢',
      'Villa' => '🏡',
      'Plot' => '🌳',
      'Commercial' => '🏬',
      _ => '🏠',
    };

class MyPropertyListing {
  final String id;
  final String type;
  final String mode;
  final String title;
  final String location;
  final String price;
  final String bhk;
  final String sqft;
  final String about;
  final String contact;
  final bool active;
  final int unreadEnquiries;

  const MyPropertyListing({
    required this.id,
    required this.type,
    required this.mode,
    required this.title,
    required this.location,
    required this.price,
    required this.bhk,
    required this.sqft,
    required this.about,
    required this.contact,
    this.active = true,
    this.unreadEnquiries = 0,
  });

  String get emoji => emojiForPropertyType(type);

  factory MyPropertyListing.fromJson(Map<String, dynamic> json) => MyPropertyListing(
        id: json['_id'] as String,
        type: json['type'] as String,
        mode: json['mode'] as String,
        title: json['title'] as String,
        location: json['location'] as String,
        price: json['price'] as String,
        bhk: json['bhk'] as String,
        sqft: json['sqft'] as String,
        about: json['about'] as String,
        contact: json['contact'] as String,
        active: json['active'] as bool? ?? true,
        unreadEnquiries: json['unreadEnquiries'] as int? ?? 0,
      );
}

class PropertyEnquiry {
  final String id;
  final String propertyTitle;
  final String clientPhone;
  final DateTime createdAt;

  const PropertyEnquiry({
    required this.id,
    required this.propertyTitle,
    required this.clientPhone,
    required this.createdAt,
  });

  factory PropertyEnquiry.fromJson(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>?;
    return PropertyEnquiry(
      id: json['_id'] as String,
      propertyTitle: property?['title'] as String? ?? 'Property',
      clientPhone: json['clientPhone'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
