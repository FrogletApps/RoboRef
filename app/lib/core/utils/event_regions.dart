import 'package:flutter/widgets.dart';
import '../l10n/l10n.dart';
import 'event_region_matcher.dart';

export 'event_region_matcher.dart';

/// Configuration for a region's administrative divisions (e.g. States, Provinces)
class RegionDivisionConfig {
  final String singularLabel; // e.g. "State", "Province"
  final String pluralLabel;   // e.g. "States", "Provinces"
  final List<String> divisions;

  const RegionDivisionConfig({
    required this.singularLabel,
    required this.pluralLabel,
    required this.divisions,
  });

  String allLabel(BuildContext context) {
    final l10n = context.l10n;
    switch (singularLabel) {
      case 'State':
        return l10n.eventSelectionAllStates;
      case 'Province':
        return l10n.eventSelectionAllProvinces;
      default:
        return l10n.eventSelectionAllDivisions(pluralLabel);
    }
  }

  String selectedLabel(BuildContext context, String division) {
    final l10n = context.l10n;
    switch (singularLabel) {
      case 'State':
        return l10n.eventSelectionStateSelected(division);
      case 'Province':
        return l10n.eventSelectionProvinceSelected(division);
      default:
        return l10n.eventSelectionDivisionSelected(singularLabel, division);
    }
  }

  String selectedMultiLabel(BuildContext context, List<String> divisions) {
    if (divisions.isEmpty) return allLabel(context);
    if (divisions.length == 1) return selectedLabel(context, divisions.first);
    final l10n = context.l10n;
    switch (singularLabel) {
      case 'State':
        return l10n.eventSelectionStatesSelected(divisions.length);
      case 'Province':
        return l10n.eventSelectionProvincesSelected(divisions.length);
      default:
        return l10n.eventSelectionDivisionsSelected(pluralLabel, divisions.length);
    }
  }

  String filterByTitle(BuildContext context) {
    final l10n = context.l10n;
    switch (singularLabel) {
      case 'State':
        return l10n.eventSelectionFilterByState;
      case 'Province':
        return l10n.eventSelectionFilterByProvince;
      default:
        return l10n.eventSelectionFilterByDivision(singularLabel);
    }
  }

  String searchHint(BuildContext context) {
    final l10n = context.l10n;
    switch (singularLabel) {
      case 'State':
        return l10n.eventSelectionSearchStatesHint;
      case 'Province':
        return l10n.eventSelectionSearchProvincesHint;
      default:
        return l10n.eventSelectionSearchDivisionsHint(pluralLabel.toLowerCase());
    }
  }

  String noMatchingLabel(BuildContext context, String query) {
    final l10n = context.l10n;
    switch (singularLabel) {
      case 'State':
        return l10n.eventSelectionNoStatesMatching(query);
      case 'Province':
        return l10n.eventSelectionNoProvincesMatching(query);
      default:
        return l10n.eventSelectionNoDivisionsMatching(
          pluralLabel.toLowerCase(),
          query,
        );
    }
  }
}

// Backwards compatibility alias
typedef CountryDivisionConfig = RegionDivisionConfig;

/// Official list of regions hosting VEX Robotics events
const List<String> vexRegions = [
  "Australia",
  "Bahrain",
  "Brazil",
  "Canada",
  "Chile",
  "China",
  "Colombia",
  "Egypt",
  "Ethiopia",
  "Finland",
  "France",
  "Germany",
  "Hong Kong",
  "Ireland",
  "Japan",
  "Jordan",
  "Macao",
  "Malaysia",
  "Mexico",
  "Morocco",
  "Netherlands",
  "New Zealand",
  "Oman",
  "Paraguay",
  "Philippines",
  "Saudi Arabia",
  "Singapore",
  "South Korea",
  "Spain",
  "Switzerland",
  "Taiwan",
  "Thailand",
  "Tunisia",
  "Turkey",
  "United Arab Emirates",
  "United Kingdom",
  "United States",
  "Vietnam",
];

// Backwards compatibility alias
const List<String> vexCountries = vexRegions;

/// Region-specific division lists with local terminology
const Map<String, RegionDivisionConfig> vexRegionDivisions = {
  'United States': RegionDivisionConfig(
    singularLabel: 'State',
    pluralLabel: 'States',
    divisions: usDivisions,
  ),
  'Canada': RegionDivisionConfig(
    singularLabel: 'Province',
    pluralLabel: 'Provinces',
    divisions: canadaDivisions,
  ),
};

// Backwards compatibility alias
const Map<String, RegionDivisionConfig> vexCountryDivisions = vexRegionDivisions;

/// Get division configuration for a region, or null if no division list is configured
RegionDivisionConfig? getRegionDivisionConfig(String? region) {
  if (region == null || region.isEmpty || region == 'All') return null;
  return vexRegionDivisions[region];
}

