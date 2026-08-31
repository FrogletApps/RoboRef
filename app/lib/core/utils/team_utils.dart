import '../../database/app_database.dart';

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
  final matches = RegExp(r'(\d+|\D+)').allMatches(str);
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
