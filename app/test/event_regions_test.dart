import 'package:flutter_test/flutter_test.dart';
import 'package:roboref/core/utils/event_regions.dart';

void main() {
  group('RegionDivisionConfig Tests', () {
    test('instantiates RegionDivisionConfig with correct properties', () {
      const config = RegionDivisionConfig(
        singularLabel: 'State',
        pluralLabel: 'States',
        divisions: ['California', 'Texas'],
      );

      expect(config.singularLabel, equals('State'));
      expect(config.pluralLabel, equals('States'));
      expect(config.divisions, equals(['California', 'Texas']));
    });
  });

  group('getRegionDivisionConfig Tests', () {
    test('returns null for null, empty, or "All" region', () {
      expect(getRegionDivisionConfig(null), isNull);
      expect(getRegionDivisionConfig(''), isNull);
      expect(getRegionDivisionConfig('All'), isNull);
    });

    test('returns correct config for configured regions', () {
      final usConfig = getRegionDivisionConfig('United States');
      expect(usConfig, isNotNull);
      expect(usConfig!.singularLabel, equals('State'));
      expect(usConfig.pluralLabel, equals('States'));
      expect(usConfig.divisions, contains('Texas'));

      final caConfig = getRegionDivisionConfig('Canada');
      expect(caConfig, isNotNull);
      expect(caConfig!.singularLabel, equals('Province'));
      expect(caConfig.pluralLabel, equals('Provinces'));
      expect(caConfig.divisions, contains('Ontario'));
    });

    test('returns null for regions without division configurations', () {
      expect(getRegionDivisionConfig('Japan'), isNull);
      expect(getRegionDivisionConfig('Unknown Region'), isNull);
    });
  });

  group('getSortedVexRegions Tests', () {
    test('returns sorted list of VEX regions without duplicates', () {
      final sorted = getSortedVexRegions();

      expect(sorted, isNotEmpty);
      expect(sorted, contains('United States'));
      expect(sorted, contains('Australia'));

      // Check sorting
      final copy = List<String>.from(sorted);
      copy.sort((a, b) => a.compareTo(b));
      expect(sorted, equals(copy));

      // Check deduplication
      expect(sorted.length, equals(sorted.toSet().length));
    });
  });

  group('isRegionMatchingQuery Tests', () {
    test('returns true when query is empty or whitespace', () {
      expect(isRegionMatchingQuery('United States', ''), isTrue);
      expect(isRegionMatchingQuery('United States', '   '), isTrue);
    });

    test('matches direct region name with case-insensitivity and substring', () {
      expect(isRegionMatchingQuery('United States', 'united'), isTrue);
      expect(isRegionMatchingQuery('United States', 'STATES'), isTrue);
      expect(isRegionMatchingQuery('Japan', 'jap'), isTrue);
    });

    test('matches region aliases', () {
      expect(isRegionMatchingQuery('United States', 'USA'), isTrue);
      expect(isRegionMatchingQuery('United States', 'US'), isTrue);
      expect(isRegionMatchingQuery('United Kingdom', 'UK'), isTrue);
      expect(isRegionMatchingQuery('United Kingdom', 'ENGLAND'), isTrue);
      expect(isRegionMatchingQuery('Taiwan', 'CHINESE TAIPEI'), isTrue);
    });

    test('matches child divisions (states/provinces) directly', () {
      expect(isRegionMatchingQuery('United States', 'Texas'), isTrue);
      expect(isRegionMatchingQuery('United States', 'california'), isTrue);
      expect(isRegionMatchingQuery('Canada', 'Ontario'), isTrue);
    });

    test('matches child divisions using division aliases/abbreviations', () {
      expect(isRegionMatchingQuery('United States', 'TX'), isTrue);
      expect(isRegionMatchingQuery('United States', 'CA'), isTrue);
      expect(isRegionMatchingQuery('Canada', 'ON'), isTrue);
    });

    test('returns false when query does not match region, alias, or division', () {
      expect(isRegionMatchingQuery('United States', 'InvalidQuery'), isFalse);
      expect(isRegionMatchingQuery('Japan', 'Texas'), isFalse);
      expect(isRegionMatchingQuery('Japan', 'USA'), isFalse);
    });
  });

  group('getMatchingDivisionsForRegion Tests', () {
    test('returns empty list for empty query or whitespace', () {
      expect(getMatchingDivisionsForRegion('United States', ''), isEmpty);
      expect(getMatchingDivisionsForRegion('United States', '   '), isEmpty);
    });

    test('returns empty list for regions with no division configuration', () {
      expect(getMatchingDivisionsForRegion('Japan', 'Tokyo'), isEmpty);
      expect(getMatchingDivisionsForRegion('Australia', 'Sydney'), isEmpty);
    });

    test('returns matching divisions for substring query', () {
      final matches = getMatchingDivisionsForRegion('United States', 'Cal');
      expect(matches, contains('California'));

      final caMatches = getMatchingDivisionsForRegion('Canada', 'Ont');
      expect(caMatches, contains('Ontario'));
    });

    test('returns matching divisions using division aliases/abbreviations', () {
      final matches = getMatchingDivisionsForRegion('United States', 'TX');
      expect(matches, equals(['Texas']));

      final caMatches = getMatchingDivisionsForRegion('Canada', 'ON');
      expect(caMatches, equals(['Ontario']));
    });

    test('does not produce duplicate entries when both name and alias match', () {
      // Searching 'ON' matches 'Ontario' via alias and substring
      final caMatches = getMatchingDivisionsForRegion('Canada', 'ON');
      expect(caMatches.where((e) => e == 'Ontario').length, equals(1));
    });

    test('returns empty list when query does not match any division', () {
      expect(getMatchingDivisionsForRegion('United States', 'NonExistentState'), isEmpty);
    });
  });
}
