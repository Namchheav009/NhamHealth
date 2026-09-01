class MealModel {
  MealModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.image,
    required this.category,
    required this.categoryId,
    this.description = '',
    this.cookingTimeMinutes,
    this.difficulty = '',
    this.servings,
    this.recommendationReason = '',
    this.isFavorite = false,
    this.ingredients = const [],
    this.nutrition = const [],
    this.steps = const [],
  });

  final int id;
  final String name;
  final int calories;
  final String image;
  final String category;
  final int categoryId;
  final String description;
  final int? cookingTimeMinutes;
  final String difficulty;
  final int? servings;
  final String recommendationReason;
  bool isFavorite;
  final List<MealIngredientModel> ingredients;
  final List<MealNutritionModel> nutrition;
  final List<MealStepModel> steps;

  factory MealModel.fromJson(
    Map<String, dynamic> json, {
    required String baseUrl,
  }) {
    final id = json['id'];
    final name = (json['name'] as String? ?? '').trim();
    if (id is! num || name.isEmpty) {
      throw const FormatException('Meal data is incomplete.');
    }
    final rawImage = (json['imageUrl'] as String? ?? '').trim();
    return MealModel(
      id: id.toInt(),
      name: name,
      calories: (json['calories'] as num?)?.round() ?? 0,
      image: _resolveImageUrl(rawImage, baseUrl),
      category: (json['category'] as String? ?? 'Uncategorized').trim(),
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      description: (json['description'] as String? ?? '').trim(),
      cookingTimeMinutes: (json['cookingTimeMinutes'] as num?)?.toInt(),
      difficulty: (json['difficulty'] as String? ?? '').trim(),
      servings: (json['servings'] as num?)?.toInt(),
    );
  }

  factory MealModel.fromDetailJson(Map<String, dynamic> json, {required String baseUrl}) {
    final meal = MealModel.fromJson(json, baseUrl: baseUrl);
    return MealModel(
      id: meal.id, name: meal.name, calories: meal.calories, image: meal.image,
      category: meal.category, categoryId: meal.categoryId, description: meal.description,
      cookingTimeMinutes: meal.cookingTimeMinutes, difficulty: meal.difficulty,
      servings: meal.servings,
      ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
          .map((item) => MealIngredientModel.fromJson(Map<String, dynamic>.from(item as Map), baseUrl: baseUrl))
          .toList(growable: false),
      nutrition: (json['nutrition'] as List<dynamic>? ?? const [])
          .map((item) => MealNutritionModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      steps: (json['steps'] as List<dynamic>? ?? const [])
          .map((item) => MealStepModel.fromJson(Map<String, dynamic>.from(item as Map), baseUrl: baseUrl))
          .toList(growable: false),
    );
  }

  factory MealModel.fromRecommendationJson(
    Map<String, dynamic> json, {
    required String baseUrl,
  }) {
    final id = json['id'];
    final name = (json['name'] as String? ?? '').trim();
    if (id is! num || name.isEmpty) {
      throw const FormatException('Recommended meal data is incomplete.');
    }
    final rawImage = (json['imageUrl'] as String? ?? '').trim();
    return MealModel(
      id: id.toInt(),
      name: name,
      calories: (json['calories'] as num?)?.round() ?? 0,
      image: _resolveImageUrl(rawImage, baseUrl),
      category: 'AI Pick',
      categoryId: 0,
      cookingTimeMinutes: (json['cookingTimeMinutes'] as num?)?.toInt(),
      recommendationReason: (json['reason'] as String? ?? '').trim(),
    );
  }

  static String _resolveImageUrl(String image, String baseUrl) {
    if (image.isEmpty ||
        image.startsWith('http://') ||
        image.startsWith('https://') ||
        image.startsWith('assets/')) {
      return image;
    }
    final separator = image.startsWith('/') ? '' : '/';
    return '$baseUrl$separator$image';
  }
}

class MealIngredientModel {
  const MealIngredientModel({required this.name, required this.description, required this.image, this.quantity, this.unit = '', this.preparationNote = ''});
  final String name;
  final String description;
  final String image;
  final num? quantity;
  final String unit;
  final String preparationNote;

  factory MealIngredientModel.fromJson(Map<String, dynamic> json, {required String baseUrl}) => MealIngredientModel(
    name: (json['name'] as String? ?? '').trim(),
    description: (json['description'] as String? ?? '').trim(),
    image: MealModel._resolveImageUrl((json['imageUrl'] as String? ?? '').trim(), baseUrl),
    quantity: json['quantity'] as num?, unit: (json['unit'] as String? ?? '').trim(),
    preparationNote: (json['preparationNote'] as String? ?? '').trim(),
  );

  String get detail {
    final value = quantity;
    final displayValue = value is double && value == value.roundToDouble()
        ? value.toInt()
        : value;
    final amount = value == null ? '' : '$displayValue $unit'.trim();
    return [amount, preparationNote, description]
        .where((value) => value.isNotEmpty)
        .join(' - ');
  }
}

class MealNutritionModel {
  const MealNutritionModel({required this.name, required this.amount, required this.unit});
  final String name;
  final num amount;
  final String unit;
  factory MealNutritionModel.fromJson(Map<String, dynamic> json) => MealNutritionModel(
    name: (json['name'] as String? ?? '').trim(), amount: json['amount'] as num? ?? 0,
    unit: (json['unit'] as String? ?? '').trim(),
  );
}

class MealStepModel {
  const MealStepModel({required this.number, required this.title, required this.instruction, required this.image});
  final int number;
  final String title;
  final String instruction;
  final String image;
  factory MealStepModel.fromJson(Map<String, dynamic> json, {required String baseUrl}) => MealStepModel(
    number: (json['number'] as num?)?.toInt() ?? 0,
    title: (json['title'] as String? ?? '').trim(), instruction: (json['instruction'] as String? ?? '').trim(),
    image: MealModel._resolveImageUrl((json['imageUrl'] as String? ?? '').trim(), baseUrl),
  );
}
