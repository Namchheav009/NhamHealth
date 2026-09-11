import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/app/translations/meal_localization_helpers.dart';

void main() {
  setUp(() {
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
  });

  group('Meal localization helpers in English', () {
    setUp(() {
      Get.updateLocale(const Locale('en', 'US'));
    });

    test('formats calories and cooking time in English', () {
      expect(localizeCalories(1108), '1108 kcal');
      expect(localizeCookingTime(20), '20 min');
      expect(localizeDifficulty('easy'), 'Easy');
      expect(localizeDifficulty('medium'), 'Medium');
      expect(localizeDifficulty('hard'), 'Hard');
    });

    test('localizes categories and dish names in English', () {
      expect(localizeCategory('Breakfast'), 'Breakfast');
      expect(localizeCategory('អាហារពេលព្រឹក'), 'Breakfast');
      expect(localizeDishName('Bai Sach Chrouk'), 'Bai Sach Chrouk');
      expect(localizeDishName('បាយសាច់ជ្រូក'), 'Bai Sach Chrouk');
    });
  });

  group('Meal localization helpers in Khmer', () {
    setUp(() {
      Get.updateLocale(const Locale('km'));
    });

    test('translates dish names from English to Khmer', () {
      expect(localizeDishName('Bai Sach Chrouk'), 'បាយសាច់ជ្រូក');
      expect(localizeDishName('Fish Amok'), 'អាម៉ុកត្រី');
      expect(localizeDishName('Beef Lok Lak'), 'ឡុកឡាក់សាច់គោ');
      expect(localizeDishName('Samlor Machu'), 'សម្លម្ជូរ');
    });

    test('translates categories to Khmer', () {
      expect(localizeCategory('Breakfast'), 'អាហារពេលព្រឹក');
      expect(localizeCategory('Lunch'), 'អាហារថ្ងៃត្រង់');
      expect(localizeCategory('Dinner'), 'អាហារពេលល្ងាច');
      expect(localizeCategory('Snacks'), 'អាហារសម្រន់');
      expect(localizeCategory('Desserts'), 'បង្អែម');
      expect(localizeCategory('Soups'), 'សម្ល');
      expect(localizeCategory('All'), 'ទាំងអស់');
    });

    test('formats calories and cooking time in Khmer', () {
      expect(localizeCalories(1108), '1108 កាឡូរី');
      expect(localizeCookingTime(20), '20 នាទី');
      expect(localizeDifficulty('easy'), 'ងាយស្រួល');
      expect(localizeDifficulty('medium'), 'មធ្យម');
      expect(localizeDifficulty('hard'), 'ពិបាក');
    });

    test('translates AI recommendation reasons into Khmer', () {
      expect(
        localizeRecommendationReason(
          'A balanced, varied option selected for your daily wellness goals.',
        ),
        'ជម្រើសអាហារមានតុល្យភាព និងចម្រុះមុខ ត្រូវបានជ្រើសរើសសម្រាប់គោលដៅសុខុមាលភាពប្រចាំថ្ងៃរបស់អ្នក។',
      );
      expect(
        localizeRecommendationReason(
          'Adds 25 g protein toward today\'s remaining goal.',
        ),
        'បន្ថែម 25 ក្រាមប្រូតេអ៊ីន សម្រាប់គោលដៅដែលនៅសល់ថ្ងៃនេះ។',
      );
      expect(
        localizeRecommendationReason(
          'Matches your saved meal preferences and current wellness profile.',
        ),
        'ត្រូវគ្នានឹងចំណូលចិត្តអាហារដែលអ្នកបានរក្សាទុក និងព័ត៌មានសុខភាពបច្ចុប្បន្នរបស់អ្នក។',
      );
    });

    test('translates meal descriptions into Khmer immediately', () {
      expect(
        localizeMealDescription(
          "Cambodia's most-loved breakfast — charcoal-grilled marinated pork over broken rice, with a bowl of clear broth and a heap of quick pickles.",
        ),
        "អាហារពេលព្រឹកដែលពេញនិយមបំផុតរបស់ប្រទេសកម្ពុជា — សាច់ជ្រូកអាំងដុតធ្យូងពីលើអង្ករសម្រូប ជាមួយនឹងទឹកស៊ុបថ្លា និងម្ហូបជ្រក់មួយចាន។",
      );
      expect(
        localizeMealDescription('Traditional Cambodian steamed fish curry'),
        'ការីត្រីចំហុយបែបប្រពៃណីខ្មែរ',
      );
    });
  });
}
