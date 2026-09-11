import 'package:get/get.dart';

const Map<String, String> _dishNamesEnToKm = {
  'bai sach chrouk': 'បាយសាច់ជ្រូក',
  'pork and rice': 'បាយសាច់ជ្រូក',
  'fish amok': 'អាម៉ុកត្រី',
  'amok trey': 'អាម៉ុកត្រី',
  'amok': 'អាម៉ុក',
  'beef lok lak': 'ឡុកឡាក់សាច់គោ',
  'lok lak': 'ឡុកឡាក់',
  'loc lac': 'ឡុកឡាក់',
  'samlor machu': 'សម្លម្ជូរ',
  'samlor machu kroeung': 'សម្លម្ជូរគ្រឿង',
  'samlor machu trey': 'សម្លម្ជូរត្រី',
  'samlor korko': 'សម្លកកូរ',
  'nom banh chok': 'នំបញ្ចុក',
  'kuy teav': 'គុយទាវ',
  'kuyteav': 'គុយទាវ',
  'a-ping': 'អាពីង',
  'aping': 'អាពីង',
  'pleah sach ko': 'ភ្លាសាច់គោ',
  'plea sach ko': 'ភ្លាសាច់គោ',
  'bok lahong': 'បុកល្ហុង',
  'cha kdao': 'ឆាក្តៅ',
  'chhar knye': 'ឆាខ្ញី',
  'sach ko ang': 'សាច់គោអាំង',
  'kari sach moan': 'ការីសាច់មាន់',
  'chicken curry': 'ការីសាច់មាន់',
  'high protein salad': 'សាឡាត់ប្រូតេអ៊ីនខ្ពស់',
  'healthy salad': 'សាឡាត់សុខភាព',
  'salad': 'សាឡាត់',
  'jasmine rice': 'បាយអង្ករផ្កាម្លិះ',
  'bai': 'បាយ',
};

const Map<String, String> _dishNamesKmToEn = {
  'បាយសាច់ជ្រូក': 'Bai Sach Chrouk',
  'អាម៉ុកត្រី': 'Fish Amok',
  'អាម៉ុក': 'Amok',
  'ឡុកឡាក់សាច់គោ': 'Beef Lok Lak',
  'ឡុកឡាក់': 'Lok Lak',
  'សម្លម្ជូរ': 'Samlor Machu',
  'សម្លម្ជូរគ្រឿង': 'Samlor Machu Kroeung',
  'សម្លម្ជូរត្រី': 'Samlor Machu Trey',
  'សម្លកកូរ': 'Samlor Korko',
  'នំបញ្ចុក': 'Nom Banh Chok',
  'គុយទាវ': 'Kuy Teav',
  'អាពីង': 'A-ping',
  'ភ្លាសាច់គោ': 'Pleah Sach Ko',
  'បុកល្ហុង': 'Bok Lahong',
  'ឆាក្តៅ': 'Cha Kdao',
  'ឆាខ្ញី': 'Chhar Knye',
  'សាច់គោអាំង': 'Sach Ko Ang',
  'ការីសាច់មាន់': 'Kari Sach Moan',
  'សាឡាត់សុខភាព': 'Healthy Salad',
  'សាឡាត់': 'Salad',
  'សាឡាត់ប្រូតេអ៊ីនខ្ពស់': 'High Protein Salad',
  'បាយអង្ករផ្កាម្លិះ': 'Jasmine Rice',
};

String localizeDishName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return trimmed;
  final isKm = Get.locale?.languageCode == 'km';
  if (isKm) {
    final lower = trimmed.toLowerCase();
    // 1. Exact match first
    if (_dishNamesEnToKm.containsKey(lower)) {
      return _dishNamesEnToKm[lower]!;
    }
    // 2. Substring match — find the longest key contained in the name
    //    (longest key wins to prefer 'amok trey' over 'amok', etc.)
    String? bestKey;
    for (final key in _dishNamesEnToKm.keys) {
      if (lower.contains(key)) {
        if (bestKey == null || key.length > bestKey.length) {
          bestKey = key;
        }
      }
    }
    if (bestKey != null) return _dishNamesEnToKm[bestKey]!;
  } else {
    // Exact match for Khmer → English
    if (_dishNamesKmToEn.containsKey(trimmed)) {
      return _dishNamesKmToEn[trimmed]!;
    }
  }
  return trimmed;
}

