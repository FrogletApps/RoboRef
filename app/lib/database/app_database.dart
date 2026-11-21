import 'dart:convert';
import 'package:drift/drift.dart';
import 'tables/events_table.dart';
import 'tables/teams_table.dart';
import 'tables/matches_table.dart';
import 'tables/incident_notes_table.dart';
import 'connection/connection.dart' as impl;
import '../core/utils/sku_utils.dart';
import '../core/utils/team_utils.dart';
import '../core/utils/match_utils.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Events, Teams, Matches, IncidentNotes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());

  AppDatabase.forTesting(QueryExecutor connection)
      : super(
          DatabaseConnection(
            connection is DatabaseConnection ? connection.executor : connection,
            closeStreamsSynchronously: true,
          ),
        );

  @override
  int get schemaVersion => 3;

  Future<Set<String>> _getTableColumns(String tableName) async {
    final rows = await customSelect('PRAGMA table_info("$tableName")').get();
    return rows
        .map((row) => row.data['name']?.toString().toLowerCase())
        .whereType<String>()
        .toSet();
  }

  Future<void> _migrateAndRepairSchema(Migrator m) async {
    final teamCols = await _getTableColumns(teams.actualTableName);
    if (!teamCols.contains('rank')) {
      await m.addColumn(teams, teams.rank);
    }

    final eventCols = await _getTableColumns(events.actualTableName);
    final missingEventColumns = <GeneratedColumn>[
      if (!eventCols.contains('venue')) events.venue,
      if (!eventCols.contains('city')) events.city,
      if (!eventCols.contains('region')) events.region,
      if (!eventCols.contains('is_hidden')) events.isHidden,
      if (!eventCols.contains('is_shared')) events.isShared,
      if (!eventCols.contains('share_id')) events.shareId,
      if (!eventCols.contains('share_role')) events.shareRole,
      if (!eventCols.contains('admin_referee_name')) events.adminRefereeName,
      if (!eventCols.contains('admin_device_id')) events.adminDeviceId,
    ];

    for (final column in missingEventColumns) {
      await m.addColumn(events, column);
    }

    await customStatement(
      'UPDATE "${events.actualTableName}" SET "is_hidden" = 0 WHERE "is_hidden" IS NULL',
    );
    await customStatement(
      'UPDATE "${events.actualTableName}" SET "is_shared" = 0 WHERE "is_shared" IS NULL',
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            await _migrateAndRepairSchema(m);
          }
        },
      );

  // Stream of all active (non-deleted) incident notes for a specific tournament SKU
  Stream<List<IncidentNote>> watchNotesForSku(String sku) {
    return (select(incidentNotes)
          ..where((tbl) => tbl.sku.equals(sku) & tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  // Stream of notes for a specific team at a tournament SKU
  Stream<List<IncidentNote>> watchNotesForTeam(String sku, String teamNumber) {
    return (select(incidentNotes)
          ..where((tbl) =>
              tbl.sku.equals(sku) &
              tbl.teamNumber.equals(teamNumber) &
              tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  // Get unsynced local changes to push to sync server
  Future<List<IncidentNote>> getUnsyncedNotes() {
    return (select(incidentNotes)..where((tbl) => tbl.isSynced.equals(false)))
        .get();
  }

  // Mark a batch of notes as synced
  Future<void> markNotesAsSynced(List<String> ids) async {
    await (update(incidentNotes)..where((tbl) => tbl.id.isIn(ids))).write(
      const IncidentNotesCompanion(isSynced: Value(true)),
    );
  }

  // Upsert incoming notes from remote sync server
  Future<void> upsertRemoteNotes(List<IncidentNotesCompanion> entries) async {
    await batch((batch) {
      for (final entry in entries) {
        batch.insert(
          incidentNotes,
          entry,
          onConflict: DoUpdate<$IncidentNotesTable, IncidentNote>(
            (old) => entry,
            target: [incidentNotes.id],
            where: entry.updatedAt.present
                ? (old) =>
                    old.isSynced.equals(true) |
                    old.updatedAt.isSmallerOrEqualValue(entry.updatedAt.value)
                : null,
          ),
        );
      }
    });
  }

  // Get latest version number for notes of a tournament SKU
  Future<int> getLatestNoteVersion(String sku) async {
    final maxVer = incidentNotes.version.max();
    final query = selectOnly(incidentNotes)
      ..addColumns([maxVer])
      ..where(incidentNotes.sku.equals(sku));
    final row = await query.getSingleOrNull();
    return row?.read(maxVer) ?? 0;
  }

  // --- Events DAO Methods ---

  // Stream of recent visible events
  Stream<List<Event>> watchRecentEvents({int limit = 10}) {
    return (select(events)
          ..where((tbl) => tbl.isHidden.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(limit))
        .watch();
  }

  // Get a single event by SKU
  Future<Event?> getEventBySku(String sku) {
    return (select(events)..where((tbl) => tbl.sku.equals(sku))).getSingleOrNull();
  }

  // Stream a single event by SKU for reactive UI updates
  Stream<Event?> watchEventBySku(String sku) {
    return (select(events)..where((tbl) => tbl.sku.equals(sku))).watchSingleOrNull();
  }

  // Upsert an event record
  Future<void> upsertEvent(EventsCompanion entry) {
    return into(events).insertOnConflictUpdate(entry);
  }

  // Hide an event from recent history
  Future<void> hideEvent(String sku) {
    return (update(events)..where((tbl) => tbl.sku.equals(sku))).write(
      const EventsCompanion(isHidden: Value(true)),
    );
  }

  // Update event share state (isShared, shareId, role, etc.)
  Future<void> updateEventShareState(
    String sku, {
    required bool isShared,
    String? shareId,
    String? shareRole,
    String? adminRefereeName,
    String? adminDeviceId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedRows = await (update(events)..where((tbl) => tbl.sku.equals(sku))).write(
      EventsCompanion(
        isShared: Value(isShared),
        shareId: Value(shareId),
        shareRole: Value(shareRole),
        adminRefereeName: Value(adminRefereeName),
        adminDeviceId: Value(adminDeviceId),
        updatedAt: Value(now),
      ),
    );
    if (updatedRows == 0 && isShared) {
      await into(events).insertOnConflictUpdate(
        EventsCompanion.insert(
          sku: sku,
          name: sku,
          program: getSkuProgram(sku),
          season: '',
          startDate: '',
          endDate: '',
          isShared: Value(isShared),
          shareId: Value(shareId),
          shareRole: Value(shareRole),
          adminRefereeName: Value(adminRefereeName),
          adminDeviceId: Value(adminDeviceId),
          updatedAt: now,
        ),
      );
    }
  }

  // Check if an event is currently marked as shared
  Future<bool> isEventShared(String sku) async {
    final event = await getEventBySku(sku);
    return event?.isShared ?? false;
  }

  // Get all events currently marked as shared
  Future<List<Event>> getSharedEvents() {
    return (select(events)..where((tbl) => tbl.isShared.equals(true))).get();
  }

  // Update admin referee name for an event
  Future<void> updateAdminRefereeName(String sku, String adminRefereeName) async {
    await (update(events)..where((tbl) => tbl.sku.equals(sku))).write(
      EventsCompanion(
        adminRefereeName: Value(adminRefereeName),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // Unhide an event in history
  Future<void> unhideEvent(String sku) {
    return (update(events)..where((tbl) => tbl.sku.equals(sku))).write(
      const EventsCompanion(isHidden: Value(false)),
    );
  }

  // Delete an event record
  Future<void> deleteEvent(String sku) {
    return (delete(events)..where((tbl) => tbl.sku.equals(sku))).go();
  }

  // --- Teams DAO Methods ---
  Stream<List<Team>> watchTeamsForSku(String sku) {
    return (select(teams)
          ..where((tbl) => tbl.sku.equals(sku)))
        .watch()
        .map((list) => List<Team>.from(list)..sort(compareTeams));
  }

  Future<List<Team>> getTeamsForSku(String sku) async {
    final list = await (select(teams)
          ..where((tbl) => tbl.sku.equals(sku)))
        .get();
    return List<Team>.from(list)..sort(compareTeams);
  }

  Future<void> upsertTeams(List<TeamsCompanion> entries) async {
    await batch((batch) {
      for (final entry in entries) {
        batch.insert(
          teams,
          entry,
          onConflict: DoUpdate(
            (old) => entry,
            target: [teams.teamNumber, teams.sku],
          ),
        );
      }
    });
  }

  // --- Matches DAO Methods ---
  Stream<List<Matche>> watchMatchesForSku(String sku) {
    return (select(matches)
          ..where((tbl) => tbl.sku.equals(sku)))
        .watch()
        .map((list) => List<Matche>.from(list)..sort(compareMatches));
  }

  Future<List<Matche>> getMatchesForSku(String sku) async {
    final list = await (select(matches)
          ..where((tbl) => tbl.sku.equals(sku)))
        .get();
    return List<Matche>.from(list)..sort(compareMatches);
  }

  static int _lastArchiveTimestamp = 0;
  static final RegExp _archiveMetaRegex = RegExp(r'_old_(\d+)(?:_n(\d+))?$');

  int _nextArchiveTimestamp([int minTimestamp = 0]) {
    final now = DateTime.now().millisecondsSinceEpoch;
    var candidate = now > minTimestamp ? now : minTimestamp;
    if (candidate <= _lastArchiveTimestamp) {
      candidate = _lastArchiveTimestamp + 1;
    }
    _lastArchiveTimestamp = candidate;
    return candidate;
  }

  ({int? timestamp, int? notesCount}) _parseArchiveMeta(String matchId) {
    final m = _archiveMetaRegex.firstMatch(matchId);
    if (m == null) return (timestamp: null, notesCount: null);
    return (
      timestamp: int.tryParse(m.group(1) ?? ''),
      notesCount: m.group(2) != null ? int.tryParse(m.group(2)!) : null,
    );
  }

  List<String> _normalizeTeamsList(String teamsJson) {
    try {
      final decoded = jsonDecode(teamsJson);
      if (decoded is List) {
        final list = decoded
            .map((e) => e.toString().trim().toUpperCase())
            .where((s) => s.isNotEmpty)
            .toList()
          ..sort(compareTeamNumbers);
        return list;
      }
    } catch (_) {}
    return const [];
  }

  bool _stringListEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _isSameScheduleData({
    required String redJsonA,
    required String blueJsonA,
    required String? fieldA,
    required String? timeA,
    required String redJsonB,
    required String blueJsonB,
    required String? fieldB,
    required String? timeB,
  }) {
    final redA = _normalizeTeamsList(redJsonA);
    final redB = _normalizeTeamsList(redJsonB);
    if (!_stringListEquals(redA, redB)) return false;

    final blueA = _normalizeTeamsList(blueJsonA);
    final blueB = _normalizeTeamsList(blueJsonB);
    if (!_stringListEquals(blueA, blueB)) return false;

    final normFieldA = (fieldA ?? '').trim();
    final normFieldB = (fieldB ?? '').trim();
    if (normFieldA != normFieldB) return false;

    final normTimeA = (timeA ?? '').trim();
    final normTimeB = (timeB ?? '').trim();
    if (normTimeA != normTimeB) return false;

    return true;
  }

  bool _isIncomingMoreRecent(MatchesCompanion previous, MatchesCompanion candidate) {
    final prevId = int.tryParse(previous.matchId.value.trim());
    final candId = int.tryParse(candidate.matchId.value.trim());
    if (prevId != null && candId != null && prevId != candId) {
      return candId > prevId;
    }
    return true;
  }

  ({bool hasNotes, int totalMatchingNotes, int maxNoteCreatedAt}) _checkNotesForActiveMatch(
    Matche activeMatch,
    List<Matche> existingOldMatches,
    List<IncidentNote> notesForSku,
  ) {
    final baseName = stripOldScheduleSuffix(activeMatch.name);
    final matchCanonical = normalizeMatchName(baseName).trim().toUpperCase();
    final matchShortName = formatMatchShortName(baseName).trim().toUpperCase();
    final matchShortCode = getMatchShortCode(baseName).trim().toUpperCase();
    final matchIdUpper = activeMatch.matchId.trim().toUpperCase();

    final matchingNotes = notesForSku.where((note) {
      final raw = note.matchId?.trim();
      if (raw == null || raw.isEmpty) return false;
      if (isOldScheduleMatch(raw)) return false;
      final rawUpper = raw.toUpperCase();
      if (rawUpper == matchIdUpper) return true;
      final noteCanonical = normalizeMatchName(raw).trim().toUpperCase();
      if (noteCanonical.isNotEmpty && noteCanonical == matchCanonical) return true;
      if (formatMatchShortName(raw).trim().toUpperCase() == matchShortName) return true;
      if (getMatchShortCode(raw).trim().toUpperCase() == matchShortCode) return true;
      return false;
    }).toList();

    if (matchingNotes.isEmpty) {
      return (hasNotes: false, totalMatchingNotes: 0, maxNoteCreatedAt: 0);
    }

    int maxNoteCreatedAt = 0;
    for (final n in matchingNotes) {
      if (n.createdAt > maxNoteCreatedAt) {
        maxNoteCreatedAt = n.createdAt;
      }
    }

    if (existingOldMatches.isEmpty) {
      return (
        hasNotes: true,
        totalMatchingNotes: matchingNotes.length,
        maxNoteCreatedAt: maxNoteCreatedAt,
      );
    }

    int maxArchivedAt = 0;
    int maxArchivedNotesCount = 0;
    bool hasArchiveNotesCountMeta = false;
    final Set<String> oldTeams = {};
    for (final oldM in existingOldMatches) {
      final meta = _parseArchiveMeta(oldM.matchId);
      if (meta.timestamp != null && meta.timestamp! > maxArchivedAt) {
        maxArchivedAt = meta.timestamp!;
      }
      if (meta.notesCount != null) {
        hasArchiveNotesCountMeta = true;
        if (meta.notesCount! > maxArchivedNotesCount) {
          maxArchivedNotesCount = meta.notesCount!;
        }
      }
      oldTeams.addAll(_normalizeTeamsList(oldM.redTeamsJson));
      oldTeams.addAll(_normalizeTeamsList(oldM.blueTeamsJson));
    }

    if (hasArchiveNotesCountMeta && matchingNotes.length > maxArchivedNotesCount) {
      return (
        hasNotes: true,
        totalMatchingNotes: matchingNotes.length,
        maxNoteCreatedAt: maxNoteCreatedAt,
      );
    }

    final Set<String> activeTeams = {
      ..._normalizeTeamsList(activeMatch.redTeamsJson),
      ..._normalizeTeamsList(activeMatch.blueTeamsJson),
    };

    for (final note in matchingNotes) {
      if (maxArchivedAt > 0 && note.createdAt > maxArchivedAt) {
        return (
          hasNotes: true,
          totalMatchingNotes: matchingNotes.length,
          maxNoteCreatedAt: maxNoteCreatedAt,
        );
      }
      final noteTeam = note.teamNumber.trim().toUpperCase();
      if (noteTeam.isNotEmpty && activeTeams.contains(noteTeam) && !oldTeams.contains(noteTeam)) {
        return (
          hasNotes: true,
          totalMatchingNotes: matchingNotes.length,
          maxNoteCreatedAt: maxNoteCreatedAt,
        );
      }
    }

    return (
      hasNotes: false,
      totalMatchingNotes: matchingNotes.length,
      maxNoteCreatedAt: maxNoteCreatedAt,
    );
  }

  Future<int> upsertMatches(List<MatchesCompanion> entries) async {
    if (entries.isEmpty) return 0;

    return transaction(() async {
      int changedCount = 0;

      // Group incoming entries by SKU
      final Map<String, List<MatchesCompanion>> entriesBySku = {};
      for (final entry in entries) {
        if (!entry.sku.present || !entry.matchId.present || !entry.name.present) {
          continue;
        }
        final sku = entry.sku.value;
        if (sku.trim().isEmpty) continue;
        entriesBySku.putIfAbsent(sku, () => []).add(entry);
      }

      for (final skuEntry in entriesBySku.entries) {
        final sku = skuEntry.key;
        final skuEntries = skuEntry.value;

        final List<MatchesCompanion> explicitOldEntries = [];
        final Map<({int divisionId, String canonicalName}), MatchesCompanion> deduplicatedActive = {};

        for (final entry in skuEntries) {
          final rawName = entry.name.value;
          if (isOldScheduleMatch(rawName)) {
            explicitOldEntries.add(entry);
            continue;
          }
          final divId = entry.divisionId.present ? entry.divisionId.value : 1;
          final baseName = stripOldScheduleSuffix(rawName);
          final canonical = normalizeMatchName(baseName).trim().toUpperCase();
          final key = (divisionId: divId, canonicalName: canonical);

          final prev = deduplicatedActive[key];
          if (prev == null || _isIncomingMoreRecent(prev, entry)) {
            deduplicatedActive[key] = entry;
          }
        }

        for (final oldEntry in explicitOldEntries) {
          await into(matches).insertOnConflictUpdate(oldEntry);
        }

        if (deduplicatedActive.isEmpty) continue;

        final existingMatches = await (select(matches)
              ..where((tbl) => tbl.sku.equals(sku)))
            .get();
        final activeNotes = await (select(incidentNotes)
              ..where((tbl) => tbl.sku.equals(sku) & tbl.isDeleted.equals(false)))
            .get();

        // Index existing matches by (divisionId, canonicalBaseName)
        final Map<({int divisionId, String canonicalName}), List<Matche>> existingByKey = {};
        for (final m in existingMatches) {
          final baseName = stripOldScheduleSuffix(m.name);
          final canonical = normalizeMatchName(baseName).trim().toUpperCase();
          final key = (divisionId: m.divisionId, canonicalName: canonical);
          existingByKey.putIfAbsent(key, () => []).add(m);
        }

        for (final activeEntry in deduplicatedActive.entries) {
          final key = activeEntry.key;
          final incoming = activeEntry.value;
          final incomingRed = incoming.redTeamsJson.present ? incoming.redTeamsJson.value : '[]';
          final incomingBlue = incoming.blueTeamsJson.present ? incoming.blueTeamsJson.value : '[]';
          final incomingField = incoming.field.present ? incoming.field.value : null;
          final incomingTime = incoming.scheduledTime.present ? incoming.scheduledTime.value : null;

          final slotExisting = existingByKey[key] ?? const <Matche>[];
          final List<Matche> existingOldMatches = [];
          final List<Matche> existingActiveMatches = [];

          for (final m in slotExisting) {
            if (isOldScheduleMatch(m.name)) {
              existingOldMatches.add(m);
            } else {
              existingActiveMatches.add(m);
            }
          }

          if (existingActiveMatches.isEmpty) {
            await into(matches).insertOnConflictUpdate(incoming);
            changedCount++;
            continue;
          }

          // If there were already duplicate active rows in DB for this slot, clean them up first
          if (existingActiveMatches.length > 1) {
            for (final candidate in existingActiveMatches) {
              final sameAsIncoming = _isSameScheduleData(
                redJsonA: candidate.redTeamsJson,
                blueJsonA: candidate.blueTeamsJson,
                fieldA: candidate.field,
                timeA: candidate.scheduledTime,
                redJsonB: incomingRed,
                blueJsonB: incomingBlue,
                fieldB: incomingField,
                timeB: incomingTime,
              );
              if (!sameAsIncoming) {
                final notesCheck = _checkNotesForActiveMatch(
                  candidate,
                  existingOldMatches,
                  activeNotes,
                );
                final alreadyInOld = existingOldMatches.any(
                  (oldM) => _isSameScheduleData(
                    redJsonA: oldM.redTeamsJson,
                    blueJsonA: oldM.blueTeamsJson,
                    fieldA: oldM.field,
                    timeA: oldM.scheduledTime,
                    redJsonB: candidate.redTeamsJson,
                    blueJsonB: candidate.blueTeamsJson,
                    fieldB: candidate.field,
                    timeB: candidate.scheduledTime,
                  ),
                );
                if (notesCheck.hasNotes && !alreadyInOld) {
                  final archiveTs = _nextArchiveTimestamp(notesCheck.maxNoteCreatedAt);
                  final archivedId = '${candidate.matchId}_old_${archiveTs}_n${notesCheck.totalMatchingNotes}';
                  final archivedName = markMatchAsOldSchedule(candidate.name);
                  final archivedRow = candidate.copyWith(
                    matchId: archivedId,
                    name: archivedName,
                  );
                  await into(matches).insertOnConflictUpdate(archivedRow.toCompanion(false));
                  existingOldMatches.add(archivedRow);
                }
              }
            }

            // Pick a single primary active row (preferring one matching incoming, else the last one)
            Matche primary = existingActiveMatches.last;
            for (final candidate in existingActiveMatches.reversed) {
              if (_isSameScheduleData(
                redJsonA: candidate.redTeamsJson,
                blueJsonA: candidate.blueTeamsJson,
                fieldA: candidate.field,
                timeA: candidate.scheduledTime,
                redJsonB: incomingRed,
                blueJsonB: incomingBlue,
                fieldB: incomingField,
                timeB: incomingTime,
              )) {
                primary = candidate;
                break;
              }
            }

            for (final candidate in existingActiveMatches) {
              if (candidate.matchId != primary.matchId) {
                await (delete(matches)
                      ..where((t) =>
                          t.sku.equals(sku) & t.matchId.equals(candidate.matchId)))
                    .go();
              }
            }
            existingActiveMatches
              ..clear()
              ..add(primary);
          }

          final existingActive = existingActiveMatches.single;
          final isSameSchedule = _isSameScheduleData(
            redJsonA: existingActive.redTeamsJson,
            blueJsonA: existingActive.blueTeamsJson,
            fieldA: existingActive.field,
            timeA: existingActive.scheduledTime,
            redJsonB: incomingRed,
            blueJsonB: incomingBlue,
            fieldB: incomingField,
            timeB: incomingTime,
          );

          if (isSameSchedule) {
            // Data is all the same -> no schedule change.
            // If scores were updated in incoming, update scores silently on the existing record.
            final newRedScore = incoming.redScore.present ? incoming.redScore.value : existingActive.redScore;
            final newBlueScore = incoming.blueScore.present ? incoming.blueScore.value : existingActive.blueScore;
            if (newRedScore != existingActive.redScore || newBlueScore != existingActive.blueScore) {
              await (update(matches)
                    ..where((t) =>
                        t.sku.equals(sku) & t.matchId.equals(existingActive.matchId)))
                  .write(
                MatchesCompanion(
                  redScore: Value(newRedScore),
                  blueScore: Value(newBlueScore),
                ),
              );
            }
            continue;
          }

          // Schedule data has changed (e.g. teams have changed)
          final notesCheck = _checkNotesForActiveMatch(
            existingActive,
            existingOldMatches,
            activeNotes,
          );

          if (notesCheck.hasNotes) {
            // Match already has notes attached: keep old match as "(Old schedule)" and load new one
            await (delete(matches)
                  ..where((t) =>
                      t.sku.equals(sku) & t.matchId.equals(existingActive.matchId)))
                .go();

            final alreadyInOld = existingOldMatches.any(
              (oldM) => _isSameScheduleData(
                redJsonA: oldM.redTeamsJson,
                blueJsonA: oldM.blueTeamsJson,
                fieldA: oldM.field,
                timeA: oldM.scheduledTime,
                redJsonB: existingActive.redTeamsJson,
                blueJsonB: existingActive.blueTeamsJson,
                fieldB: existingActive.field,
                timeB: existingActive.scheduledTime,
              ),
            );

            if (!alreadyInOld) {
              final archiveTs = _nextArchiveTimestamp(notesCheck.maxNoteCreatedAt);
              final archivedId = '${existingActive.matchId}_old_${archiveTs}_n${notesCheck.totalMatchingNotes}';
              final archivedName = markMatchAsOldSchedule(existingActive.name);
              await into(matches).insertOnConflictUpdate(
                MatchesCompanion(
                  matchId: Value(archivedId),
                  sku: Value(existingActive.sku),
                  divisionId: Value(existingActive.divisionId),
                  name: Value(archivedName),
                  field: Value(existingActive.field),
                  scheduledTime: Value(existingActive.scheduledTime),
                  redTeamsJson: Value(existingActive.redTeamsJson),
                  blueTeamsJson: Value(existingActive.blueTeamsJson),
                  redScore: Value(existingActive.redScore),
                  blueScore: Value(existingActive.blueScore),
                ),
              );
            }

            await into(matches).insertOnConflictUpdate(incoming);
            changedCount++;
          } else {
            // No notes attached: replace with the most recent version
            if (existingActive.matchId != incoming.matchId.value) {
              await (delete(matches)
                    ..where((t) =>
                        t.sku.equals(sku) & t.matchId.equals(existingActive.matchId)))
                  .go();
            }
            await into(matches).insertOnConflictUpdate(incoming);
            changedCount++;
          }
        }
      }

      return changedCount;
    });
  }

  // Clear all tournament data for a SKU
  Future<void> clearTournamentData(String sku) async {
    await (delete(matches)..where((tbl) => tbl.sku.equals(sku))).go();
    await (delete(teams)..where((tbl) => tbl.sku.equals(sku))).go();
  }
}
