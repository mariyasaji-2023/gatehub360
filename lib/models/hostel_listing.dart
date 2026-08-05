String emojiForHostelType(String type) => switch (type) {
      'PG' => '🏠',
      'Hostel' => '🏨',
      'Service Apt' => '🏙️',
      'Flat' => '🏢',
      _ => '🏠',
    };

class HostelRoomOption {
  final String name;
  final num price;
  final int available;

  const HostelRoomOption({required this.name, required this.price, required this.available});

  factory HostelRoomOption.fromJson(Map<String, dynamic> json) => HostelRoomOption(
        name: json['name'] as String,
        price: json['price'] as num,
        available: json['available'] as int,
      );

  Map<String, dynamic> toJson() => {'name': name, 'price': price, 'available': available};
}

class MyHostelListing {
  final String id;
  final String type;
  final String gender;
  final String title;
  final String location;
  final String about;
  final String contact;
  final List<String> amenities;
  final List<HostelRoomOption> rooms;
  final bool active;
  final int unreadEnquiries;

  const MyHostelListing({
    required this.id,
    required this.type,
    required this.gender,
    required this.title,
    required this.location,
    required this.about,
    required this.contact,
    required this.amenities,
    required this.rooms,
    this.active = true,
    this.unreadEnquiries = 0,
  });

  String get emoji => emojiForHostelType(type);

  /// Cheapest room's price - what a browse card headlines as "starting from".
  num get startingPrice => rooms.map((r) => r.price).reduce((a, b) => a < b ? a : b);

  factory MyHostelListing.fromJson(Map<String, dynamic> json) => MyHostelListing(
        id: json['_id'] as String,
        type: json['type'] as String,
        gender: json['gender'] as String,
        title: json['title'] as String,
        location: json['location'] as String,
        about: json['about'] as String,
        contact: json['contact'] as String,
        amenities: (json['amenities'] as List? ?? []).map((a) => a as String).toList(),
        rooms: (json['rooms'] as List).map((r) => HostelRoomOption.fromJson(r as Map<String, dynamic>)).toList(),
        active: json['active'] as bool? ?? true,
        unreadEnquiries: json['unreadEnquiries'] as int? ?? 0,
      );
}

class HostelEnquiry {
  final String id;
  final String hostelTitle;
  final String clientPhone;
  final DateTime createdAt;

  const HostelEnquiry({
    required this.id,
    required this.hostelTitle,
    required this.clientPhone,
    required this.createdAt,
  });

  factory HostelEnquiry.fromJson(Map<String, dynamic> json) {
    final hostel = json['hostel'] as Map<String, dynamic>?;
    return HostelEnquiry(
      id: json['_id'] as String,
      hostelTitle: hostel?['title'] as String? ?? 'Listing',
      clientPhone: json['clientPhone'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
