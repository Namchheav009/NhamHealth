class CommunityRecipe {
  const CommunityRecipe({
    required this.id, required this.name, required this.description,
    required this.status, required this.cookingTimeMinutes, required this.servings,
    required this.ingredients, required this.steps, this.imageUrl = '', this.review,
    this.postId, this.mealId, this.saved = false, this.difficulty = '', this.aiStatus = 'PENDING', this.aiReviewReason = '',
    this.authorName = '', this.tags = const [], this.publishedAt, this.createdAt, this.updatedAt,
  });
  final int id;
  final String name, description, status, imageUrl, difficulty, aiStatus, aiReviewReason, authorName;
  final int? cookingTimeMinutes, servings, postId, mealId;
  final List<String> tags;
  final DateTime? publishedAt, createdAt, updatedAt;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final RecipeReview? review;
  final bool saved;
  factory CommunityRecipe.fromJson(Map<String, dynamic> json) => CommunityRecipe(
    id: (json['id'] as num).toInt(), name: '${json['recipeName'] ?? ''}', description: '${json['description'] ?? ''}',
    imageUrl: '${json['mainImageUrl'] ?? ''}', status: '${json['status'] ?? 'DRAFT'}',
    cookingTimeMinutes: (json['cookingTimeMinutes'] as num?)?.toInt(), servings: (json['servings'] as num?)?.toInt(),
    postId: (json['postId'] as num?)?.toInt(), mealId: (json['mealId'] as num?)?.toInt(), saved: json['saved'] == true,
    difficulty: '${json['difficulty'] ?? ''}', aiStatus: '${json['aiStatus'] ?? 'PENDING'}', aiReviewReason: '${json['aiReviewReason'] ?? ''}',
    authorName: '${json['authorName'] ?? ''}',
    tags: (json['tags'] as List<dynamic>? ?? const []).map((tag) => '$tag').toList(growable: false),
    publishedAt: DateTime.tryParse('${json['publishedAt'] ?? ''}'),
    createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
    updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}'),
    ingredients: (json['ingredients'] as List<dynamic>? ?? const []).map((value) => RecipeIngredient.fromJson(Map<String, dynamic>.from(value as Map))).toList(),
    steps: (json['steps'] as List<dynamic>? ?? const []).map((value) => RecipeStep.fromJson(Map<String, dynamic>.from(value as Map))).toList(),
    review: json['latestReview'] is Map ? RecipeReview.fromJson(Map<String, dynamic>.from(json['latestReview'] as Map)) : null,
  );
}
class RecipeIngredient { const RecipeIngredient(this.name, {this.amount, this.unit = '', this.preparationNote = ''}); final String name, unit, preparationNote; final num? amount; factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient('${json['name'] ?? ''}', amount: json['amount'] as num?, unit: '${json['unit'] ?? ''}', preparationNote: '${json['preparationNote'] ?? ''}'); Map<String, dynamic> toJson() => {'name': name, if (amount != null) 'amount': amount, if (unit.isNotEmpty) 'unit': unit, if (preparationNote.isNotEmpty) 'preparationNote': preparationNote}; }
class RecipeStep { const RecipeStep(this.instruction, {this.title = ''}); final String title, instruction; factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep('${json['instruction'] ?? ''}', title: '${json['title'] ?? ''}'); Map<String, dynamic> toJson() => {'title': title, 'instruction': instruction}; }
class RecipeReview { const RecipeReview(this.status, this.summary, this.feedback); final String status, summary, feedback; factory RecipeReview.fromJson(Map<String, dynamic> json) => RecipeReview('${json['status'] ?? ''}', '${json['summary'] ?? ''}', '${json['feedback'] ?? ''}'); }
