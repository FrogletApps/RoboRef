import '../../database/app_database.dart';

/// Normalizes and standardizes match names across V5 and VEX IQ programs.
/// Converts RobotEvents and Tournament Manager variations (e.g. "Teamwork 1",
/// "Qual #1", "Teamwork Finals 1-1", "Match 1", "1-1") into consistent standard labels:
/// - Practice: "Practice 1"
/// - Qualification: "Qualification 1"
/// - Round of 16: "R16 1-1"
/// - Quarterfinals: "QF 1-1"
/// - Semifinals: "SF 1-1"
/// - Finals: "Finals 1-1" (or "Finals 1")
String normalizeMatchName(String? rawName, {int? round, int? instance, int? matchnum}) {
  if (rawName == null || rawName.trim().isEmpty) {
    if (round != null) {
      final inst = instance ?? 1;
      final num = matchnum ?? 1;
      switch (round) {
        case 1:
          return 'Practice $num';
        case 2:
          return 'Qualification $num';
        case 3:
          return 'QF $inst-$num';
        case 4:
          return 'SF $inst-$num';
        case 5:
        case 6:
          return 'Finals $inst-$num';
        case 7:
          return 'Finals $num';
        case 8:
          return 'RR $inst-$num';
      }
    }
    return '';
  }

  final trimmed = rawName.trim();
  final upper = trimmed.toUpperCase();

  // If explicit round info is provided from RobotEvents API
  if (round != null) {
    final inst = instance ?? 1;
    final num = matchnum ??
        (RegExp(r'\d+').firstMatch(trimmed) != null
            ? int.parse(RegExp(r'\d+').firstMatch(trimmed)!.group(0)!)
            : 1);
    switch (round) {
      case 1:
        return 'Practice $num';
      case 2:
        return 'Qualification $num';
      case 3:
        return 'QF $inst-$num';
      case 4:
        return 'SF $inst-$num';
      case 5:
        return 'Finals $inst-$num';
      case 6:
        if (upper.contains('FINAL') || upper.contains('TEAMWORK')) {
          return 'Finals $inst-$num';
        }
        return 'R16 $inst-$num';
      case 7:
        return 'Finals $num';
      case 8:
        return 'RR $inst-$num';
    }
  }

  final numbers = RegExp(r'\d+')
      .allMatches(trimmed)
      .map((m) => int.tryParse(m.group(0)!) ?? 0)
      .toList();

  // 1. Practice matches
  if (upper.contains('PRACTICE') ||
      upper.contains('PRAC') ||
      RegExp(r'^(P\s*#?\d+|P\s*[-_]\s*\d+|P\s+\d+)').hasMatch(upper)) {
    final num = numbers.isNotEmpty ? numbers.first : 1;
    return 'Practice $num';
  }

  // 2. Round of 16
  if (upper.contains('ROUND OF 16') ||
      upper.contains('ROUND OF SIXTEEN') ||
      RegExp(r'^(R\s*[-_]?\s*16|RO\s*[-_]?\s*16|R16)').hasMatch(upper)) {
    if (numbers.length >= 3) {
      return 'R16 ${numbers[1]}-${numbers[2]}';
    } else if (numbers.length == 2) {
      return 'R16 1-${numbers[1]}';
    }
    return 'R16 1-1';
  }

  // 3. Quarterfinals
  if (upper.contains('QUARTER') || RegExp(r'^(QF|Q-F|QTR)').hasMatch(upper)) {
    if (numbers.length >= 2) {
      return 'QF ${numbers[0]}-${numbers[1]}';
    } else if (numbers.length == 1) {
      return 'QF 1-${numbers[0]}';
    }
    return 'QF 1-1';
  }

  // 4. Semifinals
  if (upper.contains('SEMI') || RegExp(r'^(SF|S-F)').hasMatch(upper)) {
    if (numbers.length >= 2) {
      return 'SF ${numbers[0]}-${numbers[1]}';
    } else if (numbers.length == 1) {
      return 'SF 1-${numbers[0]}';
    }
    return 'SF 1-1';
  }

  // 5. Finals (including "Teamwork Finals 1-1", "Finals 1-1", "Final 1-1", "F 1-1", "1-1", "Match 1-1")
  if (upper.contains('FINAL') ||
      RegExp(r'^(F\s*#?\d|F\s*[-_]\s*\d|F\s+\d)').hasMatch(upper) ||
      (numbers.length >= 2 &&
          (upper.startsWith('TEAMWORK') ||
              upper.startsWith('MATCH') ||
              RegExp(r'^\s*#?\s*\d+\s*-\s*\d+\s*$').hasMatch(upper)))) {
    if (numbers.length >= 2) {
      return 'Finals ${numbers[0]}-${numbers[1]}';
    } else if (numbers.length == 1) {
      return 'Finals ${numbers[0]}';
    }
    return 'Finals 1-1';
  }

  // 6. Qualification (including "Teamwork 1", "Teamwork #1", "Match 1", "Qual #1", "Qualification 1", "Q1", "Q 1")
  if (upper.contains('QUAL') ||
      upper.contains('TEAMWORK') ||
      upper.startsWith('MATCH') ||
      RegExp(r'^(Q\s*#?\d+|Q\s*[-_]\s*\d+|Q\s+\d+)').hasMatch(upper)) {
    final num = numbers.isNotEmpty ? numbers.first : 1;
    return 'Qualification $num';
  }

  // 7. Standalone single number "1", "2", "#1" -> Qualification
  if (RegExp(r'^\s*#?\s*\d+\s*$').hasMatch(trimmed) && numbers.length == 1) {
    return 'Qualification ${numbers.first}';
  }

  return trimmed;
}

