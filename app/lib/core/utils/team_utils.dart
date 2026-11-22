import '../../database/app_database.dart';

// Pre-compiled regular expression constant to optimize team number sorting performance.
// Reusing a single compiled RegExp instance eliminates repeated compilation overhead
// during natural team ordering comparisons (O(N log N)).
final _chunksRegex = RegExp(r'(\d+|\D+)');

/// Returns the English ordinal suffix ('st', 'nd', 'rd', 'th') for a given integer rank.
String getOrdinalSuffix(int number) {
  final abs = number.abs();
  final mod100 = abs % 100;
  if (mod100 >= 11 && mod100 <= 13) {
    return 'th';
  }
  switch (abs % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}

/// Compares two team numbers using natural ordering:
/// - Numeric team numbers are ordered by their integer value first (e.g. '96F' < '1016X').
/// - Letter suffixes are compared alphabetically (e.g. '96A' < '96B').
/// - Numeric teams precede purely non-numeric team names (e.g. '96F' < 'AURA').
/// - Purely non-numeric team names are compared alphabetically (e.g. 'AURA' < 'BLRS').
int compareTeamNumbers(String? a, String? b) {
  if (a == null && b == null) return 0;
  if (a == null || a.trim().isEmpty) return 1;
  if (b == null || b.trim().isEmpty) return -1;

  final strA = a.trim();
  final strB = b.trim();

  if (strA == strB) return 0;

  final chunksA = _splitIntoChunks(strA);
  final chunksB = _splitIntoChunks(strB);

  final minLen = chunksA.length < chunksB.length ? chunksA.length : chunksB.length;
  for (int i = 0; i < minLen; i++) {
    final chunkA = chunksA[i];
    final chunkB = chunksB[i];

    if (chunkA.isNumber && chunkB.isNumber) {
      final numCompare = chunkA.numValue.compareTo(chunkB.numValue);
      if (numCompare != 0) return numCompare;
    } else if (chunkA.isNumber && !chunkB.isNumber) {
      return -1;
    } else if (!chunkA.isNumber && chunkB.isNumber) {
      return 1;
    } else {
      final caseInsensitive = chunkA.textValue.toUpperCase().compareTo(chunkB.textValue.toUpperCase());
      if (caseInsensitive != 0) return caseInsensitive;
      final exact = chunkA.textValue.compareTo(chunkB.textValue);
      if (exact != 0) return exact;
    }
  }

  final lengthCompare = chunksA.length.compareTo(chunksB.length);
  if (lengthCompare != 0) return lengthCompare;

  return strA.compareTo(strB);
}

/// Sort criteria available on the Team List screen.
enum TeamSortField {
  number,
  rank,
  name,
  school,
}

/// Lightweight view model representing a team entry on the Team List screen,
/// combining registered tournament metadata with incident note presence.
class TeamListEntry {
  final String teamNumber;
  final String? teamName;
  final String? school;
  final int? rank;

  const TeamListEntry({
    required this.teamNumber,
    this.teamName,
    this.school,
    this.rank,
  });
}

/// Returns a trimmed custom display name for a team, or `null` if missing or
/// equal to the default fallback (`"Team <teamNumber>"`).
String? normalizeTeamDisplayName(String? teamName, String teamNumber) {
  final trimmed = teamName?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (trimmed == 'Team ${teamNumber.trim()}') return null;
  return trimmed;
}

/// Returns a trimmed school/organization name, or `null` if missing or blank.
String? normalizeTeamSchool(String? organization) {
  final trimmed = organization?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

/// Returns true if the given team matches [query] on team number, custom team
/// name, or school/organization (case-insensitive substring match).
bool matchesTeamSearch({
  required String query,
  required String teamNumber,
  String? teamName,
  String? school,
}) {
  final cleanQuery = query.trim().toLowerCase();
  if (cleanQuery.isEmpty) return true;

  if (teamNumber.trim().toLowerCase().contains(cleanQuery)) {
    return true;
  }

  final displayName = normalizeTeamDisplayName(teamName, teamNumber);
  if (displayName != null && displayName.toLowerCase().contains(cleanQuery)) {
    return true;
  }

  final normalizedSchool = normalizeTeamSchool(school);
  if (normalizedSchool != null &&
      normalizedSchool.toLowerCase().contains(cleanQuery)) {
    return true;
  }

  return false;
}

int _compareTextCaseInsensitive(String a, String b) {
  final lowerCmp = a.toLowerCase().compareTo(b.toLowerCase());
  if (lowerCmp != 0) return lowerCmp;
  return a.compareTo(b);
}

/// Compares two [TeamListEntry] items according to [sortBy] and [ascending].
///
/// Missing metadata (unranked, unnamed, or missing school) is always placed
/// after populated entries regardless of sort direction. Ties are broken
/// deterministically using natural team number ordering.
int compareTeamEntries(
  TeamListEntry a,
  TeamListEntry b, {
  required TeamSortField sortBy,
  bool ascending = true,
}) {
  switch (sortBy) {
    case TeamSortField.number:
      final cmp = compareTeamNumbers(a.teamNumber, b.teamNumber);
      return ascending ? cmp : -cmp;

    case TeamSortField.rank:
      final rankA = a.rank;
      final rankB = b.rank;
      if (rankA == null && rankB == null) {
        return compareTeamNumbers(a.teamNumber, b.teamNumber);
      }
      if (rankA == null) return 1;
      if (rankB == null) return -1;
      final cmp = rankA.compareTo(rankB);
      if (cmp != 0) return ascending ? cmp : -cmp;
      return compareTeamNumbers(a.teamNumber, b.teamNumber);

    case TeamSortField.name:
      final nameA = normalizeTeamDisplayName(a.teamName, a.teamNumber);
      final nameB = normalizeTeamDisplayName(b.teamName, b.teamNumber);
      if (nameA == null && nameB == null) {
        return compareTeamNumbers(a.teamNumber, b.teamNumber);
      }
      if (nameA == null) return 1;
      if (nameB == null) return -1;
      final cmp = _compareTextCaseInsensitive(nameA, nameB);
      if (cmp != 0) return ascending ? cmp : -cmp;
      return compareTeamNumbers(a.teamNumber, b.teamNumber);

    case TeamSortField.school:
      final schoolA = normalizeTeamSchool(a.school);
      final schoolB = normalizeTeamSchool(b.school);
      if (schoolA == null && schoolB == null) {
        return compareTeamNumbers(a.teamNumber, b.teamNumber);
      }
      if (schoolA == null) return 1;
      if (schoolB == null) return -1;
      final cmp = _compareTextCaseInsensitive(schoolA, schoolB);
      if (cmp != 0) return ascending ? cmp : -cmp;
      return compareTeamNumbers(a.teamNumber, b.teamNumber);
  }
}

/// Comparator for Drift [Team] database entities by natural team number order.
int compareTeams(Team a, Team b) {
  return compareTeamNumbers(a.teamNumber, b.teamNumber);
}

class _Chunk {
  final bool isNumber;
  final BigInt numValue;
  final String textValue;

  _Chunk.number(this.numValue, this.textValue) : isNumber = true;
  _Chunk.text(this.textValue)
      : isNumber = false,
        numValue = BigInt.zero;
}

List<_Chunk> _splitIntoChunks(String str) {
  final List<_Chunk> chunks = [];
  final matches = _chunksRegex.allMatches(str);
  for (final m in matches) {
    final s = m.group(0)!;
    final b = BigInt.tryParse(s);
    if (b != null) {
      chunks.add(_Chunk.number(b, s));
    } else {
      chunks.add(_Chunk.text(s));
    }
  }
  return chunks;
}
