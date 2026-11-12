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

  group('isEventInRegion Tests', () {
    test('does not match Australian New South Wales events under United Kingdom filter', () {
      expect(
        isEventInRegion(
          country: 'Australia',
          region: 'New South Wales',
          city: 'Sydney',
          venue: 'Olympic Park',
          targetRegion: 'United Kingdom',
        ),
        isFalse,
      );
      expect(
        isEventInRegion(
          country: null,
          region: 'New South Wales',
          city: 'Sydney',
          venue: null,
          targetRegion: 'United Kingdom',
        ),
        isFalse,
      );
      expect(
        isEventInRegion(
          country: 'Australia',
          region: 'New South Wales',
          city: 'Sydney',
          venue: null,
          targetRegion: 'Australia',
        ),
        isTrue,
      );
    });

    test('matches legitimate United Kingdom events across constituent nations and aliases', () {
      for (final country in ['United Kingdom', 'Great Britain', 'UK', 'GB']) {
        expect(
          isEventInRegion(
            country: country,
            region: 'England',
            city: 'Telford',
            venue: null,
            targetRegion: 'United Kingdom',
          ),
          isTrue,
        );
      }
      for (final nation in ['England', 'Scotland', 'Wales', 'Northern Ireland', 'United Kingdom']) {
        expect(
          isEventInRegion(
            country: null,
            region: nation,
            city: null,
            venue: null,
            targetRegion: 'United Kingdom',
          ),
          isTrue,
        );
      }
    });

    test('prevents substring bleed across countries, regions, cities, and venues', () {
      // Ukraine must not match UK
      expect(
        isEventInRegion(
          country: 'Ukraine',
          region: 'Kyiv',
          city: 'Kyiv',
          venue: null,
          targetRegion: 'United Kingdom',
        ),
        isFalse,
      );
      // New England (US) must not match UK
      expect(
        isEventInRegion(
          country: 'United States',
          region: 'New England',
          city: 'Boston',
          venue: null,
          targetRegion: 'United Kingdom',
        ),
        isFalse,
      );
      // New Mexico (US) must not match Mexico
      expect(
        isEventInRegion(
          country: 'United States',
          region: 'New Mexico',
          city: 'Albuquerque',
          venue: null,
          targetRegion: 'Mexico',
        ),
        isFalse,
      );
      // Northern Ireland (UK) must not match Ireland
      expect(
        isEventInRegion(
          country: 'United Kingdom',
          region: 'Northern Ireland',
          city: 'Belfast',
          venue: null,
          targetRegion: 'Ireland',
        ),
        isFalse,
      );
      // Romania must not match Oman
      expect(
        isEventInRegion(
          country: 'Romania',
          region: 'Bucharest',
          city: 'Bucharest',
          venue: null,
          targetRegion: 'Oman',
        ),
        isFalse,
      );
      // City/venue names containing country names must not match when country differs
      expect(
        isEventInRegion(
          country: 'United States',
          region: 'Utah',
          city: 'West Jordan',
          venue: 'Jordan High School',
          targetRegion: 'Jordan',
        ),
        isFalse,
      );
      expect(
        isEventInRegion(
          country: 'United States',
          region: 'Indiana',
          city: 'Brazil',
          venue: 'Northview High School',
          targetRegion: 'Brazil',
        ),
        isFalse,
      );
      // Hong Kong and Taiwan must not match China
      expect(
        isEventInRegion(
          country: 'Hong Kong',
          region: 'Hong Kong',
          city: 'Hong Kong',
          venue: null,
          targetRegion: 'China',
        ),
        isFalse,
      );
    });

    test('handles Taiwan / Chinese Taipei and other official country variants', () {
      expect(
        isEventInRegion(
          country: 'Chinese Taipei',
          region: 'Taiwan',
          city: 'Taipei',
          venue: null,
          targetRegion: 'Taiwan',
        ),
        isTrue,
      );
      expect(
        isEventInRegion(
          country: 'Türkiye',
          region: 'Istanbul',
          city: 'Istanbul',
          venue: null,
          targetRegion: 'Turkey',
        ),
        isTrue,
      );
      expect(
        isEventInRegion(
          country: 'Korea, Republic of',
          region: 'Seoul',
          city: 'Seoul',
          venue: null,
          targetRegion: 'South Korea',
        ),
        isTrue,
      );
    });

    test('handles missing country with US/Canada division codes without colliding with ISO-2 countries', () {
      // 'CA' in region means California (US), not Canada
      expect(
        isEventInRegion(
          country: null,
          region: 'CA',
          city: 'Los Angeles',
          venue: null,
          targetRegion: 'United States',
        ),
        isTrue,
      );
      expect(
        isEventInRegion(
          country: null,
          region: 'CA',
          city: 'Los Angeles',
          venue: null,
          targetRegion: 'Canada',
        ),
        isFalse,
      );
      // 'DE' in region means Delaware (US), not Germany
      expect(
        isEventInRegion(
          country: null,
          region: 'DE',
          city: 'Wilmington',
          venue: null,
          targetRegion: 'Germany',
        ),
        isFalse,
      );
    });
  });

  group('isEventInDivision Tests', () {
    test('avoids substring false positives and supports state/province abbreviations', () {
      expect(
        isEventInDivision(
          region: 'West Virginia',
          city: 'Charleston',
          venue: null,
          targetDivision: 'Virginia',
        ),
        isFalse,
      );
      expect(
        isEventInDivision(
          region: 'Arkansas',
          city: 'Little Rock',
          venue: null,
          targetDivision: 'Kansas',
        ),
        isFalse,
      );
      expect(
        isEventInDivision(
          region: 'Missouri',
          city: 'Kansas City',
          venue: 'Kansas City Convention Center',
          targetDivision: 'Kansas',
        ),
        isFalse,
      );
      expect(
        isEventInDivision(
          region: 'District of Columbia',
          city: 'Washington',
          venue: 'Washington Convention Center',
          targetDivision: 'Washington',
        ),
        isFalse,
      );
      expect(
        isEventInDivision(
          region: 'TX',
          city: 'Austin',
          venue: null,
          targetDivision: 'Texas',
        ),
        isTrue,
      );
      expect(
        isEventInDivision(
          region: 'ON',
          city: 'Toronto',
          venue: null,
          targetDivision: 'Ontario',
        ),
        isTrue,
      );
    });
  });

  group('isEventMatchingRegionAndDivisions Tests', () {
    test('empty selection matches all events and multi-region matches any selected region', () {
      expect(
        isEventMatchingRegionAndDivisions(
          country: 'Germany',
          region: 'Bavaria',
          city: 'Munich',
          venue: null,
        ),
        isTrue,
      );

      const regions = ['United Kingdom', 'France'];
      expect(
        isEventMatchingRegionAndDivisions(
          country: 'United Kingdom',
          region: 'England',
          city: 'London',
          venue: null,
          selectedRegions: regions,
        ),
        isTrue,
      );
      expect(
        isEventMatchingRegionAndDivisions(
          country: 'France',
          region: 'Île-de-France',
          city: 'Paris',
          venue: null,
          selectedRegions: regions,
        ),
        isTrue,
      );
      expect(
        isEventMatchingRegionAndDivisions(
          country: 'Germany',
          region: 'Bavaria',
          city: 'Munich',
          venue: null,
          selectedRegions: regions,
        ),
        isFalse,
      );
    });

    test('scopes selected divisions per parent region cleanly', () {
      // United States has Texas selected, Canada has no division selected ->
      // US events must be in Texas, while all Canada & UK events still match.
      const regions = ['United States', 'Canada', 'United Kingdom'];
      const divisions = ['Texas'];

      expect(
        isEventMatchingRegionAndDivisions(
          country: 'United States',
          region: 'Texas',
          city: 'Dallas',
          venue: null,
          selectedRegions: regions,
          selectedDivisions: divisions,
        ),
        isTrue,
      );
      expect(
        isEventMatchingRegionAndDivisions(
          country: 'United States',
          region: 'Florida',
          city: 'Orlando',
          venue: null,
          selectedRegions: regions,
          selectedDivisions: divisions,
        ),
        isFalse,
      );
      expect(
        isEventMatchingRegionAndDivisions(
          country: 'Canada',
          region: 'Ontario',
          city: 'Toronto',
          venue: null,
          selectedRegions: regions,
          selectedDivisions: divisions,
        ),
        isTrue,
      );
      expect(
        isEventMatchingRegionAndDivisions(
          country: 'United Kingdom',
          region: 'England',
          city: 'Telford',
          venue: null,
          selectedRegions: regions,
          selectedDivisions: divisions,
        ),
        isTrue,
      );
      expect(
        isEventMatchingRegionAndDivisions(
          country: 'Germany',
          region: 'Bavaria',
          city: 'Munich',
          venue: null,
          selectedRegions: regions,
          selectedDivisions: divisions,
        ),
        isFalse,
      );
    });

    test('supports multiple divisions across multiple regions simultaneously', () {
      const regions = ['United States', 'Canada'];
      const divisions = ['Texas', 'California', 'Ontario'];

      expect(
        isEventMatchingRegionAndDivisions(
          country: 'United States',
          region: 'California',
          city: 'Los Angeles',
          venue: null,
          selectedRegions: regions,
          selectedDivisions: divisions,
        ),
        isTrue,
      );
      expect(
        isEventMatchingRegionAndDivisions(
          country: 'Canada',
          region: 'Ontario',
          city: 'Toronto',
          venue: null,
          selectedRegions: regions,
          selectedDivisions: divisions,
        ),
        isTrue,
      );
      expect(
        isEventMatchingRegionAndDivisions(
          country: 'Canada',
          region: 'Quebec',
          city: 'Montreal',
          venue: null,
          selectedRegions: regions,
          selectedDivisions: divisions,
        ),
        isFalse,
      );
    });
  });
}