String localizeCategory(String category) {
  final trimmed = category.trim();
  if (trimmed.isEmpty) return trimmed;
  final lower = trimmed.toLowerCase();
  final isKm = Get.locale?.languageCode == 'km';

  if (isKm) {
    if (lower == 'all' || lower == 'ទាំងអស់') return 'common.all'.tr;
    if (lower == 'breakfast' || lower == 'អាហារពេលព្រឹក') return 'wellness.breakfast'.tr;
    if (lower == 'lunch' || lower == 'អាហារពេលថ្ងៃត្រង់' || lower == 'អាហារថ្ងៃត្រង់') return 'wellness.lunch'.tr;
    if (lower == 'dinner' || lower == 'អាហារពេលល្ងាច') return 'wellness.dinner'.tr;
    if (lower == 'snack' || lower == 'snacks' || lower == 'អាហារសម្រន់') return 'wellness.snack'.tr;
    if (lower == 'dessert' || lower == 'desserts' || lower == 'បង្អែម') return 'បង្អែម';
    if (lower == 'soup' || lower == 'soups' || lower == 'សម្ល') return 'សម្ល';
    if (lower == 'grill' || lower == 'grills & street food' || lower == 'ម្ហូបអាំង') return 'ម្ហូបអាំង';
    if (lower == 'amok, curries & stir-fries') return 'អាម៉ុក ការី និងម្ហូបឆា';
    if (lower == 'other' || lower == 'others' || lower == 'ផ្សេងៗ') return 'ផ្សេងៗ';
    if (lower == 'high protein' || lower == 'ប្រូតេអ៊ីនខ្ពស់') return 'ប្រូតេអ៊ីនខ្ពស់';
    if (lower == 'recommended' || lower == 'ការណែនាំ') return 'common.recommended'.tr;
    if (lower == 'healthy' || lower == 'ល្អសម្រាប់សុខភាព') return 'meals.healthy'.tr;
  } else {
    if (lower == 'all' || lower == 'ទាំងអស់' || lower == 'អាហារទាំងអស់') return 'common.all'.tr;
    if (lower == 'breakfast' || lower == 'អាហារពេលព្រឹក') return 'wellness.breakfast'.tr;
    if (lower == 'lunch' || lower == 'អាហារពេលថ្ងៃត្រង់' || lower == 'អាហារថ្ងៃត្រង់') return 'wellness.lunch'.tr;
    if (lower == 'dinner' || lower == 'អាហារពេលល្ងាច') return 'wellness.dinner'.tr;
    if (lower == 'snack' || lower == 'snacks' || lower == 'អាហារសម្រន់') return 'wellness.snack'.tr;
    if (lower == 'dessert' || lower == 'desserts' || lower == 'បង្អែម') return 'Dessert';
    if (lower == 'soup' || lower == 'soups' || lower == 'សម្ល') return 'Soup';
    if (lower == 'grill' || lower == 'ម្ហូបអាំង') return 'Grill';
    if (lower == 'other' || lower == 'others' || lower == 'ផ្សេងៗ') return 'Other';
    if (lower == 'high protein' || lower == 'ប្រូតេអ៊ីនខ្ពស់') return 'High Protein';
    if (lower == 'recommended' || lower == 'ការណែនាំ') return 'common.recommended'.tr;
    if (lower == 'healthy' || lower == 'ល្អសម្រាប់សុខភាព') return 'meals.healthy'.tr;
  }
  return trimmed;
}

String localizeCookingTime(num? minutes) {
  if (minutes == null) return 'meals.not_specified'.tr;
  final isKm = Get.locale?.languageCode == 'km';
  final unit = isKm ? 'meals.minutes_short'.tr : 'min';
  final formattedMinutes =
      minutes.toDouble() == minutes.roundToDouble()
          ? minutes.toInt().toString()
          : minutes.toStringAsFixed(1);
  return '$formattedMinutes $unit';
}