// Backwards compatibility alias
RegionDivisionConfig? getCountryDivisionConfig(String? country) => getRegionDivisionConfig(country);

/// Deduplicated and alphabetically sorted list of all VEX regions
List<String> getSortedVexRegions() {
  final set = vexRegions.toSet();
  final list = set.toList();
  list.sort((a, b) => a.compareTo(b));
  return list;
}

// Backwards compatibility alias
List<String> getSortedVexCountries() => getSortedVexRegions();

// Backwards compatibility alias
const Map<String, String> countryAliases = regionAliases;

/// Checks whether a region matches a query string by direct name, alias, or child division (e.g. state or province).
bool isRegionMatchingQuery(String region, String query) {
  final cleanQuery = query.trim().toUpperCase();
  if (cleanQuery.isEmpty) return true;

  final regionUpper = region.toUpperCase();
  // 1. Direct region name match (e.g. "United", "Can", "Japan")
  if (regionUpper.contains(cleanQuery)) return true;

  // 2. Region alias match (e.g. "USA" -> "United States", "England" -> "United Kingdom")
  final aliasTarget = regionAliases[cleanQuery]?.toUpperCase();
  if (aliasTarget != null && (regionUpper == aliasTarget || regionUpper.contains(aliasTarget))) {
    return true;
  }

  // 3. Child division match (state / province)
  final divConfig = vexRegionDivisions[region];
  if (divConfig != null) {
    // Check if any state/province contains the query (e.g. "Texas", "California", "Ontario")
    final hasDirectDivisionMatch = divConfig.divisions.any(
      (d) => d.toUpperCase().contains(cleanQuery),
    );
    if (hasDirectDivisionMatch) return true;

    // Check if query is a division abbreviation (e.g. "TX" -> "Texas", "ON" -> "Ontario")
    final aliasedDivision = divisionAliases[cleanQuery]?.toUpperCase();
    if (aliasedDivision != null) {
      final hasAliasedDivisionMatch = divConfig.divisions.any(
        (d) => d.toUpperCase() == aliasedDivision || d.toUpperCase().contains(aliasedDivision),
      );
      if (hasAliasedDivisionMatch) return true;
    }
  }

  return false;
}

/// Returns list of matching division names (e.g. states/provinces) for a region and query.
List<String> getMatchingDivisionsForRegion(String region, String query) {
  final cleanQuery = query.trim().toUpperCase();
  if (cleanQuery.isEmpty) return const [];

  final divConfig = vexRegionDivisions[region];
  if (divConfig == null) return const [];

  final matches = <String>[];
  for (final div in divConfig.divisions) {
    if (div.toUpperCase().contains(cleanQuery)) {
      matches.add(div);
    }
  }

  final aliasedDivision = divisionAliases[cleanQuery];
  if (aliasedDivision != null && divConfig.divisions.contains(aliasedDivision)) {
    if (!matches.contains(aliasedDivision)) {
      matches.add(aliasedDivision);
    }
  }

  return matches;
}

/// Checks whether an event matches multi-select [selectedRegions] and [selectedDivisions].
///
/// An empty [selectedRegions] matches all regions (and if [selectedDivisions] is also empty, all events).
/// When multiple regions are selected, each region's division filters only constrain events within that region.
bool isEventMatchingRegionAndDivisions({
  required String? country,
  required String? region,
  required String? city,
  required String? venue,
  Iterable<String> selectedRegions = const [],
  Iterable<String> selectedDivisions = const [],
}) {
  final regions = selectedRegions
      .map((r) => r.trim())
      .where((r) => r.isNotEmpty && r != 'All')
      .toList();
  final divisions = selectedDivisions
      .map((d) => d.trim())
      .where((d) => d.isNotEmpty && d != 'All')
      .toList();

  if (regions.isEmpty) {
    if (divisions.isEmpty) return true;
    return divisions.any(
      (d) => isEventInDivision(
        region: region,
        city: city,
        venue: venue,
        targetDivision: d,
      ),
    );
  }

  for (final r in regions) {
    if (!isEventInRegion(
      country: country,
      region: region,
      city: city,
      venue: venue,
      targetRegion: r,
    )) {
      continue;
    }

    final divConfig = getRegionDivisionConfig(r);
    if (divConfig == null) {
      return true;
    }

    final activeDivsForRegion = divisions.where((d) => divConfig.divisions.contains(d)).toList();
    if (activeDivsForRegion.isEmpty) {
      return true;
    }

    if (activeDivsForRegion.any(
      (d) => isEventInDivision(
        region: region,
        city: city,
        venue: venue,
        targetDivision: d,
      ),
    )) {
      return true;
    }
  }

  return false;
}

