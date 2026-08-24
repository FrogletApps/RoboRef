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

  String get cleanCode => code.replaceAll(RegExp(r'[<>]'), '');
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
}
