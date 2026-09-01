class RuleModel {
  final String code;
  final String title;
  final String description;
  final String group;
  final String? link;
  final String? qaQuery;

  const RuleModel({
    required this.code,
    required this.title,
    required this.description,
    required this.group,
    this.link,
    this.qaQuery,
  });

  /// Clean alphanumeric rule code without brackets, e.g. "SG1", "GG2", "G1".
  String get cleanCode => code.replaceAll(RegExp(r'[<>]'), '');

  /// Formatted code with angle brackets, e.g. `<SG1>`.
  String get formattedCode => code.startsWith('<') && code.endsWith('>') ? code : '<$code>';

  /// Quick Reference Guide summary of the rule.
  String get summary => title;

  /// User-facing display label with code and summary, e.g. `<SG1> Starting a Match`.
  String get displayLabel => '$formattedCode $title';
}

class GameRuleset {
  final String gameTitle;
  final String season;
  final String program;
  final String manualUrl;
  final String qaUrl;
  final List<RuleModel> rules;

  const GameRuleset({
    required this.gameTitle,
    required this.season,
    required this.program,
    required this.manualUrl,
    required this.qaUrl,
    required this.rules,
  });

  /// Look up a rule by code (e.g. `<SG1>`, `SG1`, `sg1`, or `<GG2>`).
  RuleModel? findRule(String ruleCode) {
    final clean = ruleCode.replaceAll(RegExp(r'[<>]'), '').trim().toUpperCase();
    if (clean.isEmpty) return null;
    for (final r in rules) {
      if (r.cleanCode.toUpperCase() == clean) {
        return r;
      }
    }
    return null;
  }

  /// Get the Quick Reference summary for a given rule code string.
  String? getSummaryForCode(String ruleCode) {
    return findRule(ruleCode)?.summary;
  }
}
