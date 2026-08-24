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

    test('searchEvents passes Bearer token and parses returned events', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], equals('Bearer test-token-123'));
        expect(request.url.host, equals('events.vex.com'));
        expect(request.url.path, equals('/api/v2/events'));

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
        apiKey: 'Bearer test-token-123',
      );

      final events = await client.searchEvents(query: 'Torneo', program: 'V5RC');
      expect(events.length, equals(1));
      expect(events.first.sku, equals('RE-VRC-18-6495'));
      expect(events.first.name, equals('Torneo Internacional VEX Robotics'));
      expect(events.first.program, equals('V5RC'));
      expect(events.first.city, equals('Cancun'));
    });

    test('fetchTournamentData fetches event, teams, and matches into AppDatabase', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v2/events') {
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
        apiKey: 'test-token',
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

