class IngredientSuggestion {
  const IngredientSuggestion({
    required this.id,
    required this.name,
    this.defaultUnit = '',
  });

  final int id;
  final String name;
  final String defaultUnit;

  factory IngredientSuggestion.fromJson(Map<String, dynamic> json) =>
      IngredientSuggestion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: '${json['name'] ?? ''}'.trim(),
        defaultUnit: '${json['defaultUnit'] ?? ''}'.trim(),
      );
}
