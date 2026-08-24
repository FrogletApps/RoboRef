import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import '../../../core/utils/sku_utils.dart';
import '../../../database/app_database.dart';
import '../../event_selection/models/event_model.dart';

class VexApiException implements Exception {
  final String message;
  final int? statusCode;

  VexApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

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
  final String? _serverUrl;

  VexEventsClient({
    http.Client? client,
    String? serverUrl,
  })  : _client = client ?? http.Client(),
        _serverUrl = serverUrl;

  String get _effectiveServerUrl {
    final url = _serverUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return url.replaceAll(RegExp(r'/+$'), '');
    }
    return 'http://roboref.local:8080';
  }

  String get _baseProxyUrl => '$_effectiveServerUrl/api/vexevents';

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
      };

  /// Map program names to VEX Events program IDs
  List<int> _getProgramIds(String? program) {
    if (program == null || program.isEmpty || program == 'All') {
      return [];
    }
    switch (program.toUpperCase()) {
      case 'V5RC':
      case 'VRC':
        return [1];
      case 'VIQRC':
      case 'VIQC':
        return [41];
      case 'VEX U':
      case 'VURC':
        return [4];
      case 'VEX AI':
      case 'VAIRC':
      case 'VAIC':
        return [57, 58];
      default:
        return [];
    }
  }

  /// Searches events via the sync server VEX Events proxy
  Future<List<EventModel>> searchEvents({
    String? query,
    String? program,
    String? sku,
    int page = 1,
    int perPage = 25,
    String? serverUrl,
  }) async {
    final serverBase = serverUrl != null && serverUrl.trim().isNotEmpty
        ? '${serverUrl.trim().replaceAll(RegExp(r"/+$"), "")}/api/vexevents'
        : _baseProxyUrl;

    final baseUri = Uri.parse('$serverBase/events');

    final queryParams = <String, List<String>>{
      'page': [page.toString()],
      'per_page': [perPage.toString()],
    };

    if (sku != null && sku.trim().isNotEmpty) {
      queryParams['sku[]'] = [sku.trim().toUpperCase()];
    } else if (query != null && query.trim().isNotEmpty) {
      final cleanQuery = query.trim();
      if (cleanQuery.toUpperCase().startsWith('RE-')) {
        queryParams['sku[]'] = [cleanQuery.toUpperCase()];
      } else {
        queryParams['name'] = [cleanQuery];
      }
    }

    final programIds = _getProgramIds(program);
    if (programIds.isNotEmpty) {
      queryParams['program[]'] = programIds.map((id) => id.toString()).toList();
    }

    final uri = baseUri.replace(queryParameters: queryParams);

    try {
      final response = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw VexApiException(
          'Sync server returned error ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
        );
      }

      final data = jsonDecode(response.body);
      if (data['data'] is List) {
        return (data['data'] as List)
            .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is VexApiException) rethrow;
      throw VexApiException('Failed to search events via sync server: ${e.toString()}');
    }
  }

  /// Fetches tournament details, teams, and match schedule from VEX Events via sync server
  Future<VexEventsFetchResult> fetchTournamentData({
    required String sku,
    required AppDatabase db,
    int? eventId,
    String? defaultEventName,
    String? defaultProgram,
    String? serverUrl,
  }) async {
    final cleanSku = sku.trim().toUpperCase();
    if (cleanSku.isEmpty) {
      return VexEventsFetchResult(success: false, errorMessage: 'SKU cannot be empty');
    }

    final serverBase = serverUrl != null && serverUrl.trim().isNotEmpty
        ? '${serverUrl.trim().replaceAll(RegExp(r"/+$"), "")}/api/vexevents'
        : _baseProxyUrl;

    try {
      int? resolvedId = eventId;
      String eventName = (defaultEventName != null && defaultEventName.trim().isNotEmpty)
          ? defaultEventName.trim()
          : cleanSku;
      String program = defaultProgram ?? getSkuProgram(cleanSku);
      String season = '2026-2027';
      String startDate = DateTime.now().toIso8601String();
      String endDate = DateTime.now().toIso8601String();
      String? venue;
      String? city;
      String? region;
      List<int> divisionIds = [];

      // 1. Fetch Event Info if ID not given or to get fresh event details
      final eventUri = Uri.parse('$serverBase/events?sku[]=$cleanSku');
      final eventResponse = await _client.get(eventUri, headers: _headers).timeout(const Duration(seconds: 10));

      if (eventResponse.statusCode == 200) {
        final data = jsonDecode(eventResponse.body);
        if (data['data'] is List && (data['data'] as List).isNotEmpty) {
          final item = data['data'][0];
          resolvedId = item['id'] as int?;
          eventName = item['name'] ?? cleanSku;
          program = item['program'] is Map ? item['program']['code'] ?? 'V5RC' : item['program'] ?? 'V5RC';
          season = item['season'] is Map ? item['season']['name'] ?? '2024-2025' : item['season'] ?? '2024-2025';
          startDate = item['start'] ?? startDate;
          endDate = item['end'] ?? endDate;

          if (item['location'] is Map) {
            venue = item['location']['venue'];
            city = item['location']['city'];
            region = item['location']['region'];
          }

          if (item['divisions'] is List) {
            for (final div in item['divisions']) {
              if (div['id'] is int) {
                divisionIds.add(div['id'] as int);
              }
            }
          }
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
          venue: Value(venue),
          city: Value(city),
          region: Value(region),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          isHidden: const Value(false),
        ),
      );

      int teamsCount = 0;
      int matchesCount = 0;

      // 2. Fetch Teams if eventId was found
      if (resolvedId != null) {
        int page = 1;
        bool hasMorePages = true;
        final List<TeamsCompanion> allTeamCompanions = [];

        while (hasMorePages && page <= 5) {
          final teamsUri = Uri.parse('$serverBase/events/$resolvedId/teams?page=$page&per_page=250');
          final teamsResponse = await _client.get(teamsUri, headers: _headers).timeout(const Duration(seconds: 12));

          if (teamsResponse.statusCode == 200) {
            final teamsData = jsonDecode(teamsResponse.body);
            if (teamsData['data'] is List) {
              final list = teamsData['data'] as List;
              for (final t in list) {
                final teamNum = t['number']?.toString().toUpperCase() ?? '';
                if (teamNum.isNotEmpty) {
                  allTeamCompanions.add(
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

              final meta = teamsData['meta'];
              final lastPage = meta?['last_page'] as int? ?? 1;
              if (page >= lastPage || list.isEmpty) {
                hasMorePages = false;
              } else {
                page++;
              }
            } else {
              hasMorePages = false;
            }
          } else {
            hasMorePages = false;
          }
        }

        if (allTeamCompanions.isNotEmpty) {
          await db.upsertTeams(allTeamCompanions);
          teamsCount = allTeamCompanions.length;
        }

        // 3. Fetch Matches for each division
        if (divisionIds.isEmpty) {
          divisionIds = [1];
        }

        final List<MatchesCompanion> allMatchCompanions = [];
        for (final divId in divisionIds) {
          int matchPage = 1;
          bool hasMoreMatches = true;

          while (hasMoreMatches && matchPage <= 5) {
            final matchesUri =
                Uri.parse('$serverBase/events/$resolvedId/divisions/$divId/matches?page=$matchPage&per_page=250');
            final matchesResponse =
                await _client.get(matchesUri, headers: _headers).timeout(const Duration(seconds: 12));

            if (matchesResponse.statusCode == 200) {
              final matchesData = jsonDecode(matchesResponse.body);
              if (matchesData['data'] is List) {
                final list = matchesData['data'] as List;
                for (final m in list) {
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
                      final numbers = teamsList
                          .map((t) => t['team']?['name']?.toString() ?? '')
                          .where((s) => s.isNotEmpty)
                          .toList();
                      if (color == 'red') {
                        redTeams = numbers;
                      } else if (color == 'blue') {
                        blueTeams = numbers;
                      }
                    }
                  }

                  if (matchId.isNotEmpty) {
                    allMatchCompanions.add(
                      MatchesCompanion(
                        matchId: Value(matchId),
                        sku: Value(cleanSku),
                        divisionId: Value(divId),
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

                final meta = matchesData['meta'];
                final lastPage = meta?['last_page'] as int? ?? 1;
                if (matchPage >= lastPage || list.isEmpty) {
                  hasMoreMatches = false;
                } else {
                  matchPage++;
                }
              } else {
                hasMoreMatches = false;
              }
            } else {
              hasMoreMatches = false;
            }
          }
        }

        if (allMatchCompanions.isNotEmpty) {
          await db.upsertMatches(allMatchCompanions);
          matchesCount = allMatchCompanions.length;
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
        errorMessage: 'Failed to fetch tournament data from sync server: ${e.toString()}',
      );
    }
  }
}