/// Formats a match name into standard abbreviated competition display format:
/// - Qualification: "Q 1", "Q 12"
/// - Finals: "F 1-1", "F 1-2" (or "F 1")
/// - Practice: "P 1", "P 10"
/// - Round of 16: "R16 1-1"
/// - Quarterfinals: "QF 1-1"
/// - Semifinals: "SF 1-1"
/// - Round Robin: "RR 1-1"
String formatMatchShortName(String? matchName) {
  if (matchName == null || matchName.trim().isEmpty) return '';
  final trimmed = matchName.trim();
  final upper = trimmed.toUpperCase();

  final numbers = RegExp(r'\d+')
      .allMatches(trimmed)
      .map((m) => int.tryParse(m.group(0)!) ?? 0)
      .toList();

  // 1. Practice
  if (upper.startsWith('PRACTICE') ||
      upper.startsWith('PRAC') ||
      RegExp(r'^(P\s*#?\d+|P\s*[-_]\s*\d+|P\s+\d+)').hasMatch(upper)) {
    final num = numbers.isNotEmpty ? numbers.first : 1;
    return 'P $num';
  }

  // 2. Round of 16
  if (upper.startsWith('R16') ||
      upper.startsWith('RO16') ||
      upper.contains('ROUND OF 16') ||
      upper.contains('ROUND OF SIXTEEN')) {
    if (numbers.length >= 3) {
      return 'R16 ${numbers[1]}-${numbers[2]}';
    } else if (numbers.length == 2) {
      return 'R16 1-${numbers[1]}';
    }
    return 'R16 1-1';
  }

  // 3. Quarterfinals
  if (upper.startsWith('QF') || upper.startsWith('QTR') || upper.contains('QUARTER')) {
    if (numbers.length >= 2) {
      return 'QF ${numbers[0]}-${numbers[1]}';
    } else if (numbers.length == 1) {
      return 'QF 1-${numbers[0]}';
    }
    return 'QF 1-1';
  }

  // 4. Semifinals
  if (upper.startsWith('SF') || upper.contains('SEMI')) {
    if (numbers.length >= 2) {
      return 'SF ${numbers[0]}-${numbers[1]}';
    } else if (numbers.length == 1) {
      return 'SF 1-${numbers[0]}';
    }
    return 'SF 1-1';
  }

  // 5. Finals (including "Teamwork Finals 1-1", "Finals 1-1", "Final 1-1", "F 1-1", "1-1", "Match 1-1")
  if (upper.startsWith('FINAL') ||
      RegExp(r'^(F\s*#?\d|F\s*[-_]\s*\d|F\s+\d+)').hasMatch(upper) ||
      (numbers.length >= 2 &&
          (upper.startsWith('TEAMWORK') ||
              upper.startsWith('MATCH') ||
              RegExp(r'^\s*#?\s*\d+\s*-\s*\d+\s*$').hasMatch(upper)))) {
    if (numbers.length >= 2) {
      return 'F ${numbers[0]}-${numbers[1]}';
    } else if (numbers.length == 1) {
      return 'F ${numbers[0]}';
    }
    return 'F 1-1';
  }

  // 6. Qualification (including "Teamwork 1", "Teamwork #1", "Match 1", "Qual #1", "Qualification 1", "Q1", "Q 1")
  if (upper.startsWith('QUAL') ||
      upper.startsWith('TEAMWORK') ||
      upper.startsWith('MATCH') ||
      RegExp(r'^(Q\s*#?\d+|Q\s*[-_]\s*\d+|Q\s+\d+)').hasMatch(upper)) {
    final num = numbers.isNotEmpty ? numbers.first : 1;
    return 'Q $num';
  }

  // 7. Standalone single number "1", "#1" -> Q 1
  if (RegExp(r'^\s*#?\s*\d+\s*$').hasMatch(trimmed) && numbers.length == 1) {
    return 'Q ${numbers.first}';
  }

  return trimmed;
}

