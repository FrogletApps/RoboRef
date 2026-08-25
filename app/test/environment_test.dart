import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:roboref/core/utils/sku_utils.dart';

void main() {
  group('resolveAppEnvironment', () {
    test('resolves based on compile-time APP_ENV flag', () {
      expect(
        resolveAppEnvironment(compileEnv: 'local', isWeb: false),
        AppEnvironment.local,
      );
      expect(
        resolveAppEnvironment(compileEnv: 'dev', isWeb: false),
        AppEnvironment.local,
      );
      expect(
        resolveAppEnvironment(compileEnv: 'test', isWeb: false),
        AppEnvironment.test,
      );
      expect(
        resolveAppEnvironment(compileEnv: 'staging', isWeb: false),
        AppEnvironment.test,
      );
      expect(
        resolveAppEnvironment(compileEnv: 'live', isWeb: false),
        AppEnvironment.production,
      );
      expect(
        resolveAppEnvironment(compileEnv: 'production', isWeb: false),
        AppEnvironment.production,
      );
    });

    test('resolves local web hosts to AppEnvironment.local', () {
      final localHosts = [
        'localhost',
        '127.0.0.1',
        '0.0.0.0',
        'roboref.local',
        'arena-server.local',
        '192.168.1.100',
        '10.0.0.5',
        '172.16.0.1',
      ];

      for (final host in localHosts) {
        expect(
          resolveAppEnvironment(host: host, isWeb: true),
          AppEnvironment.local,
          reason: 'Host "$host" should resolve to local environment',
        );
      }
    });

    test('resolves test and staging web hosts to AppEnvironment.test', () {
      final testHosts = [
        'test.roboref.app',
        'test.roboref.fyi',
        'roboref-test.workers.dev',
        'feature-test.workers.dev',
      ];

      for (final host in testHosts) {
        expect(
          resolveAppEnvironment(host: host, isWeb: true),
          AppEnvironment.test,
          reason: 'Host "$host" should resolve to test environment',
        );
      }
    });

    test('resolves live/production web hosts to AppEnvironment.production', () {
      final prodHosts = [
        'roboref.app',
        'roboref.fyi',
        'app.roboref.com',
      ];

      for (final host in prodHosts) {
        expect(
          resolveAppEnvironment(host: host, isWeb: true),
          AppEnvironment.production,
          reason: 'Host "$host" should resolve to production environment',
        );
      }
    });

    test('resolves native platform modes', () {
      expect(
        resolveAppEnvironment(isWeb: false, isDebug: true, isProfile: false),
        AppEnvironment.local,
      );
      expect(
        resolveAppEnvironment(isWeb: false, isDebug: false, isProfile: true),
        AppEnvironment.test,
      );
      expect(
        resolveAppEnvironment(isWeb: false, isDebug: false, isProfile: false),
        AppEnvironment.production,
      );
    });
  });

  group('getAppTitle', () {
    test('returns correct title for each environment', () {
      expect(getAppTitle(AppEnvironment.local), 'RoboRef Local');
      expect(getAppTitle(AppEnvironment.test), 'RoboRef Test');
      expect(getAppTitle(AppEnvironment.production), 'RoboRef');
    });
  });

  group('PWA Manifests', () {
    test('validates manifest.json (Live)', () {
      final file = File('web/manifest.json');
      expect(file.existsSync(), isTrue);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json['name'], 'RoboRef');
      expect(json['short_name'], 'RoboRef');
    });

    test('validates manifest-test.json (Test)', () {
      final file = File('web/manifest-test.json');
      expect(file.existsSync(), isTrue);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json['name'], 'RoboRef Test');
      expect(json['short_name'], 'RoboRef Test');
    });

    test('validates manifest-local.json (Local)', () {
      final file = File('web/manifest-local.json');
      expect(file.existsSync(), isTrue);
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(json['name'], 'RoboRef Local');
      expect(json['short_name'], 'RoboRef Local');
    });
  });
}
