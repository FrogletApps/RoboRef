import 'dart:convert';

/// Maximum response body length (in code units) accepted when parsing server info JSON.
const int maxServerInfoResponseLength = 8192;

/// Maximum displayed length (in Unicode code points) for server names (`SERVER_NAME`).
const int maxServerNameLength = 64;

/// Maximum displayed/copied length (in Unicode code points) for server version strings.
const int maxServerVersionLength = 48;

/// Pre-sanitization bound to avoid expensive regex work on oversized payloads.
const int _maxRawScanLength = 1024;

// ANSI CSI / OSC escape sequences (e.g. terminal color or cursor control).
final RegExp _ansiEscapePattern = RegExp(
  r'\u001B(?:\[[0-?]*[ -/]*[@-~]|\][^\u0007\u001B]*(?:\u0007|\u001B\\))',
);

// Line breaks, tabs, and Unicode line/paragraph separators.
final RegExp _lineBreakPattern = RegExp(r'[\r\n\t\u0085\u2028\u2029]+');

// ASCII control characters (C0 + DEL), C1 control characters, Unicode BiDi
// override/embedding/isolate controls, and zero-width / BOM characters.
final RegExp _unsafeControlPattern = RegExp(
  r'[\u0000-\u001F\u007F-\u009F\u061C\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]',
);

final RegExp _whitespacePattern = RegExp(r'\s+');

/// Sanitizes an untrusted server-supplied text field (such as `SERVER_NAME` or `version`)
/// for safe single-line UI display and clipboard copying.
///
/// - Strips ANSI escape sequences, ASCII/C1 control characters, Unicode BiDi controls
///   (preventing visual/Trojan-Source spoofing), and zero-width characters.
/// - Collapses newlines, tabs, and repeated whitespace into single spaces so clipboard
///   content cannot inject multi-line commands or break UI layout.
/// - Enforces a strict maximum code-point length without splitting UTF-16 surrogate pairs.
String? sanitizeServerText(Object? raw, {required int maxLength}) {
  if (raw is! String || raw.isEmpty) return null;

  final bounded = raw.length > _maxRawScanLength
      ? raw.substring(0, _maxRawScanLength)
      : raw;

  var cleaned = bounded
      .replaceAll(_ansiEscapePattern, '')
      .replaceAll(_lineBreakPattern, ' ')
      .replaceAll(_unsafeControlPattern, '')
      .replaceAll(_whitespacePattern, ' ')
      .trim();

  if (cleaned.isEmpty) return null;

  final runes = cleaned.runes;
  if (runes.length > maxLength) {
    cleaned = String.fromCharCodes(runes.take(maxLength)).trimRight();
  }

  return cleaned.isEmpty ? null : cleaned;
}

/// Sanitizes an untrusted server display name (`SERVER_NAME`).
String? sanitizeServerName(Object? raw) =>
    sanitizeServerText(raw, maxLength: maxServerNameLength);

/// Sanitizes an untrusted server version string.
String? sanitizeServerVersion(Object? raw) =>
    sanitizeServerText(raw, maxLength: maxServerVersionLength);

/// Parsed and sanitized server identity and version metadata.
class ServerInfo {
  final String? serverName;
  final String? serverVersion;
  final String? serverEnvironment;

  const ServerInfo({
    this.serverName,
    this.serverVersion,
    this.serverEnvironment,
  });

  bool get hasAny =>
      serverName != null || serverVersion != null || serverEnvironment != null;
}

/// Safely extracts and sanitizes `server` (`SERVER_NAME`), `version`, and optional
/// `environment` from an HTTP `/api/health` or `/api/version` response body and headers.
ServerInfo parseServerInfoFromResponse({
  required String body,
  Map<String, String>? headers,
}) {
  String? serverName;
  String? serverVersion;
  String? serverEnvironment;

  if (body.isNotEmpty && body.length <= maxServerInfoResponseLength) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        serverName = sanitizeServerName(decoded['server']);
        serverVersion = sanitizeServerVersion(decoded['version']);
        serverEnvironment = sanitizeServerText(
          decoded['environment'],
          maxLength: 24,
        );
      }
    } catch (_) {
      // Ignore malformed JSON (e.g. HTML error pages or captive portals)
    }
  }

  if (serverVersion == null && headers != null) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'x-server-version') {
        serverVersion = sanitizeServerVersion(entry.value);
        break;
      }
    }
  }

  return ServerInfo(
    serverName: serverName,
    serverVersion: serverVersion,
    serverEnvironment: serverEnvironment,
  );
}
