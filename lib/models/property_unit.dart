/// A single trackable bed/unit under a property floor - created in bulk from
/// an `AddUnitsScreen` row, then individually flippable between vacant and
/// occupied.
class PropertyUnit {
  final String id;
  final String floor;
  final String type;
  final String label;
  final int beds;
  final String status;

  const PropertyUnit({
    required this.id,
    required this.floor,
    required this.type,
    required this.label,
    required this.beds,
    required this.status,
  });

  bool get isOccupied => status == 'occupied';

  PropertyUnit copyWith({String? status}) => PropertyUnit(
        id: id,
        floor: floor,
        type: type,
        label: label,
        beds: beds,
        status: status ?? this.status,
      );

  factory PropertyUnit.fromJson(Map<String, dynamic> json) => PropertyUnit(
        id: json['_id'] as String,
        floor: json['floor'] as String,
        type: json['type'] as String,
        label: json['label'] as String,
        beds: json['beds'] as int,
        status: json['status'] as String,
      );
}

/// One row from the "Add Units" stepper - `count` individual [PropertyUnit]s
/// are created from it.
class UnitRowInput {
  final String type;
  final String label;
  final int beds;
  final int count;

  const UnitRowInput({required this.type, required this.label, required this.beds, required this.count});

  Map<String, dynamic> toJson() => {'type': type, 'label': label, 'beds': beds, 'count': count};
}

class FloorVacancy {
  final String floor;
  final int totalUnits;
  final int totalBeds;
  final int occupiedUnits;
  final int vacantUnits;

  const FloorVacancy({
    required this.floor,
    required this.totalUnits,
    required this.totalBeds,
    required this.occupiedUnits,
    required this.vacantUnits,
  });

  factory FloorVacancy.fromJson(Map<String, dynamic> json) => FloorVacancy(
        floor: json['floor'] as String,
        totalUnits: json['totalUnits'] as int,
        totalBeds: json['totalBeds'] as int,
        occupiedUnits: json['occupiedUnits'] as int,
        vacantUnits: json['vacantUnits'] as int,
      );
}

/// Full vacancy picture for one property - powers the floors overview and
/// the property dashboard's occupancy stats.
class VacancySummary {
  final List<FloorVacancy> floors;
  final int totalFloors;
  final int filledFloors;
  final int totalUnits;
  final int totalBeds;
  final int occupiedUnits;
  final int vacantUnits;
  final DateTime? vacancyPublishedAt;

  const VacancySummary({
    required this.floors,
    required this.totalFloors,
    required this.filledFloors,
    required this.totalUnits,
    required this.totalBeds,
    required this.occupiedUnits,
    required this.vacantUnits,
    this.vacancyPublishedAt,
  });

  factory VacancySummary.fromJson(Map<String, dynamic> json) => VacancySummary(
        floors: (json['floors'] as List).map((f) => FloorVacancy.fromJson(f as Map<String, dynamic>)).toList(),
        totalFloors: json['totalFloors'] as int,
        filledFloors: json['filledFloors'] as int,
        totalUnits: json['totalUnits'] as int,
        totalBeds: json['totalBeds'] as int,
        occupiedUnits: json['occupiedUnits'] as int,
        vacantUnits: json['vacantUnits'] as int,
        vacancyPublishedAt:
            json['vacancyPublishedAt'] != null ? DateTime.parse(json['vacancyPublishedAt'] as String) : null,
      );
}
