import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import '../../../database/app_database.dart';

class VexEventsFetchResult {
  final bool success;
  final String? eventName;
  final int teamsCount;
  final int matchesCount;
  final String? errorMessage;

  VexEventsFetchResult({
    required this.success,
    this.eventName,
    this.teamsCount = 0,
    this.matchesCount = 0,
    this.errorMessage,
  });
}

class VexEventsClient {
  final http.Client _client;

  VexEventsClient({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches tournament details, teams, and match schedule from RobotEvents / VEX public API
  Future<VexEventsFetchResult> fetchTournamentData({
    required String sku,
    required AppDatabase db,
  }) async {
    final cleanSku = sku.trim().toUpperCase();
    if (cleanSku.isEmpty) {
      return VexEventsFetchResult(success: false, errorMessage: 'SKU cannot be empty');
    }

    try {
      // 1. Fetch Event Info from public RobotEvents endpoint or mirror
      final eventUri = Uri.parse('https://www.robotevents.com/api/v2/events?sku[]=$cleanSku');
      final eventResponse = await _client.get(
        eventUri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      String eventName = cleanSku;
      String program = 'V5RC';
      String season = '2024-2025';
      String startDate = DateTime.now().toIso8601String();
      String endDate = DateTime.now().toIso8601String();
      int? eventId;

      if (eventResponse.statusCode == 200) {
        final data = jsonDecode(eventResponse.body);
        if (data['data'] is List && (data['data'] as List).isNotEmpty) {
          final item = data['data'][0];
          eventId = item['id'] as int?;
          eventName = item['name'] ?? cleanSku;
          program = item['program']?['code'] ?? 'V5RC';
          season = item['season']?['name'] ?? '2024-2025';
          startDate = item['start'] ?? startDate;
          endDate = item['end'] ?? endDate;
        }
      }

      // Upsert event record
      await db.upsertEvent(
        EventsCompanion(
          sku: Value(cleanSku),
          name: Value(eventName),
          program: Value(program),
          season: Value(season),
          startDate: Value(startDate),
          endDate: Value(endDate),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          isHidden: const Value(false),
        ),
      );

      int teamsCount = 0;
      int matchesCount = 0;

      // 2. Fetch Teams if eventId was found
      if (eventId != null) {
        final teamsUri = Uri.parse('https://www.robotevents.com/api/v2/events/$eventId/teams?per_page=250');
        final teamsResponse = await _client.get(
          teamsUri,
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        if (teamsResponse.statusCode == 200) {
          final teamsData = jsonDecode(teamsResponse.body);
          if (teamsData['data'] is List) {
            final List<TeamsCompanion> teamCompanions = [];
            for (final t in teamsData['data']) {
              final teamNum = t['number']?.toString().toUpperCase() ?? '';
              if (teamNum.isNotEmpty) {
                teamCompanions.add(
                  TeamsCompanion(
                    teamNumber: Value(teamNum),
                    teamName: Value(t['team_name']?.toString() ?? 'Team $teamNum'),
                    sku: Value(cleanSku),
                    organization: Value(t['organization']?.toString()),
                    city: Value(t['location']?['city']?.toString()),
                    region: Value(t['location']?['region']?.toString()),
                    country: Value(t['location']?['country']?.toString()),
                  ),
                );
              }
            }
            if (teamCompanions.isNotEmpty) {
              await db.upsertTeams(teamCompanions);
              teamsCount = teamCompanions.length;
            }
          }
        }

        // 3. Fetch Matches if eventId was found
        final matchesUri = Uri.parse('https://www.robotevents.com/api/v2/events/$eventId/divisions/1/matches?per_page=250');
        final matchesResponse = await _client.get(
          matchesUri,
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 10));

        if (matchesResponse.statusCode == 200) {
          final matchesData = jsonDecode(matchesResponse.body);
          if (matchesData['data'] is List) {
            final List<MatchesCompanion> matchCompanions = [];
            for (final m in matchesData['data']) {
              final matchId = m['id']?.toString() ?? m['name']?.toString() ?? '';
              final name = m['name']?.toString() ?? 'Match';
              final field = m['field']?.toString();
              final scheduledTime = m['scheduled']?.toString();

              List<String> redTeams = [];
              List<String> blueTeams = [];

              if (m['alliances'] is List) {
                for (final alliance in m['alliances']) {
                  final color = alliance['color']?.toString().toLowerCase();
                  final teamsList = alliance['teams'] as List? ?? [];
                  final numbers = teamsList.map((t) => t['team']?['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
                  if (color == 'red') {
                    redTeams = numbers;
                  } else if (color == 'blue') {
                    blueTeams = numbers;
                  }
                }
              }

              if (matchId.isNotEmpty) {
                matchCompanions.add(
                  MatchesCompanion(
                    matchId: Value(matchId),
                    sku: Value(cleanSku),
                    divisionId: const Value(1),
                    name: Value(name),
                    field: Value(field),
                    scheduledTime: Value(scheduledTime),
                    redTeamsJson: Value(jsonEncode(redTeams)),
                    blueTeamsJson: Value(jsonEncode(blueTeams)),
                    redScore: Value(m['alliances']?[0]?['score'] as int?),
                    blueScore: Value(m['alliances']?[1]?['score'] as int?),
                  ),
                );
              }
            }
            if (matchCompanions.isNotEmpty) {
              await db.upsertMatches(matchCompanions);
              matchesCount = matchCompanions.length;
            }
          }
        }
      }

      return VexEventsFetchResult(
        success: true,
        eventName: eventName,
        teamsCount: teamsCount,
        matchesCount: matchesCount,
      );
    } catch (e) {
      return VexEventsFetchResult(
        success: false,
        errorMessage: 'Failed to fetch tournament data: ${e.toString()}',
      );
    }
  }
}
