import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:roboref/database/app_database.dart';
import 'package:roboref/features/event_data/services/vex_events_client.dart';

void main() {
  group('VexEventsClient Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(
        DatabaseConnection(NativeDatabase.memory()),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('searchEvents proxies to sync server and parses returned events', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/api/vexevents/events'));

        final responseBody = {
          'data': [
            {
              'id': 36495,
              'sku': 'RE-VRC-18-6495',
              'name': 'Torneo Internacional VEX Robotics',
              'start': '2026-11-21T00:00:00Z',
              'end': '2026-11-23T00:00:00Z',
              'program': {'id': 1, 'name': 'VEX V5 Robotics Competition', 'code': 'V5RC'},
              'season': {'id': 180, 'name': '2026-2027'},
              'location': {'venue': 'Convention Center', 'city': 'Cancun', 'region': 'Quintana Roo'},
              'divisions': [
                {'id': 1, 'name': 'Division 1', 'order': 1}
              ]
            }
          ]
        };

        return http.Response(jsonEncode(responseBody), 200);
      });

      final client = VexEventsClient(
        client: mockClient,
        serverUrl: 'http://127.0.0.1:8080',
      );

      final events = await client.searchEvents(query: 'Torneo', program: 'V5RC');
      expect(events.length, equals(1));
      expect(events.first.sku, equals('RE-VRC-18-6495'));
      expect(events.first.name, equals('Torneo Internacional VEX Robotics'));
      expect(events.first.program, equals('V5RC'));
      expect(events.first.city, equals('Cancun'));
    });

    test('searchEvents includes season[] params according to program filter', () async {
      final mockClient = MockClient((request) async {
        final seasons = request.url.queryParametersAll['season[]'];
        expect(seasons, isNotNull);
        expect(seasons, contains('203')); // 2026-2027 VIQRC
        expect(seasons, contains('196')); // 2025-2026 VIQRC

        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 987,
                'sku': 'RE-VIQRC-26-4368',
                'name': 'VIQRC Elite Qualifier',
                'program': {'code': 'VIQRC'},
              }
            ]
          }),
          200,
        );
      });

      final client = VexEventsClient(client: mockClient);
      final events = await client.searchEvents(program: 'VIQRC');
      expect(events.length, equals(1));
      expect(events.first.sku, equals('RE-VIQRC-26-4368'));
    });

    test('searchEvents passes start and end dates formatted as ISO strings', () async {
      final start = DateTime.utc(2026, 8, 21);
      final end = DateTime.utc(2026, 8, 31);

      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['start'], equals(start.toIso8601String()));
        expect(request.url.queryParameters['end'], equals(end.toIso8601String()));

        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 12345,
                'sku': 'RE-V5RC-26-1234',
                'name': 'Summer Regional Tournament',
                'start': '2026-08-24T00:00:00Z',
                'end': '2026-08-25T00:00:00Z',
                'program': {'code': 'V5RC'},
              }
            ]
          }),
          200,
        );
      });

      final client = VexEventsClient(client: mockClient);
      final events = await client.searchEvents(start: start, end: end);
      expect(events.length, equals(1));
      expect(events.first.sku, equals('RE-V5RC-26-1234'));
    });

    test('searchEvents falls back to cloud proxy if primary serverUrl fails', () async {
      int attempt = 0;
      final mockClient = MockClient((request) async {
        attempt++;
        if (request.url.host == '192.168.1.99') {
          return http.Response('Connection Refused', 500);
        }
        if (request.url.host == 'roboref.app') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 999,
                  'sku': 'RE-VIQRC-26-9999',
                  'name': 'Cloud Recovered Event',
                  'program': {'code': 'VIQRC'},
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final client = VexEventsClient(
        client: mockClient,
        serverUrl: 'http://192.168.1.99:8080',
      );

      final events = await client.searchEvents();
      expect(events.length, equals(1));
      expect(events.first.sku, equals('RE-VIQRC-26-9999'));
      expect(attempt, equals(2));
    });

    test('fetchTournamentData fetches event, teams, and matches via sync server into AppDatabase', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/vexevents/events') {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 36495,
                  'sku': 'RE-VRC-18-6495',
                  'name': 'Torneo Internacional VEX Robotics',
                  'start': '2026-11-21T00:00:00Z',
                  'end': '2026-11-23T00:00:00Z',
                  'program': {'code': 'V5RC'},
                  'season': {'name': '2026-2027'},
                  'divisions': [
                    {'id': 1, 'name': 'Division 1'}
                  ]
                }
              ]
            }),
            200,
          );
        } else if (request.url.path.contains('/teams')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'number': '1234A',
                  'team_name': 'RoboKnights',
                  'organization': 'Knights High School',
                  'location': {'city': 'Austin', 'region': 'TX', 'country': 'USA'}
                }
              ],
              'meta': {'last_page': 1}
            }),
            200,
          );
        } else if (request.url.path.contains('/matches')) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 101,
                  'name': 'Q1',
                  'field': 'Field 1',
                  'scheduled': '2026-11-21T09:00:00Z',
                  'alliances': [
                    {
                      'color': 'red',
                      'score': 50,
                      'teams': [
                        {'team': {'name': '1234A'}}
                      ]
                    },
                    {
                      'color': 'blue',
                      'score': 45,
                      'teams': [
                        {'team': {'name': '5678B'}}
                      ]
                    }
                  ]
                }
              ],
              'meta': {'last_page': 1}
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final client = VexEventsClient(
        client: mockClient,
        serverUrl: 'http://127.0.0.1:8080',
      );

      final result = await client.fetchTournamentData(
        sku: 'RE-VRC-18-6495',
        db: db,
      );

      expect(result.success, isTrue);
      expect(result.teamsCount, equals(1));
      expect(result.matchesCount, equals(1));

      final event = await db.getEventBySku('RE-VRC-18-6495');
      expect(event, isNotNull);
      expect(event!.name, equals('Torneo Internacional VEX Robotics'));

      final teams = await db.getTeamsForSku('RE-VRC-18-6495');
      expect(teams.length, equals(1));
      expect(teams.first.teamNumber, equals('1234A'));
      expect(teams.first.teamName, equals('RoboKnights'));

      final matches = await db.getMatchesForSku('RE-VRC-18-6495');
      expect(matches.length, equals(1));
      expect(matches.first.name, equals('Q1'));
      expect(matches.first.redScore, equals(50));
      expect(matches.first.blueScore, equals(45));
    });
  });
}

