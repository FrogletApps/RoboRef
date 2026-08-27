import '../../database/app_database.dart';

/// Round order definition for chronological tournament progression:
/// 1. Practice
/// 2. Qualification
/// 3. Round of 16
/// 4. Quarterfinals
/// 5. Semifinals
/// 6. Finals
/// 7. Round Robin / Top N
/// 99. Other / Unknown
int getMatchRoundOrder(String? matchName) {
  if (matchName == null || matchName.trim().isEmpty) return 99;
  final upper = matchName.trim().toUpperCase();

  // 1. Practice matches:
  // e.g. "Practice 1", "Practice #1", "Prac 1", "P 1", "P1", "P-1", "P_1", "P#1"
  if (RegExp(r'^(P\s*#?\s*|P\s*[-_]\s*|P\d|PRAC)').hasMatch(upper) ||
      upper.contains('PRACTICE') ||
      upper.contains('PRAC')) {
    return 1;
  }

  // 2. Round of 16:
  // e.g. "Round of 16 1-1", "RO16 1-1", "R16 1-1", "R16-1", "R16 #1"
  if (upper.contains('ROUND OF 16') ||
      upper.contains('ROUND OF SIXTEEN') ||
      RegExp(r'^(R\s*[-_]?\s*16|RO\s*[-_]?\s*16|R16)').hasMatch(upper)) {
    return 3;
  }

  // 3. Quarterfinals:
  // e.g. "Quarterfinal 1-1", "Quarterfinals 1-1", "Quarter-final 1-1", "QF 1-1", "QF1-1", "QTR 1"
  if (upper.contains('QUARTER') ||
      RegExp(r'^(QF|Q-F|QTR)').hasMatch(upper)) {
    return 4;
  }

  // 4. Semifinals:
  // e.g. "Semifinal 1-1", "Semifinals 1-1", "Semi-final 1-1", "SF 1-1", "SF1-1", "SF 1"
  if (upper.contains('SEMI') ||
      RegExp(r'^(SF|S-F)').hasMatch(upper)) {
    return 5;
  }

  // 5. Qualification matches:
  // e.g. "Qualification 1", "Qualifier 1", "Quals 1", "Qual 1", "Q 1", "Q1", "Q-1", "Q#1"
  if (RegExp(r'^(Q\s*#?\s*|Q\s*[-_]\s*|Q\d)').hasMatch(upper) ||
      upper.contains('QUAL')) {
    return 2;
  }

  // 6. Finals:
  // e.g. "Final 1-1", "Finals 1-1", "Finals 1", "F 1-1", "F1-1", "F1", "F 1", "F#1"
  if (RegExp(r'^(F\s*#?\s*|F\s*[-_]\s*|F\d)').hasMatch(upper) ||
      upper.contains('FINAL')) {
    return 6;
  }

  // 7. Top N / Round Robin:
  if (upper.contains('ROUND ROBIN') ||
      upper.contains('ROUND-ROBIN') ||
      upper.startsWith('RR') ||
      upper.contains('TOP ')) {
    return 7;
  }

  return 99;
}

/// Compares two match names chronologically:
/// - Rounds: Practice -> Qualification -> Round of 16 -> Quarterfinals -> Semifinals -> Finals
/// - Within the same round: Natural numeric comparison (e.g. Q1 < Q2 < Q9 < Q10 < Q99)
/// - Multi-part match numbers: (e.g. QF 1-1 < QF 1-2 < QF 2-1 < QF 10-1)
int compareMatchNames(String? a, String? b) {
  if (a == null && b == null) return 0;
  if (a == null || a.trim().isEmpty) return 1;
  if (b == null || b.trim().isEmpty) return -1;

  final strA = a.trim();
  final strB = b.trim();
  if (strA == strB) return 0;

  final roundA = getMatchRoundOrder(strA);
  final roundB = getMatchRoundOrder(strB);

  if (roundA != roundB) {
    return roundA.compareTo(roundB);
  }

  // Same round: compare sequence of extracted numbers
  final numsA = _extractMatchNumbers(strA);
  final numsB = _extractMatchNumbers(strB);

  final minLen = numsA.length < numsB.length ? numsA.length : numsB.length;
  for (int i = 0; i < minLen; i++) {
    final diff = numsA[i].compareTo(numsB[i]);
    if (diff != 0) return diff;
  }

  if (numsA.length != numsB.length) {
    return numsA.length.compareTo(numsB.length);
  }

  // Fallback natural string comparison
  return _naturalCompareStrings(strA, strB);
}

/// Compares two Drift [Matche] entities by:
/// 1. Division ID
/// 2. Chronological match name order
/// 3. Scheduled time / matchId (if tied)
int compareMatches(Matche a, Matche b) {
  if (a.divisionId != b.divisionId) {
    return a.divisionId.compareTo(b.divisionId);
  }

  final nameCompare = compareMatchNames(a.name, b.name);
  if (nameCompare != 0) return nameCompare;

  if (a.scheduledTime != null && b.scheduledTime != null) {
    final timeCompare = a.scheduledTime!.compareTo(b.scheduledTime!);
    if (timeCompare != 0) return timeCompare;
  } else if (a.scheduledTime != null) {
    return -1;
  } else if (b.scheduledTime != null) {
    return 1;
  }

  return a.matchId.compareTo(b.matchId);
}

List<int> _extractMatchNumbers(String name) {
  return RegExp(r'\d+')
      .allMatches(name)
      .map((m) => int.tryParse(m.group(0)!) ?? 0)
      .toList();
}

int _naturalCompareStrings(String a, String b) {
  final chunksA = _splitChunks(a);
  final chunksB = _splitChunks(b);

  final minLen = chunksA.length < chunksB.length ? chunksA.length : chunksB.length;
  for (int i = 0; i < minLen; i++) {
    final chunkA = chunksA[i];
    final chunkB = chunksB[i];

    if (chunkA.isNumber && chunkB.isNumber) {
      final numDiff = chunkA.numValue.compareTo(chunkB.numValue);
      if (numDiff != 0) return numDiff;
    } else if (chunkA.isNumber && !chunkB.isNumber) {
      return -1;
    } else if (!chunkA.isNumber && chunkB.isNumber) {
      return 1;
    } else {
      final textDiff = chunkA.textValue.toUpperCase().compareTo(chunkB.textValue.toUpperCase());
      if (textDiff != 0) return textDiff;
      final exact = chunkA.textValue.compareTo(chunkB.textValue);
      if (exact != 0) return exact;
    }
  }

  if (chunksA.length != chunksB.length) {
    return chunksA.length.compareTo(chunksB.length);
  }

  return a.compareTo(b);
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

List<_Chunk> _splitChunks(String str) {
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
