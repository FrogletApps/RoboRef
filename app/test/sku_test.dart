import 'package:flutter_test/flutter_test.dart';
import 'package:roboref/core/utils/sku_utils.dart';

void main() {
  group('SKU Utils Tests', () {
    test('Validates official VEX SKUs correctly', () {
      expect(isValidSku('RE-V5RC-24-8909'), isTrue);
      expect(isValidSku('RE-VIQRC-24-8913'), isTrue);
      expect(isValidSku('RE-VURC-24-8911'), isTrue);
      expect(isValidSku('RE-VAIRC-24-8912'), isTrue);
      expect(isValidSku('re-vrc-24-1234'), isTrue);

      expect(isValidSku('INVALID-SKU'), isFalse);
      expect(isValidSku('RE-ADC-24-9001'), isFalse);
      expect(isValidSku('RE-V5RC-24'), isFalse);
      expect(isValidSku('RE-UNKNOWN-24-1234'), isFalse);
    });

    test('Detects VIQRC, VAIRC, and V5 programs', () {
      expect(isVIQRC('RE-VIQRC-24-8913'), isTrue);
      expect(isVIQRC('RE-VIQC-24-8913'), isTrue);
      expect(isVIQRC('RE-V5RC-24-8909'), isFalse);

      expect(isVAIRC('RE-VAIRC-24-8912'), isTrue);
      expect(isVAIRC('RE-V5RC-24-8909'), isFalse);

      expect(isV5('RE-V5RC-24-8909'), isTrue);
      expect(isV5('RE-VRC-24-1234'), isTrue);
      expect(isV5('RE-VURC-24-8911'), isTrue);
      expect(isV5('RE-VIQRC-24-8913'), isFalse);

      expect(getSkuProgram('RE-V5RC-24-8909'), equals('V5RC'));
      expect(getSkuProgram('RE-VIQRC-24-8913'), equals('VIQRC'));
      expect(getSkuProgram('RE-VURC-24-8911'), equals('VEX U'));
      expect(getSkuProgram('RE-VAIRC-24-8912'), equals('VEX AI'));
    });

    test('Formats date ranges accurately', () {
      final formatted = formatEventDateRange('2026-04-25T08:00:00Z', '2026-04-28T18:00:00Z');
      expect(formatted, contains('Apr 25'));
      expect(formatted, contains('28, 2026'));

      final singleDay = formatEventDateRange('2026-05-01T08:00:00Z', '2026-05-01T17:00:00Z');
      expect(singleDay, equals('May 1, 2026'));
    });
  });
}
