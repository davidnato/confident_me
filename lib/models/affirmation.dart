class Affirmation {
  const Affirmation({required this.id, required this.text, this.category = ''});

  final String id;
  final String text;
  final String category;

  static Affirmation? tryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final text = json['text'];
    if (id is! String || id.isEmpty || text is! String || text.isEmpty) {
      return null;
    }
    return Affirmation(
      id: id,
      text: text,
      category: json['category'] is String ? json['category'] as String : '',
    );
  }
}
