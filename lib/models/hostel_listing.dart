class HostelRoomOption {
  final String name;
  final String price;
  final int available;

  const HostelRoomOption({required this.name, required this.price, required this.available});
}

class HostelListing {
  final int id;
  final String emoji;
  final String title;
  final String location;
  final String price;
  final String type;
  final String gender;
  final List<String> amenities;
  final String badge;
  final double rating;
  final int reviews;

  const HostelListing({
    required this.id,
    required this.emoji,
    required this.title,
    required this.location,
    required this.price,
    required this.type,
    required this.gender,
    required this.amenities,
    required this.badge,
    required this.rating,
    required this.reviews,
  });
}

class HostelDetail {
  final int id;
  final String emoji;
  final String title;
  final String location;
  final String price;
  final String type;
  final String gender;
  final List<String> amenities;
  final String badge;
  final double rating;
  final int reviews;
  final String owner;
  final String phone;
  final List<HostelRoomOption> rooms;
  final List<String> rules;
  final String about;
  final List<String> nearby;

  const HostelDetail({
    required this.id,
    required this.emoji,
    required this.title,
    required this.location,
    required this.price,
    required this.type,
    required this.gender,
    required this.amenities,
    required this.badge,
    required this.rating,
    required this.reviews,
    required this.owner,
    required this.phone,
    required this.rooms,
    required this.rules,
    required this.about,
    required this.nearby,
  });
}
