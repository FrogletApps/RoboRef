import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:roboref/core/utils/event_regions.dart';
import 'package:roboref/core/utils/sku_utils.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en_US');
    await initializeDateFormatting('en_GB');
  });

  group('SKU Utils Tests', () {
    test('Validates official VEX SKUs correctly', () {
      expect(isValidSku('RE-V5RC-24-8909'), isTrue);
      expect(isValidSku('RE-VIQRC-24-8913'), isTrue);
      expect(isValidSku('RE-VURC-24-8911'), isTrue);
      expect(isValidSku('RE-VAIRC-24-8912'), isTrue);
      expect(isValidSku('re-vrc-24-1234'), isTrue);

      // VE event codes (4, 5, and 6 digit IDs)
      expect(isValidSku('VE-IQ-26-65627'), isTrue);
      expect(isValidSku('VE-V5-26-65764'), isTrue);
      expect(isValidSku('VE-U-26-65535'), isTrue);
      expect(isValidSku('VE-AI-26-1234'), isTrue);
      expect(isValidSku('ve-iq-26-65627'), isTrue);
      expect(isValidSku('ve-v5-26-65764'), isTrue);
      expect(isValidSku('VE-IQ-24-1234'), isTrue);
      expect(isValidSku('VE-V5-24-1234'), isTrue);
      expect(isValidSku('VE-U-24-1234'), isTrue);

      expect(isValidSku('INVALID-SKU'), isFalse);
      expect(isValidSku('RE-ADC-24-9001'), isFalse);
      expect(isValidSku('VE-ADC-24-9001'), isFalse);
      expect(isValidSku('RE-V5RC-24'), isFalse);
      expect(isValidSku('VE-V5-24'), isFalse);
      expect(isValidSku('RE-UNKNOWN-24-1234'), isFalse);
      expect(isValidSku('VE-UNKNOWN-24-1234'), isFalse);
      expect(isValidSku('VE-IQ-24-123'), isFalse);
    });

    test('Detects VIQRC, VAIRC, VEX U, and V5 programs across RE and VE codes', () {
      // VIQRC
      expect(isVIQRC('RE-VIQRC-24-8913'), isTrue);
      expect(isVIQRC('RE-VIQC-24-8913'), isTrue);
      expect(isVIQRC('VE-IQ-26-65627'), isTrue);
      expect(isVIQRC('VE-IQ-24-1234'), isTrue);
      expect(isVIQRC('RE-V5RC-24-8909'), isFalse);
      expect(isVIQRC('VE-V5-26-65764'), isFalse);

      // VAIRC
      expect(isVAIRC('RE-VAIRC-24-8912'), isTrue);
      expect(isVAIRC('VE-AI-26-1234'), isTrue);
      expect(isVAIRC('RE-V5RC-24-8909'), isFalse);
      expect(isVAIRC('VE-V5-26-65764'), isFalse);

      // VEX U
      expect(isVEXU('RE-VURC-24-8911'), isTrue);
      expect(isVEXU('RE-VEXU-24-8911'), isTrue);
      expect(isVEXU('VE-U-26-65535'), isTrue);
      expect(isVEXU('VE-U-24-1234'), isTrue);
      expect(isVEXU('RE-V5RC-24-8909'), isFalse);
      expect(isVEXU('VE-V5-26-65764'), isFalse);

      // V5
      expect(isV5('RE-V5RC-24-8909'), isTrue);
      expect(isV5('RE-VRC-24-1234'), isTrue);
      expect(isV5('RE-VURC-24-8911'), isTrue);
      expect(isV5('VE-V5-26-65764'), isTrue);
      expect(isV5('VE-V5-24-1234'), isTrue);
      expect(isV5('VE-U-26-65535'), isTrue);
      expect(isV5('RE-VIQRC-24-8913'), isFalse);
      expect(isV5('VE-IQ-26-65627'), isFalse);

      // getSkuProgram
      expect(getSkuProgram('RE-V5RC-24-8909'), equals('V5RC'));
      expect(getSkuProgram('VE-V5-26-65764'), equals('V5RC'));
      expect(getSkuProgram('RE-VIQRC-24-8913'), equals('VIQRC'));
      expect(getSkuProgram('VE-IQ-26-65627'), equals('VIQRC'));
      expect(getSkuProgram('RE-VURC-24-8911'), equals('VEX U'));
      expect(getSkuProgram('VE-U-26-65535'), equals('VEX U'));
      expect(getSkuProgram('RE-VAIRC-24-8912'), equals('VEX AI'));
      expect(getSkuProgram('VE-AI-26-1234'), equals('VEX AI'));
    });

    test('isSkuQuery identifies SKU query prefixes', () {
      expect(isSkuQuery('RE-V5RC-24-8909'), isTrue);
      expect(isSkuQuery('re-viqrc'), isTrue);
      expect(isSkuQuery('RE-'), isTrue);
      expect(isSkuQuery('VE-IQ-26-65627'), isTrue);
      expect(isSkuQuery('ve-v5'), isTrue);
      expect(isSkuQuery('VE-'), isTrue);
      expect(isSkuQuery('Dallas Championship'), isFalse);
      expect(isSkuQuery(''), isFalse);
      expect(isSkuQuery(null), isFalse);
    });

    test('getSkuColor returns corresponding program color', () {
      // VIQRC -> Blue
      expect(getSkuColor('RE-VIQRC-24-8913'), equals(const Color(0xFF42A5F5)));
      expect(getSkuColor('VE-IQ-26-65627'), equals(const Color(0xFF42A5F5)));

      // VAIRC -> Purple
      expect(getSkuColor('RE-VAIRC-24-8912'), equals(const Color(0xFFAB47BC)));
      expect(getSkuColor('VE-AI-26-1234'), equals(const Color(0xFFAB47BC)));

      // V5RC & VEX U -> Red
      expect(getSkuColor('RE-V5RC-24-8909'), equals(const Color(0xFFEF5350)));
      expect(getSkuColor('VE-V5-26-65764'), equals(const Color(0xFFEF5350)));
      expect(getSkuColor('VE-U-26-65535'), equals(const Color(0xFFEF5350)));
    });

    test('Formats date ranges accurately in user locale', () {
      final usFormatted = formatEventDateRange('2026-04-25T08:00:00Z', '2026-04-28T18:00:00Z', 'en_US');
      expect(usFormatted, contains('Apr 25'));
      expect(usFormatted, contains('Apr 28, 2026'));

      final gbFormatted = formatEventDateRange('2026-04-25T08:00:00Z', '2026-04-28T18:00:00Z', 'en_GB');
      expect(gbFormatted, contains('25 Apr'));
      expect(gbFormatted, contains('28 Apr 2026'));

      final singleDay = formatEventDateRange('2026-05-01T08:00:00Z', '2026-05-01T17:00:00Z', 'en_US');
      expect(singleDay, equals('May 1, 2026'));

      final singleDayGb = formatEventDateRange('2026-05-01T08:00:00Z', '2026-05-01T17:00:00Z', 'en_GB');
      expect(singleDayGb, equals('1 May 2026'));

      final dateGb = formatEventDate('2026-04-25T08:00:00Z', 'en_GB');
      expect(dateGb, equals('25 Apr 2026'));
    });

    test('isEventMatchingProgram accurately filters events by program', () {
      // VIQRC event (RE & VE)
      expect(isEventMatchingProgram(program: 'VIQRC', sku: 'RE-VIQRC-24-8913', selectedProgram: 'All'), isTrue);
      expect(isEventMatchingProgram(program: 'VIQRC', sku: 'RE-VIQRC-24-8913', selectedProgram: 'VIQRC'), isTrue);
      expect(isEventMatchingProgram(program: 'VIQRC', sku: 'RE-VIQRC-24-8913', selectedProgram: 'V5RC'), isFalse);
      expect(isEventMatchingProgram(program: 'VIQRC', sku: 'RE-VIQRC-24-8913', selectedProgram: 'VEX U'), isFalse);
      expect(isEventMatchingProgram(program: 'VIQRC', sku: 'RE-VIQRC-24-8913', selectedProgram: 'VEX AI'), isFalse);

      expect(isEventMatchingProgram(program: 'VIQRC', sku: 'VE-IQ-26-65627', selectedProgram: 'All'), isTrue);
      expect(isEventMatchingProgram(program: 'VIQRC', sku: 'VE-IQ-26-65627', selectedProgram: 'VIQRC'), isTrue);
      expect(isEventMatchingProgram(program: 'VE-IQ', sku: 'VE-IQ-26-65627', selectedProgram: 'VIQRC'), isTrue);
      expect(isEventMatchingProgram(program: 'VIQRC', sku: 'VE-IQ-26-65627', selectedProgram: 'V5RC'), isFalse);

      // V5RC event (RE & VE)
      expect(isEventMatchingProgram(program: 'V5RC', sku: 'RE-V5RC-24-8909', selectedProgram: 'All'), isTrue);
      expect(isEventMatchingProgram(program: 'V5RC', sku: 'RE-V5RC-24-8909', selectedProgram: 'V5RC'), isTrue);
      expect(isEventMatchingProgram(program: 'V5RC', sku: 'RE-V5RC-24-8909', selectedProgram: 'VIQRC'), isFalse);
      expect(isEventMatchingProgram(program: 'V5RC', sku: 'RE-V5RC-24-8909', selectedProgram: 'VEX U'), isFalse);
      expect(isEventMatchingProgram(program: 'V5RC', sku: 'RE-V5RC-24-8909', selectedProgram: 'VEX AI'), isFalse);

      expect(isEventMatchingProgram(program: 'V5RC', sku: 'VE-V5-26-65764', selectedProgram: 'All'), isTrue);
      expect(isEventMatchingProgram(program: 'V5RC', sku: 'VE-V5-26-65764', selectedProgram: 'V5RC'), isTrue);
      expect(isEventMatchingProgram(program: 'VE-V5', sku: 'VE-V5-26-65764', selectedProgram: 'V5RC'), isTrue);
      expect(isEventMatchingProgram(program: 'V5RC', sku: 'VE-V5-26-65764', selectedProgram: 'VIQRC'), isFalse);

      // VEX U (VURC & VE-U) event
      expect(isEventMatchingProgram(program: 'VURC', sku: 'RE-VURC-24-8911', selectedProgram: 'All'), isTrue);
      expect(isEventMatchingProgram(program: 'VURC', sku: 'RE-VURC-24-8911', selectedProgram: 'VEX U'), isTrue);
      expect(isEventMatchingProgram(program: 'VURC', sku: 'RE-VURC-24-8911', selectedProgram: 'V5RC'), isFalse);
      expect(isEventMatchingProgram(program: 'VURC', sku: 'RE-VURC-24-8911', selectedProgram: 'VIQRC'), isFalse);

      expect(isEventMatchingProgram(program: 'VURC', sku: 'VE-U-26-65535', selectedProgram: 'All'), isTrue);
      expect(isEventMatchingProgram(program: 'VURC', sku: 'VE-U-26-65535', selectedProgram: 'VEX U'), isTrue);
      expect(isEventMatchingProgram(program: 'VE-U', sku: 'VE-U-26-65535', selectedProgram: 'VEX U'), isTrue);
      expect(isEventMatchingProgram(program: 'VURC', sku: 'VE-U-26-65535', selectedProgram: 'V5RC'), isFalse);

      // VEX AI (VAIRC & VE-AI) event
      expect(isEventMatchingProgram(program: 'VAIRC', sku: 'RE-VAIRC-24-8912', selectedProgram: 'All'), isTrue);
      expect(isEventMatchingProgram(program: 'VAIRC', sku: 'RE-VAIRC-24-8912', selectedProgram: 'VEX AI'), isTrue);
      expect(isEventMatchingProgram(program: 'VAIRC', sku: 'RE-VAIRC-24-8912', selectedProgram: 'V5RC'), isFalse);
      expect(isEventMatchingProgram(program: 'VAIRC', sku: 'RE-VAIRC-24-8912', selectedProgram: 'VIQRC'), isFalse);

      expect(isEventMatchingProgram(program: 'VAIRC', sku: 'VE-AI-26-1234', selectedProgram: 'All'), isTrue);
      expect(isEventMatchingProgram(program: 'VAIRC', sku: 'VE-AI-26-1234', selectedProgram: 'VEX AI'), isTrue);
      expect(isEventMatchingProgram(program: 'VE-AI', sku: 'VE-AI-26-1234', selectedProgram: 'VEX AI'), isTrue);
      expect(isEventMatchingProgram(program: 'VAIRC', sku: 'VE-AI-26-1234', selectedProgram: 'V5RC'), isFalse);
    });

    test('isRegionMatchingQuery matches regions by direct name, alias, or child division (state/province)', () {
      // Direct region name
      expect(isRegionMatchingQuery('United States', 'United States'), isTrue);
      expect(isRegionMatchingQuery('United States', 'unit'), isTrue);
      expect(isRegionMatchingQuery('Canada', 'Can'), isTrue);

      // State / Province names -> parent country
      expect(isRegionMatchingQuery('United States', 'Texas'), isTrue);
      expect(isRegionMatchingQuery('United States', 'tex'), isTrue);
      expect(isRegionMatchingQuery('United States', 'California'), isTrue);
      expect(isRegionMatchingQuery('Canada', 'Ontario'), isTrue);
      expect(isRegionMatchingQuery('Canada', 'Alberta'), isTrue);

      // State / Province abbreviations -> parent country
      expect(isRegionMatchingQuery('United States', 'TX'), isTrue);
      expect(isRegionMatchingQuery('United States', 'CA'), isTrue);
      expect(isRegionMatchingQuery('Canada', 'ON'), isTrue);

      // Non-matching state queries
      expect(isRegionMatchingQuery('Australia', 'Texas'), isFalse);
      expect(isRegionMatchingQuery('Japan', 'Ontario'), isFalse);

      // Country aliases
      expect(isRegionMatchingQuery('United States', 'USA'), isTrue);
      expect(isRegionMatchingQuery('United Kingdom', 'UK'), isTrue);
      expect(isRegionMatchingQuery('United Kingdom', 'England'), isTrue);
      expect(isRegionMatchingQuery('United Kingdom', 'Scotland'), isTrue);
      expect(isRegionMatchingQuery('Taiwan', 'Taipei'), isTrue);
    });

    test('getMatchingDivisionsForRegion extracts matching states/provinces', () {
      expect(getMatchingDivisionsForRegion('United States', 'Texas'), equals(['Texas']));
      expect(getMatchingDivisionsForRegion('United States', 'TX'), equals(['Texas']));
      expect(getMatchingDivisionsForRegion('Canada', 'Ontario'), equals(['Ontario']));
      expect(getMatchingDivisionsForRegion('Canada', 'ON'), equals(['Ontario']));
      expect(getMatchingDivisionsForRegion('Australia', 'Texas'), isEmpty);
    });
  });
}
