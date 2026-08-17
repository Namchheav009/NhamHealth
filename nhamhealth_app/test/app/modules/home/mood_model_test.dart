import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/home/models/mood_model.dart';

void main() {
  group('MoodModel.fromJson', () {
    test('converts a hexadecimal code point to an emoji', () {
      final mood = MoodModel.fromJson({
        'id': 1,
        'moodName': 'Relaxed',
        'emojiCode': '1F60E',
      });

      expect(mood.emoji, '\u{1F60E}');
    });

    test('converts a joined emoji code-point sequence', () {
      final mood = MoodModel.fromJson({
        'id': 2,
        'moodName': 'Relieved',
        'emojiCode': '1F62E-200D-1F4A8',
      });

      expect(mood.emoji, '\u{1F62E}\u{200D}\u{1F4A8}');
    });

    test('keeps an emoji returned directly by the API', () {
      final mood = MoodModel.fromJson({
        'id': 3,
        'moodName': 'Happy',
        'emojiCode': '\u{1F604}',
      });

      expect(mood.emoji, '\u{1F604}');
    });

    test('supports U+ notation and an empty value', () {
      final codedMood = MoodModel.fromJson({
        'id': 4,
        'moodName': 'Okay',
        'emojiCode': 'U+1F642',
      });
      final emptyMood = MoodModel.fromJson({
        'id': 5,
        'moodName': 'Unknown',
        'emojiCode': null,
      });

      expect(codedMood.emoji, '\u{1F642}');
      expect(emptyMood.emoji, isEmpty);
    });
  });
}
