class MoodModel {
  const MoodModel({required this.id, required this.name, required this.emoji});

  final int id;
  final String name;
  final String emoji;

  static String _emojiFromCode(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';

    final normalized = raw
        .replaceFirst(RegExp(r'^U\+', caseSensitive: false), '')
        .replaceAll(RegExp(r'(?:\s*U\+|[_\s])', caseSensitive: false), '-');
    if (!RegExp(
      r'^[0-9a-f]{1,6}(?:-[0-9a-f]{1,6})*$',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return raw;
    }

    try {
      final codePoints = normalized
          .split('-')
          .map((part) => int.parse(part, radix: 16))
          .toList(growable: false);
      if (codePoints.any((codePoint) => codePoint > 0x10ffff)) return raw;
      return String.fromCharCodes(codePoints);
    } on FormatException {
      return raw;
    } on RangeError {
      return raw;
    }
  }

  factory MoodModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['moodName'];
    if (id is! num || name is! String || name.trim().isEmpty) {
      throw const FormatException('Mood data is incomplete.');
    }

    return MoodModel(
      id: id.toInt(),
      name: name.trim(),
      emoji: _emojiFromCode(json['emojiCode'] as String? ?? ''),
    );
  }
}
