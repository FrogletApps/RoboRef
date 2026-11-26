import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roboref/core/utils/debug_info_formatter.dart';
import 'package:roboref/core/utils/sku_utils.dart';
import 'package:roboref/features/settings/state/sync_settings_controller.dart';

void main() {
  group('debug_info_formatter', () {
    test('formats platform names accurately for native and web apps', () {
      expect(
        formatPlatformName(isWeb: false, targetPlatform: TargetPlatform.android),
        equals('Android'),
      );
      expect(
        formatPlatformName(isWeb: false, targetPlatform: TargetPlatform.iOS),
        equals('iOS'),
      );
      expect(
        formatPlatformName(isWeb: true, targetPlatform: TargetPlatform.windows),
        equals('Web App (Windows)'),
      );
      expect(
        formatPlatformName(isWeb: true, targetPlatform: TargetPlatform.iOS),
        equals('Web App (iOS)'),
      );
      expect(
        formatPlatformName(isWeb: true, targetPlatform: TargetPlatform.android),
        equals('Web App (Android)'),
      );
    });

    test('resolves server environment labels for live, test, local, custom, and explicit values', () {
      expect(
        resolveServerEnvironmentLabel(serverUrl: 'https://roboref.app'),
        equals('Live'),
      );
      expect(
        resolveServerEnvironmentLabel(serverUrl: 'https://test.roboref.app'),
        equals('Test'),
      );
      expect(
        resolveServerEnvironmentLabel(
          serverUrl: 'https://roboapps-server-test.example.workers.dev',
        ),
        equals('Test'),
      );
      expect(
        resolveServerEnvironmentLabel(serverUrl: 'http://roboref.local:8080'),
        equals('Local'),
      );
      expect(
        resolveServerEnvironmentLabel(serverUrl: 'http://localhost:8080'),
        equals('Local'),
      );
      expect(
        resolveServerEnvironmentLabel(serverUrl: 'http://192.168.1.50:8080'),
        equals('Local'),
      );
      expect(
        resolveServerEnvironmentLabel(
          serverUrl: 'https://custom.example.com',
          serverName: 'Custom Staging (Test)',
        ),
        equals('Test'),
      );
      expect(
        resolveServerEnvironmentLabel(
          serverUrl: 'https://custom.example.com',
          serverName: 'Custom Venue Server',
        ),
        equals('Custom'),
      );
      expect(
        resolveServerEnvironmentLabel(
          serverUrl: 'https://custom.example.com',
          explicitServerEnvironment: 'live',
        ),
        equals('Live'),
      );
      expect(
        resolveServerEnvironmentLabel(serverUrl: ''),
        equals('Unknown'),
      );
    });

    test('resolveCurrentWebUrl strips query parameters and fragments and returns null on native', () {
      expect(
        resolveCurrentWebUrl(
          isWeb: true,
          currentUri: Uri.parse('https://test.roboref.app/settings?joinShare=ABC123#top'),
        ),
        equals('https://test.roboref.app'),
      );
      expect(
        resolveCurrentWebUrl(
          isWeb: true,
          currentUri: Uri.parse('https://roboref.app/event/RE-V5RC-26-1234'),
        ),
        equals('https://roboref.app'),
      );
      expect(
        resolveCurrentWebUrl(
          isWeb: false,
          currentUri: Uri.parse('https://roboref.app'),
        ),
        isNull,
      );
    });

    test('buildDebugInfoText produces complete sanitized output for Web App on Test server', () {
      final text = buildDebugInfoText(
        appVersion: '2026.11.26+303',
        appEnvironment: AppEnvironment.test,
        serverUrl: 'https://test.roboref.app/',
        connectionStatus: ServerConnectionStatus.connectedCloud,
        serverName: 'RoboApps Server (Test)\u202E\n',
        serverVersion: '\u001B[31mv2026.11.26+1\u001B[0m\r\n',
        isWeb: true,
        targetPlatform: TargetPlatform.windows,
        currentUri: Uri.parse('https://test.roboref.app/settings?joinShare=SECRET'),
      );

      expect(
        text,
        equals(
          'RoboRef: v2026.11.26+303\n'
          'App Environment: Test\n'
          'Platform: Web App (Windows)\n'
          'Current URL: https://test.roboref.app\n'
          'Server: RoboApps Server (Test)\n'
          'Server Version: v2026.11.26+1\n'
          'Server URL: https://test.roboref.app\n'
          'Server Environment: Test',
        ),
      );
    });

    test('buildDebugInfoText produces complete output for native Android on Live server and handles offline state', () {
      final nativeLive = buildDebugInfoText(
        appVersion: 'v2026.11.26+303',
        appEnvironment: AppEnvironment.production,
        serverUrl: 'https://roboref.app',
        connectionStatus: ServerConnectionStatus.connectedCloud,
        serverName: 'RoboApps Server',
        serverVersion: 'v2026.11.26+1',
        isWeb: false,
        targetPlatform: TargetPlatform.android,
      );

      expect(
        nativeLive,
        equals(
          'RoboRef: v2026.11.26+303\n'
          'App Environment: Live\n'
          'Platform: Android\n'
          'Server: RoboApps Server\n'
          'Server Version: v2026.11.26+1\n'
          'Server URL: https://roboref.app\n'
          'Server Environment: Live',
        ),
      );

      final offline = buildDebugInfoText(
        appVersion: '2026.11.26+303',
        appEnvironment: AppEnvironment.production,
        serverUrl: 'https://roboref.app',
        connectionStatus: ServerConnectionStatus.unreachable,
        isWeb: false,
        targetPlatform: TargetPlatform.iOS,
      );

      expect(offline, contains('Platform: iOS'));
      expect(offline, contains('Server: Unknown'));
      expect(offline, contains('Server Version: Unavailable'));
      expect(offline, contains('Server URL: https://roboref.app'));
      expect(offline, contains('Server Environment: Live'));
    });
  });
}
