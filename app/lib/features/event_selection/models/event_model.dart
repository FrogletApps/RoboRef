class DivisionModel {
  final int id;
  final String name;
  final int order;

  const DivisionModel({
    required this.id,
    required this.name,
    required this.order,
  });

  factory DivisionModel.fromJson(Map<String, dynamic> json) {
    return DivisionModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Default Division',
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'order': order,
      };
}

class EventModel {
  final int? id;
  final String sku;
  final String name;
  final String program;
  final String season;
  final String startDate;
  final String endDate;
  final String? venue;
  final String? city;
  final String? region;
  final String? country;
  final List<DivisionModel> divisions;

  const EventModel({
    this.id,
    required this.sku,
    required this.name,
    required this.program,
    required this.season,
    required this.startDate,
    required this.endDate,
    this.venue,
    this.city,
    this.region,
    this.country,
    this.divisions = const [],
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    var rawDivs = json['divisions'] as List<dynamic>?;
    var divs = rawDivs != null
        ? rawDivs.map((e) => DivisionModel.fromJson(e as Map<String, dynamic>)).toList()
        : <DivisionModel>[];

    var location = json['location'] as Map<String, dynamic>?;

    return EventModel(
      id: json['id'] as int?,
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      program: json['program'] is Map
          ? (json['program']['code'] as String? ?? 'V5RC')
          : (json['program'] as String? ?? 'V5RC'),
      season: json['season'] is Map
          ? (json['season']['name'] as String? ?? '2026-2027')
          : (json['season'] as String? ?? '2026-2027'),
      startDate: json['start'] as String? ?? json['startDate'] as String? ?? '',
      endDate: json['end'] as String? ?? json['endDate'] as String? ?? '',
      venue: location != null ? location['venue'] as String? : json['venue'] as String?,
      city: location != null ? location['city'] as String? : json['city'] as String?,
      region: location != null ? location['region'] as String? : json['region'] as String?,
      country: location != null ? location['country'] as String? : json['country'] as String?,
      divisions: divs,
    );
  }
}
