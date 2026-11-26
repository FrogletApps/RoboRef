import 'package:flutter_test/flutter_test.dart';
import 'package:roboref/core/utils/server_info_sanitizer.dart';

void main() {
  group('server_info_sanitizer', () {
    test('preserves normal server names and version strings', () {
      expect(sanitizeServerName('RoboApps Server'), equals('RoboApps Server'));
      expect(
        sanitizeServerName('RoboApps Server (Test)'),
        equals('RoboApps Server (Test)'),
      );
      expect(
        sanitizeServerVersion('v2026.11.26+1'),
        equals('v2026.11.26+1'),
      );
      expect(
        sanitizeServerVersion('2.4.0-rc.1+build.42'),
        equals('2.4.0-rc.1+build.42'),
      );
    });

    test('rejects non-strings and blank/whitespace-only strings', () {
      expect(sanitizeServerName(null), isNull);
      expect(sanitizeServerName(12345), isNull);
      expect(sanitizeServerName(true), isNull);
      expect(sanitizeServerName(['RoboApps']), isNull);
      expect(sanitizeServerName({'name': 'RoboApps'}), isNull);
      expect(sanitizeServerName('   \t\r\n  '), isNull);
      expect(sanitizeServerVersion(''), isNull);
    });

    test('strips ANSI escape sequences, ASCII/C1 control chars, and collapses newlines', () {
      expect(
        sanitizeServerVersion('\u001B[31mv1.2.3\u001B[0m\r\nrm -rf /'),
        equals('v1.2.3 rm -rf /'),
      );
      expect(
        sanitizeServerName('Venue\u0000\u0007\u001F\n\tLAN\u007F\u008FServer'),
        equals('Venue LANServer'),
      );
    });

    test('strips Unicode BiDi override and zero-width characters', () {
      // Right-to-left override (U+202E), zero-width space (U+200B), BOM (U+FEFF)
      const spoofed = '\uFEFFRoboRef\u202E1.0.0\u200BServer\u2066Test\u2069';
      expect(sanitizeServerName(spoofed), equals('RoboRef1.0.0ServerTest'));
    });

    test('enforces maximum code-point lengths without breaking surrogate pairs', () {
      final longName = 'A' * 120;
      final sanitizedName = sanitizeServerName(longName);
      expect(sanitizedName, isNotNull);
      expect(sanitizedName!.length, equals(maxServerNameLength));

      final longVersion = 'v${'9' * 100}';
      final sanitizedVersion = sanitizeServerVersion(longVersion);
      expect(sanitizedVersion, isNotNull);
      expect(sanitizedVersion!.length, equals(maxServerVersionLength));

      // Emoji are 2 UTF-16 code units (surrogate pair) but 1 rune
      final emojiName = '🤖' * (maxServerNameLength + 10);
      final sanitizedEmoji = sanitizeServerName(emojiName);
      expect(sanitizedEmoji, isNotNull);
      expect(sanitizedEmoji!.runes.length, equals(maxServerNameLength));
    });

    test('parseServerInfoFromResponse extracts sanitized JSON and falls back to X-Server-Version header', () {
      final fromJson = parseServerInfoFromResponse(
        body: '{"status":"ok","server":"  RoboApps Server (Test)  ","version":"v2026.11.26+1"}',
      );
      expect(fromJson.serverName, equals('RoboApps Server (Test)'));
      expect(fromJson.serverVersion, equals('v2026.11.26+1'));

      final fromHeader = parseServerInfoFromResponse(
        body: '{"status":"ok","server":"Venue Pi"}',
        headers: {'X-Server-Version': 'v2026.11.26+2\r\n'},
      );
      expect(fromHeader.serverName, equals('Venue Pi'));
      expect(fromHeader.serverVersion, equals('v2026.11.26+2'));
    });

    test('parseServerInfoFromResponse ignores malformed JSON and oversized bodies safely', () {
      final htmlPage = parseServerInfoFromResponse(
        body: '<html><body>Captive Portal</body></html>',
      );
      expect(htmlPage.serverName, isNull);
      expect(htmlPage.serverVersion, isNull);

      final hugeBody = '{"server":"${'x' * (maxServerInfoResponseLength + 500)}","version":"1.0"}';
      final fromHuge = parseServerInfoFromResponse(
        body: hugeBody,
        headers: {'x-server-version': 'v1.0.0'},
      );
      expect(fromHuge.serverName, isNull);
      expect(fromHuge.serverVersion, equals('v1.0.0'));
    });
  });
}