/// Returns a compact short code for a match name (e.g. "Qualification 12" -> "Q12", "Finals 1-1" -> "F1-1")
String getMatchShortCode(String? matchName) {
  if (matchName == null || matchName.trim().isEmpty) return '';
  final trimmed = matchName.trim();
  final upper = trimmed.toUpperCase();

  final numbers = RegExp(r'\d+')
      .allMatches(trimmed)
      .map((m) => int.tryParse(m.group(0)!) ?? 0)
      .toList();

  if (upper.startsWith('QUAL') ||
      upper.startsWith('TEAMWORK') ||
      RegExp(r'^(Q\s*#?\d+|Q\s*[-_]\s*\d+|Q\s+\d+)').hasMatch(upper)) {
    final num = numbers.isNotEmpty ? numbers.first : 1;
    return 'Q$num';
  }

  if (upper.startsWith('PRACTICE') || upper.startsWith('PRAC') || RegExp(r'^P\s*#?\d+').hasMatch(upper)) {
    final num = numbers.isNotEmpty ? numbers.first : 1;
    return 'P$num';
  }

  if (upper.startsWith('FINAL') || RegExp(r'^F\s*#?\d+').hasMatch(upper)) {
    if (numbers.length >= 2) {
      return 'F${numbers[0]}-${numbers[1]}';
    } else if (numbers.length == 1) {
      return 'F${numbers[0]}';
    }
    return 'F1-1';
  }

  if (upper.startsWith('R16') || upper.contains('ROUND OF 16')) {
    if (numbers.length >= 3) {
      return 'R16 ${numbers[1]}-${numbers[2]}';
    } else if (numbers.length == 2) {
      return 'R16 1-${numbers[1]}';
    }
    return 'R16 1-1';
  }

  if (upper.startsWith('QF') || upper.contains('QUARTER')) {
    if (numbers.length >= 2) {
      return 'QF ${numbers[0]}-${numbers[1]}';
    }
    return 'QF 1-1';
  }

  if (upper.startsWith('SF') || upper.contains('SEMI')) {
    if (numbers.length >= 2) {
      return 'SF ${numbers[0]}-${numbers[1]}';
    }
    return 'SF 1-1';
  }

  return trimmed;
}

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

  // 6. Finals (VEX IQ Finals 1-1 onwards, V5RC Finals 1-1, Finals 1, F 1-1, 1-1, etc.):
  // e.g. "Final 1-1", "Finals 1-1", "Finals 1", "F 1-1", "F1-1", "F1", "F 1", "F#1", "1-1", "1-2", "#1-1"
  if (RegExp(r'^(F\s*#?\s*|F\s*[-_]\s*|F\d)').hasMatch(upper) ||
      upper.contains('FINAL') ||
      RegExp(r'^(MATCH\s*#?\s*|M\s*#?\s*|#\s*)?\d+\s*[-]\s*\d+$').hasMatch(upper)) {
    return 6;
  }

  // 5. Qualification matches:
  // e.g. "Qualification 1", "Qualifier 1", "Quals 1", "Qual 1", "Q 1", "Q1", "Q-1", "Q#1", "Teamwork 1", "Match 1"
  if (RegExp(r'^(Q\s*#?\s*|Q\s*[-_]\s*|Q\d)').hasMatch(upper) ||
      upper.contains('QUAL') ||
      upper.contains('TEAMWORK') ||
      RegExp(r'^(MATCH\s*#?\s*|M\s*#?\s*|#\s*)?\d+$').hasMatch(upper)) {
    return 2;
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