String localizeCalories(num? calories) {
  final value = calories ?? 0;
  final isKm = Get.locale?.languageCode == 'km';
  final unit = isKm ? 'កាឡូរី' : 'kcal';
  final formatted =
      value.toDouble() == value.roundToDouble()
          ? value.toInt().toString()
          : value.toStringAsFixed(1);
  return '$formatted $unit';
}

String localizeDifficulty(String difficulty) {
  final lower = difficulty.trim().toLowerCase();
  if (lower == 'easy') return 'meals.easy'.tr;
  if (lower == 'medium') return 'common.medium'.tr;
  if (lower == 'hard') return 'meals.hard'.tr;
  return difficulty.isEmpty ? 'meals.not_specified'.tr : difficulty;
}

String localizeNutrient(String name) {
  final lower = name.trim().toLowerCase();
  if (lower.contains('protein')) return 'common.protein'.tr;
  if (lower.contains('carb')) return 'wellness.carbohydrates'.tr;
  if (lower.contains('fat')) return 'common.fat'.tr;
  if (lower.contains('fiber')) return 'common.fiber'.tr;
  if (lower.contains('sugar')) return 'common.sugar'.tr;
  if (lower.contains('calorie')) return 'common.calories'.tr;
  return name;
}

String localizeRecommendationReason(String reason) {
  if (Get.locale?.languageCode != 'km') return reason;
  final trimmed = reason.trim();
  if (trimmed == 'A balanced, varied option selected for your daily wellness goals.') {
    return 'ជម្រើសអាហារមានតុល្យភាព និងចម្រុះមុខ ត្រូវបានជ្រើសរើសសម្រាប់គោលដៅសុខុមាលភាពប្រចាំថ្ងៃរបស់អ្នក។';
  }
  if (trimmed.startsWith('A balanced, varied option for your ')) {
    return 'ជម្រើសអាហារមានតុល្យភាព និងចម្រុះមុខ សម្រាប់អារម្មណ៍របស់អ្នក។';
  }
  if (trimmed == 'Matches your saved meal preferences and current wellness profile.') {
    return 'ត្រូវគ្នានឹងចំណូលចិត្តអាហារដែលអ្នកបានរក្សាទុក និងព័ត៌មានសុខភាពបច្ចុប្បន្នរបស់អ្នក។';
  }
  if (trimmed.startsWith('Matches your saved preferences and suits your ')) {
    return 'ត្រូវគ្នានឹងចំណូលចិត្តដែលអ្នកបានរក្សាទុក និងអារម្មណ៍នាពេលនេះ។';
  }
  if (trimmed.startsWith('Provides practical energy for a ')) {
    return 'ផ្តល់ថាមពលសមស្របសម្រាប់ថ្ងៃនេះ។';
  }
  final addProteinMatch = RegExp(
    r'^Adds\s+([\d.]+)\s*g protein toward today.*goal\.',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (addProteinMatch != null) {
    final proteinValue = addProteinMatch.group(1) ?? '';
    return 'បន្ថែម $proteinValue ក្រាមប្រូតេអ៊ីន សម្រាប់គោលដៅដែលនៅសល់ថ្ងៃនេះ។';
  }
  final usesMatch = RegExp(
    r'^Uses\s+(.*?)\s+with your saved BMI and activity context\.',
    caseSensitive: false,
  ).firstMatch(trimmed);
  if (usesMatch != null) {
    return 'ប្រើប្រាស់ជីវជាតិស្របតាមទិន្នន័យ BMI និងកម្រិតសកម្មភាពរបស់អ្នក។';
  }
  if (trimmed.startsWith('Connects your ')) {
    return 'សមស្របទៅតាមអារម្មណ៍ និងកម្រិត BMI របស់អ្នក។';
  }
  return reason;
}

const Map<String, String> _mealDescriptionsKm = {
  "cambodia's most-loved breakfast — charcoal-grilled marinated pork over broken rice, with a bowl of clear broth and a heap of quick pickles.":
      "អាហារពេលព្រឹកដែលពេញនិយមបំផុតរបស់ប្រទេសកម្ពុជា — សាច់ជ្រូកអាំងដុតធ្យូងពីលើអង្ករសម្រូប ជាមួយនឹងទឹកស៊ុបថ្លា និងម្ហូបជ្រក់មួយចាន។",
  "the fried tarantulas of skuon, kampong cham — garlic-salt seasoned, crisp outside and soft within, sold by the basket at the market crossroads.":
      "ត្រកួនចៀន ស្គួន កំពង់ចាម - ខ្ទឹម-អំបិល ចិញ្រ្ចាំខាងក្រៅ ទន់ ខាងក្នុង លក់តាមកន្ត្រកនៅផ្លូវបំបែកផ្សារ។",
  "cambodia's national dish: freshwater fish folded into coconut and yellow kroeung, steamed to a custard inside a banana-leaf cup. the siem reap way.":
      "មុខម្ហូបជាតិរបស់កម្ពុជា៖ ត្រីទឹកសាបបត់ចូលខ្ទិះដូង និងក្រៀមលឿង ចំហុយដាក់ទឹកខ្មេះក្នុងពែងស្លឹកចេក។ ផ្លូវសៀមរាប។",
  "whole squid grilled over charcoal and glazed with fish sauce, lime, and garlic — the smoke-and-sea skewer of every kampot and kep beach grill.":
      "មឹកទាំងមូលដុតពីលើធ្យូង ហើយស្រោបដោយទឹកត្រី កំបោរ និងខ្ទឹមស ដែលជាគ្រឿងដុតផ្សែង និងសមុទ្រនៃរាល់ការដុតឆ្នេរកំពត និងកែប។",
  "battambang's fragrant jasmine rice cooked two ways — the absorption pot and the old drain method — until every grain stands separate and sweet.":
      "អង្ករផ្កាម្លិះក្រអូបរបស់បាត់ដំបង ចម្អិនតាមពីរវិធី គឺឆ្នាំងស្រូប និងវិធីបង្ហូរចាស់ រហូតទាល់តែគ្រាប់ធញ្ញជាតិទាំងអស់ដាច់ចេញពីគ្នា និងផ្អែម។",
  "marinated chicken and herbs sealed in green bamboo and roasted over coals — a highland forest technique adapted honestly for a home grill or oven.":
      "សាច់​មាន់ និង​គ្រឿង​ផ្សំ​ដែល​បិទ​ជិត​ក្នុង​ឬស្សី​បៃតង ហើយ​អាំង​លើ​ធ្យូង - ជា​បច្ចេកទេស​ព្រៃ​ភ្នំ​ដែល​សម្រប​ដោយ​ស្មោះត្រង់​សម្រាប់​ការ​ដុត​ផ្ទះ ឬ​ឡ។",
  "whole prawns wok-fried in their shells and tossed in crushed kampot pepper and salt-field salt — the crispest, simplest tribute to two coastal ingredients.":
      "បង្គា​ទាំង​មូល​ដែល​បំពង​ក្នុង​សម្បក​របស់​វា ហើយ​បោះ​ក្នុង​ម្រេច​កំពត​បុក និង​អំបិល​ប្រៃ​ជា​អាហារ​ដ៏​ឆ្ងាញ់ និង​សាមញ្ញ​បំផុត​ចំពោះ​គ្រឿងផ្សំ​ឆ្នេរ​ពីរ។",
  "kampot durian folded into warm coconut sticky rice — the coast's most decadent sweet, from the orchards of the town's famous durian roundabout.":
      "ទុរេនកំពតបត់ចូលទៅក្នុងអង្ករដំណើបដូងក្តៅ ដែលជារសជាតិផ្អែមបំផុតរបស់ឆ្នេរសមុទ្រ ចេញពីចម្ការនៃរង្វង់មូលធុរេនដ៏ល្បីរបស់ទីក្រុង។",
  "silky chicken rice porridge simmered soft, then dressed at the table with bean sprouts, fried garlic, herbs, and a squeeze of lime — cambodia's dawn bowl.":
      "បបរ​បាយ​មាន់​ស្រួយ​ស្រួយ​ស្រួយ រួច​ស្លៀកពាក់​នៅ​តុ​ជាមួយ​សណ្តែកបណ្តុះ ខ្ទឹម​បំពង ឱសថ និង​ទឹក​កំបោរ​មួយ​ចាន​ព្រឹក​ព្រលឹម​របស់​កម្ពុជា។",
  "the khmer pounded green papaya salad — shredded papaya bruised in a clay mortar with prahok, lime, chilli, and long beans until it weeps and bites.":
      "ល្ហុងខ្មែរ បុកល្ហុងខ្ចី - ល្ហុងខ្ទេចខ្ទី បុកក្នុងបាយអដីឥដ្ឋជាមួយប្រហុក កំបោរ ម្ទេស និងសណ្តែកវែង រហូតស្រក់ទឹកភ្នែក។",
  "kho trey is southern home cooking at its plainest and best — fish braised slow in palm-sugar caramel and fish sauce until dark, sweet and deep.":
      "Kho trey គឺ​ជា​ការ​ចម្អិន​ម្ហូប​នៅ​ផ្ទះ​ភាគ​ខាង​ត្បូង​ក្នុង​លក្ខណៈ​សាមញ្ញ​បំផុត និង​ល្អ​បំផុត — ត្រី​ប្រឡាក់​យឺតៗ​ក្នុង​ស្ករត្នោត និង​ទឹក​ត្រី​រហូត​ដល់​ងងឹត ផ្អែម និង​ជ្រៅ។",
  "traditional cambodian steamed fish curry": "ការីត្រីចំហុយបែបប្រពៃណីខ្មែរ",
};

const Map<String, String> _mealDescriptionsEn = {
  "អាហារពេលព្រឹកដែលពេញនិយមបំផុតរបស់ប្រទេសកម្ពុជា — សាច់ជ្រូកអាំងដុតធ្យូងពីលើអង្ករសម្រូប ជាមួយនឹងទឹកស៊ុបថ្លា និងម្ហូបជ្រក់មួយចាន។":
      "Cambodia's most-loved breakfast — charcoal-grilled marinated pork over broken rice, with a bowl of clear broth and a heap of quick pickles.",
  "អាហារពេលព្រឹកដែលពេញនិយមបំផុតរបស់ប្រទេសកម្ពុជា — សាច់ជ្រូកអាំងដុតធ្យូងពីលើអង្ករសំរូប ជាមួយនឹងទឹកទំពាំងបាយជូរថ្លាមួយចាន និងហាន់ជាបន្ទះៗ។":
      "Cambodia's most-loved breakfast — charcoal-grilled marinated pork over broken rice, with a bowl of clear broth and a heap of quick pickles.",
  "ការីត្រីចំហុយបែបប្រពៃណីខ្មែរ": "Traditional Cambodian steamed fish curry",
};

String localizeMealDescription(String description) {
  final trimmed = description.trim();
  if (trimmed.isEmpty) return description;
  final isKm = Get.locale?.languageCode == 'km';
  if (isKm) {
    final lower = trimmed.toLowerCase();
    if (_mealDescriptionsKm.containsKey(lower)) {
      return _mealDescriptionsKm[lower]!;
    }
    if (lower.startsWith("cambodia's most-loved breakfast")) {
      return "អាហារពេលព្រឹកដែលពេញនិយមបំផុតរបស់ប្រទេសកម្ពុជា — សាច់ជ្រូកអាំងដុតធ្យូងពីលើអង្ករសម្រូប ជាមួយនឹងទឹកស៊ុបថ្លា និងម្ហូបជ្រក់មួយចាន។";
    }
    return description;
  } else {
    if (_mealDescriptionsEn.containsKey(trimmed)) {
      return _mealDescriptionsEn[trimmed]!;
    }
    if (trimmed.startsWith("អាហារពេលព្រឹកដែលពេញនិយមបំផុតរបស់ប្រទេសកម្ពុជា")) {
      return "Cambodia's most-loved breakfast — charcoal-grilled marinated pork over broken rice, with a bowl of clear broth and a heap of quick pickles.";
    }
    return description;
  }
}

const Map<String, String> _notificationTitlesEnToKm = {
  'report submitted': 'បានដាក់ស្នើរបាយការណ៍',
  'report reviewed': 'របាយការណ៍ត្រូវបានពិនិត្យ',
  'report accepted for review': 'របាយការណ៍ត្រូវបានទទួលយកដើម្បីពិនិត្យ',
  'profile report reviewed': 'របាយការណ៍គណនីត្រូវបានពិនិត្យ',
  'profile report resolved': 'របាយការណ៍គណនីត្រូវបានដោះស្រាយ',
  'password changed': 'បានប្តូរពាក្យសម្ងាត់',
  'ai food check needs review': 'ការពិនិត្យម្ហូប AI ត្រូវការការបញ្ជាក់',
  'ai food check complete': 'ការពិនិត្យម្ហូប AI បានបញ្ចប់',
  'someone': 'នរណាម្នាក់',
  'notification': 'ការជូនដំណឹង',
};

const Map<String, String> _notificationTitlesKmToEn = {
  'បានដាក់ស្នើរបាយការណ៍': 'Report submitted',
  'របាយការណ៍ត្រូវបានពិនិត្យ': 'Report reviewed',
  'របាយការណ៍ត្រូវបានទទួលយកដើម្បីពិនិត្យ': 'Report accepted for review',
  'របាយការណ៍គណនីត្រូវបានពិនិត្យ': 'Profile report reviewed',
  'របាយការណ៍គណនីត្រូវបានដោះស្រាយ': 'Profile report resolved',
  'បានប្តូរពាក្យសម្ងាត់': 'Password changed',
  'ការពិនិត្យម្ហូប AI ត្រូវការការបញ្ជាក់': 'AI food check needs review',
  'ការពិនិត្យម្ហូប AI បានបញ្ចប់': 'AI food check complete',
  'នរណាម្នាក់': 'Someone',
  'ការជូនដំណឹង': 'Notification',
};

const Map<String, String> _notificationMessagesEnToKm = {
  'started following you.': 'បានចាប់ផ្តើមតាមដានអ្នក។',
  'started following you': 'បានចាប់ផ្តើមតាមដានអ្នក។',
  'followed you.': 'បានតាមដានអ្នក។',
  'followed you': 'បានតាមដានអ្នក។',
  'replied to your comment.': 'បានឆ្លើយតបទៅមតិរបស់អ្នក។',
  'replied to your comment': 'បានឆ្លើយតបទៅមតិរបស់អ្នក។',
  'replied to a comment on your post.': 'បានឆ្លើយតបទៅមតិលើការបង្ហោះរបស់អ្នក។',
  'replied to a comment on your post': 'បានឆ្លើយតបទៅមតិលើការបង្ហោះរបស់អ្នក។',
  'commented on your post.': 'បានបញ្ចេញមតិលើការបង្ហោះរបស់អ្នក។',
  'commented on your post': 'បានបញ្ចេញមតិលើការបង្ហោះរបស់អ្នក។',
  'liked your post.': 'បានចូលចិត្តការបង្ហោះរបស់អ្នក។',
  'liked your post': 'បានចូលចិត្តការបង្ហោះរបស់អ្នក។',
  'liked your comment.': 'បានចូលចិត្តមតិរបស់អ្នក។',
  'liked your comment': 'បានចូលចិត្តមតិរបស់អ្នក។',
  'shared your post.': 'បានចែករំលែកការបង្ហោះរបស់អ្នក។',
  'shared your post': 'បានចែករំលែកការបង្ហោះរបស់អ្នក។',
  'thanks for letting us know. our team will review your report.':
      'សូមអរគុណដែលបានប្រាប់យើង។ ក្រុមការងាររបស់យើងនឹងពិនិត្យមើលរបាយការណ៍របស់អ្នក។',
  'your report has been reviewed. thank you for helping keep nhamhealth safe.':
      'របាយការណ៍របស់អ្នកត្រូវបានពិនិត្យរួចរាល់។ សូមអរគុណដែលបានជួយរក្សាសុវត្ថិភាព NhamHealth។',
  'an administrator accepted your profile report and is reviewing it.':
      'អ្នកគ្រប់គ្រងបានទទួលយករបាយការណ៍គណនីរបស់អ្នក ហើយកំពុងពិនិត្យមើល។',
  'we reviewed your report and did not find a community guidelines violation.':
      'យើងបានពិនិត្យរបាយការណ៍របស់អ្នក ហើយរកមិនឃើញការបំពានគោលការណ៍សហគមន៍ទេ។',
  'thank you for helping keep the community safe. we reviewed your report and took appropriate action.':
      'សូមអរគុណដែលបានជួយរក្សាសុវត្ថិភាពសហគមន៍។ យើងបានពិនិត្យរបាយការណ៍របស់អ្នក និងចាត់វិធានការសមស្រប។',
  'report reviewed — we reviewed the reported content and did not find a community guidelines violation.':
      'របាយការណ៍ត្រូវបានពិនិត្យ — យើងបានពិនិត្យមាតិកាដែលបានរាយការណ៍ ហើយរកមិនឃើញការបំពានគោលការណ៍សហគមន៍ទេ។',
  'report reviewed — thank you for helping keep the community safe. we reviewed the content and took appropriate action.':
      'របាយការណ៍ត្រូវបានពិនិត្យ — សូមអរគុណដែលបានជួយរក្សាសុវត្ថិភាពសហគមន៍។ យើងបានពិនិត្យមាតិកា និងចាត់វិធានការសមស្រប។',
  'your nhamhealth password was changed successfully. if this was not you, secure your account now.':
      'ពាក្យសម្ងាត់ NhamHealth របស់អ្នកត្រូវបានផ្លាស់ប្តូរដោយជោគជ័យ។ ប្រសិនបើមិនមែនជាអ្នក សូមការពារគណនីរបស់អ្នកឥឡូវនេះ។',
  'no food was detected. open ai food check and try another clear photo.':
      'រកមិនឃើញម្ហូបអាហារទេ។ សូមបើកការពិនិត្យម្ហូប AI ហើយសាកល្បងថតរូបច្បាស់ម្តងទៀត។',
};

const Map<String, String> _notificationMessagesKmToEn = {
  'បានចាប់ផ្តើមតាមដានអ្នក។': 'started following you.',
  'បានតាមដានអ្នក។': 'followed you.',
  'បានឆ្លើយតបទៅមតិរបស់អ្នក។': 'replied to your comment.',
  'បានឆ្លើយតបទៅមតិលើការបង្ហោះរបស់អ្នក។': 'replied to a comment on your post.',
  'បានបញ្ចេញមតិលើការបង្ហោះរបស់អ្នក។': 'commented on your post.',
  'បានចូលចិត្តការបង្ហោះរបស់អ្នក។': 'liked your post.',
  'បានចូលចិត្តមតិរបស់អ្នក។': 'liked your comment.',
  'បានចែករំលែកការបង្ហោះរបស់អ្នក។': 'shared your post.',
  'សូមអរគុណដែលបានប្រាប់យើង។ ក្រុមការងាររបស់យើងនឹងពិនិត្យមើលរបាយការណ៍របស់អ្នក។':
      'Thanks for letting us know. Our team will review your report.',
  'របាយការណ៍របស់អ្នកត្រូវបានពិនិត្យរួចរាល់។ សូមអរគុណដែលបានជួយរក្សាសុវត្ថិភាព NhamHealth។':
      'Your report has been reviewed. Thank you for helping keep NhamHealth safe.',
  'អ្នកគ្រប់គ្រងបានទទួលយករបាយការណ៍គណនីរបស់អ្នក ហើយកំពុងពិនិត្យមើល។':
      'An administrator accepted your profile report and is reviewing it.',
  'យើងបានពិនិត្យរបាយការណ៍របស់អ្នក ហើយរកមិនឃើញការបំពានគោលការណ៍សហគមន៍ទេ។':
      'We reviewed your report and did not find a Community Guidelines violation.',
  'សូមអរគុណដែលបានជួយរក្សាសុវត្ថិភាពសហគមន៍។ យើងបានពិនិត្យរបាយការណ៍របស់អ្នក និងចាត់វិធានការសមស្រប។':
      'Thank you for helping keep the community safe. We reviewed your report and took appropriate action.',
  'របាយការណ៍ត្រូវបានពិនិត្យ — យើងបានពិនិត្យមាតិកាដែលបានរាយការណ៍ ហើយរកមិនឃើញការបំពានគោលការណ៍សហគមន៍ទេ។':
      'Report reviewed — we reviewed the reported content and did not find a Community Guidelines violation.',
  'របាយការណ៍ត្រូវបានពិនិត្យ — សូមអរគុណដែលបានជួយរក្សាសុវត្ថិភាពសហគមន៍។ យើងបានពិនិត្យមាតិកា និងចាត់វិធានការសមស្រប។':
      'Report reviewed — thank you for helping keep the community safe. We reviewed the content and took appropriate action.',
  'ពាក្យសម្ងាត់ NhamHealth របស់អ្នកត្រូវបានផ្លាស់ប្តូរដោយជោគជ័យ។ ប្រសិនបើមិនមែនជាអ្នក សូមការពារគណនីរបស់អ្នកឥឡូវនេះ។':
      'Your NhamHealth password was changed successfully. If this was not you, secure your account now.',
  'រកមិនឃើញម្ហូបអាហារទេ។ សូមបើកការពិនិត្យម្ហូប AI ហើយសាកល្បងថតរូបច្បាស់ម្តងទៀត។':
      'No food was detected. Open AI Food Check and try another clear photo.',
};

String localizeNotificationTitle(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return trimmed;
  final isKm = Get.locale?.languageCode == 'km';
  if (isKm) {
    final lower = trimmed.toLowerCase();
    if (_notificationTitlesEnToKm.containsKey(lower)) {
      return _notificationTitlesEnToKm[lower]!;
    }
  } else {
    if (_notificationTitlesKmToEn.containsKey(trimmed)) {
      return _notificationTitlesKmToEn[trimmed]!;
    }
  }
  return trimmed;
}

String localizeNotificationMessage(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty) return trimmed;
  final isKm = Get.locale?.languageCode == 'km';
  if (isKm) {
    final lower = trimmed.toLowerCase();
    if (_notificationMessagesEnToKm.containsKey(lower)) {
      return _notificationMessagesEnToKm[lower]!;
    }
    final aiAnalysisMatch = RegExp(
      r'^(.*?)\s+was analyzed\.\s+Open the result to review the nutrition details\.?$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (aiAnalysisMatch != null) {
      final dish = localizeDishName(aiAnalysisMatch.group(1)!);
      return '$dish ត្រូវបានវិភាគរួចរាល់។ បើកលទ្ធផលដើម្បីពិនិត្យមើលព័ត៌មានលម្អិតអំពីអាហារូបត្ថម្ភ។';
    }
  } else {
    if (_notificationMessagesKmToEn.containsKey(trimmed)) {
      return _notificationMessagesKmToEn[trimmed]!;
    }
    final aiAnalysisMatchKm = RegExp(
      r'^(.*?)\s+ត្រូវបានវិភាគរួចរាល់។\s+បើកលទ្ធផលដើម្បីពិនិត្យមើលព័ត៌មានលម្អិតអំពីអាហារូបត្ថម្ភ\.?$',
    ).firstMatch(trimmed);
    if (aiAnalysisMatchKm != null) {
      final dish = localizeDishName(aiAnalysisMatchKm.group(1)!);
      return '$dish was analyzed. Open the result to review the nutrition details.';
    }
  }
  return trimmed;
}

