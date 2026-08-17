class MoodModel {
  const MoodModel({
    required this.id,
    required this.name,
    required this.emoji,
  });

  final int id;
  final String name;
  final String emoji;

  factory MoodModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['moodName'];
    if (id is! num || name is! String || name.trim().isEmpty) {
      throw const FormatException('Mood data is incomplete.');
    }

    return MoodModel(
      id: id.toInt(),
      name: name.trim(),
      emoji: (json['emojiCode'] as String? ?? '').trim(),
    );
  }
}
