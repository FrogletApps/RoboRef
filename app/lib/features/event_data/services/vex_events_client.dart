import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import '../../../core/utils/sku_utils.dart';
import '../../../core/utils/match_utils.dart';
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

  static const String defaultCloudBaseUrl = 'https://roboref.app/api/vexevents';

  VexEventsClient({
    http.Client? client,
    String? serverUrl,
  })  : _client = client ?? http.Client(),
        _serverUrl = serverUrl;

  List<String> _getCandidateBaseUrls(String? customServerUrl) {
    final candidates = <String>[];
    final custom = customServerUrl?.trim() ?? _serverUrl?.trim();

    if (custom != null && custom.isNotEmpty) {
      final clean = custom.replaceAll(RegExp(r'/+$'), '');
      if (clean.endsWith('/api/vexevents')) {
        candidates.add(clean);
      } else {
        candidates.add('$clean/api/vexevents');
      }
    }

    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && origin.startsWith('http')) {
          final webCandidate = '$origin/api/vexevents';
          if (!candidates.contains(webCandidate)) {
            candidates.add(webCandidate);
          }
        }
      } catch (_) {}
    }

    if (!candidates.contains(defaultCloudBaseUrl)) {
      candidates.add(defaultCloudBaseUrl);
    }

    return candidates;
  }

  Map<String, String> get _headers => const {
        'Accept': 'application/json',
        'User-Agent': 'RoboRef/1.0',
      };

  /// Helper to perform GET with multi-candidate fallback
  Future<http.Response> _getWithFallback(
    String path, {
    Map<String, List<String>>? queryParams,
    Duration timeout = const Duration(seconds: 10),
    String? serverUrl,
  }) async {
    final candidateBases = _getCandidateBaseUrls(serverUrl);
    Exception? lastException;
    http.Response? lastResponse;

    for (final base in candidateBases) {
      try {
        final cleanPath = path.startsWith('/') ? path : '/$path';
        final baseUri = Uri.parse('$base$cleanPath');
        final uri = queryParams != null ? baseUri.replace(queryParameters: queryParams) : baseUri;

        final response = await _client.get(uri, headers: _headers).timeout(timeout);
        if (response.statusCode == 200) {
          return response;
        }
        lastResponse = response;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
      }
    }

    if (lastResponse != null) {
      throw VexApiException(
        'Server returned error ${lastResponse.statusCode}: ${lastResponse.body}',
        statusCode: lastResponse.statusCode,
      );
    }

    throw VexApiException(
      'Failed to connect to VEX Events proxy: ${lastException?.toString() ?? "Unknown error"}',
    );
  }

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

  /// Map program names to VEX Events season IDs for server-side season filtering
  List<int> _getProgramSeasonIds(String? program) {
    if (program == null || program.isEmpty || program == 'All') {
      return [204, 203, 205, 206, 197, 196, 198, 199, 190, 189, 191, 194];
    }
    switch (program.toUpperCase()) {
      case 'V5RC':
      case 'VRC':
        return [204, 197, 190, 181, 173];
      case 'VIQRC':
      case 'VIQC':
        return [203, 196, 189, 180, 174];
      case 'VEX U':
      case 'VURC':
        return [205, 198, 191, 182, 175];
      case 'VEX AI':
      case 'VAIRC':
      case 'VAIC':
        return [206, 199, 194, 185, 171];
      default:
        return [];
    }
  }

  /// Searches events via the sync server VEX Events proxy
  Future<List<EventModel>> searchEvents({
    String? query,
    String? program,
    String? sku,
    String? country,
    String? region,
    DateTime? start,
    DateTime? end,
    int page = 1,
    int perPage = 30,
    String? serverUrl,
  }) async {
    final queryParams = <String, List<String>>{
      'page': [page.toString()],
      'per_page': [perPage.toString()],
    };

    final isSkuSearch = (sku != null && sku.trim().isNotEmpty) ||
        (query != null && query.trim().toUpperCase().startsWith('RE-'));

    if (sku != null && sku.trim().isNotEmpty) {
      queryParams['sku[]'] = [sku.trim().toUpperCase()];
    } else if (query != null && query.trim().isNotEmpty) {
      final cleanQuery = query.trim();
      if (cleanQuery.toUpperCase().startsWith('RE-')) {
        queryParams['sku[]'] = [cleanQuery.toUpperCase()];
      }
    }

    if (start != null) {
      queryParams['start'] = [start.toUtc().toIso8601String()];
    }
    if (end != null) {
      queryParams['end'] = [end.toUtc().toIso8601String()];
    }

    final targetReg = region ?? country;
    if (targetReg != null && targetReg.trim().isNotEmpty && targetReg.trim() != 'All') {
      final clean = targetReg.trim();
      // Only United States (and Canada when no province is specified) are omitted from the upstream
      // API 'region' parameter because RobotEvents API v2 requires state/province names for US and returns 0 for 'region=United States'.
      // For all other countries (such as United Kingdom, Australia, Taiwan, Japan, etc.), RobotEvents API accepts 'region=<country>' properly.
      final isCountryWithStateOnlyApi = clean == 'United States' || clean == 'Canada';
      if (!isCountryWithStateOnlyApi) {
        queryParams['region'] = [clean];
      }
    }

    if (!isSkuSearch) {
      final seasonIds = _getProgramSeasonIds(program);
      if (seasonIds.isNotEmpty) {
        queryParams['season[]'] = seasonIds.map((id) => id.toString()).toList();
      }
    }

    final programIds = _getProgramIds(program);
    if (programIds.isNotEmpty) {
      queryParams['program[]'] = programIds.map((id) => id.toString()).toList();
    }

    try {
      final response = await _getWithFallback(
        '/events',
        queryParams: queryParams,
        timeout: const Duration(seconds: 12),
        serverUrl: serverUrl,
      );

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
      try {
        final eventResponse = await _getWithFallback(
          '/events',
          queryParams: {
            'sku[]': [cleanSku]
          },
          timeout: const Duration(seconds: 10),
          serverUrl: serverUrl,
        );

        final data = jsonDecode(eventResponse.body);
        if (data['data'] is List && (data['data'] as List).isNotEmpty) {
          final item = data['data'][0];
          resolvedId = item['id'] as int?;
          eventName = item['name'] ?? cleanSku;
          program = item['program'] is Map ? item['program']['code'] ?? 'V5RC' : item['program'] ?? 'V5RC';
          season = item['season'] is Map ? item['season']['name'] ?? '2026-2027' : item['season'] ?? '2026-2027';
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
      } catch (_) {
        // Fall back to using default/existing metadata
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

        if (divisionIds.isEmpty) {
          divisionIds = [1];
        }

        // Fetch division rankings
        final Map<String, int> teamRanks = {};
        for (final divId in divisionIds) {
          int rankPage = 1;
          bool hasMoreRanks = true;
          while (hasMoreRanks && rankPage <= 5) {
            try {
              final rankResponse = await _getWithFallback(
                '/events/$resolvedId/divisions/$divId/rankings',
                queryParams: {
                  'page': [rankPage.toString()],
                  'per_page': ['250'],
                },
                timeout: const Duration(seconds: 12),
                serverUrl: serverUrl,
              );

              final rankData = jsonDecode(rankResponse.body);
              if (rankData['data'] is List) {
                final list = rankData['data'] as List;
                for (final r in list) {
                  final teamObj = r['team'];
                  String? teamNum;
                  if (teamObj is Map) {
                    teamNum = (teamObj['name'] ?? teamObj['number'] ?? teamObj['team_name'])?.toString();
                  }
                  final rankVal = r['rank'] is int ? r['rank'] as int : int.tryParse(r['rank']?.toString() ?? '');
                  if (teamNum != null && teamNum.trim().isNotEmpty && rankVal != null) {
                    teamRanks[teamNum.trim().toUpperCase()] = rankVal;
                  }
                }

                final meta = rankData['meta'];
                final lastPage = meta?['last_page'] as int? ?? 1;
                if (rankPage >= lastPage || list.isEmpty) {
                  hasMoreRanks = false;
                } else {
                  rankPage++;
                }
              } else {
                hasMoreRanks = false;
              }
            } catch (_) {
              hasMoreRanks = false;
            }
          }
        }

        while (hasMorePages && page <= 5) {
          try {
            final teamsResponse = await _getWithFallback(
              '/events/$resolvedId/teams',
              queryParams: {
                'page': [page.toString()],
                'per_page': ['250'],
              },
              timeout: const Duration(seconds: 12),
              serverUrl: serverUrl,
            );

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
                      rank: Value(teamRanks[teamNum]),
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
          } catch (_) {
            hasMorePages = false;
          }
        }

        // Add any ranked teams not in the event team roster
        final existingNums = allTeamCompanions.map((t) => t.teamNumber.value).toSet();
        for (final entry in teamRanks.entries) {
          if (!existingNums.contains(entry.key)) {
            allTeamCompanions.add(
              TeamsCompanion(
                teamNumber: Value(entry.key),
                teamName: Value('Team ${entry.key}'),
                sku: Value(cleanSku),
                rank: Value(entry.value),
              ),
            );
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
            try {
              final matchesResponse = await _getWithFallback(
                '/events/$resolvedId/divisions/$divId/matches',
                queryParams: {
                  'page': [matchPage.toString()],
                  'per_page': ['250'],
                },
                timeout: const Duration(seconds: 12),
                serverUrl: serverUrl,
              );

              final matchesData = jsonDecode(matchesResponse.body);
              if (matchesData['data'] is List) {
                final list = matchesData['data'] as List;
                for (final m in list) {
                  final matchId = m['id']?.toString() ?? m['name']?.toString() ?? '';
                  final rawName = m['name']?.toString();
                  final round = m['round'] as int?;
                  final instance = m['instance'] as int?;
                  final matchnum = m['matchnum'] as int?;
                  final name = normalizeMatchName(rawName, round: round, instance: instance, matchnum: matchnum);
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
            } catch (_) {
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
