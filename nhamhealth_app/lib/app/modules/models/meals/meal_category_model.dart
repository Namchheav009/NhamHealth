class MealCategoryModel {
  const MealCategoryModel({required this.id, required this.name});

  static const all = MealCategoryModel(id: 0, name: 'All');

  final int id;
  final String name;

  factory MealCategoryModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = (json['name'] as String? ?? '').trim();
    if (id is! num || name.isEmpty) {
      throw const FormatException('Meal category data is incomplete.');
    }
    return MealCategoryModel(id: id.toInt(), name: name);
  }
}
