class PropertyListing {
  final int id;
  final String emoji;
  final String title;
  final String location;
  final String price;
  final String type;
  final String bhk;
  final String sqft;
  final String status;
  final String badge;

  const PropertyListing({
    required this.id,
    required this.emoji,
    required this.title,
    required this.location,
    required this.price,
    required this.type,
    required this.bhk,
    required this.sqft,
    required this.status,
    required this.badge,
  });
}

class PropertyPriceBreakdown {
  final String base;
  final String registration;
  final String other;
  final String total;

  const PropertyPriceBreakdown({
    required this.base,
    required this.registration,
    required this.other,
    required this.total,
  });

  List<MapEntry<String, String>> get entries => [
        MapEntry('Base Price', base),
        MapEntry('Registration & Stamp Duty', registration),
        MapEntry('Other Charges', other),
        MapEntry('Total Cost', total),
      ];
}

class PropertyDetail {
  final int id;
  final String emoji;
  final String title;
  final String location;
  final String price;
  final String type;
  final String bhk;
  final String sqft;
  final String floor;
  final String status;
  final String badge;
  final String builder;
  final String facing;
  final String age;
  final String about;
  final List<String> amenities;
  final PropertyPriceBreakdown priceBreakdown;
  final String contact;

  const PropertyDetail({
    required this.id,
    required this.emoji,
    required this.title,
    required this.location,
    required this.price,
    required this.type,
    required this.bhk,
    required this.sqft,
    required this.floor,
    required this.status,
    required this.badge,
    required this.builder,
    required this.facing,
    required this.age,
    required this.about,
    required this.amenities,
    required this.priceBreakdown,
    required this.contact,
  });
}
