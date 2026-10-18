/// One line to rehearse: what the other person says, plus example replies.
class PracticePrompt {
  const PracticePrompt({required this.heard, required this.suggestions});

  final String heard;
  final List<String> suggestions;
}

class SocialScenario {
  const SocialScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.setting,
    required this.conversationStarters,
    required this.followUpQuestions,
    required this.prompts,
    required this.listeningTips,
  });

  final String id;
  final String title;
  final String description;
  final String setting;
  final List<String> conversationStarters;
  final List<String> followUpQuestions;
  final List<PracticePrompt> prompts;
  final List<String> listeningTips;

  static List<String> _strings(Object? raw) =>
      raw is List ? [for (final s in raw) if (s is String && s.isNotEmpty) s] : const [];

  static SocialScenario? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id is! String || id.isEmpty || title is! String || title.isEmpty) {
      return null;
    }
    final prompts = <PracticePrompt>[];
    final rawPrompts = json['prompts'];
    if (rawPrompts is List) {
      for (final p in rawPrompts) {
        if (p is Map<String, dynamic> && p['heard'] is String) {
          prompts.add(PracticePrompt(
            heard: p['heard'] as String,
            suggestions: _strings(p['suggestions']),
          ));
        }
      }
    }
    return SocialScenario(
      id: id,
      title: title,
      description: json['description'] is String ? json['description'] as String : '',
      setting: json['setting'] is String ? json['setting'] as String : '',
      conversationStarters: _strings(json['conversationStarters']),
      followUpQuestions: _strings(json['followUpQuestions']),
      prompts: prompts,
      listeningTips: _strings(json['listeningTips']),
    );
  }
}
