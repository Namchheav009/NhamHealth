class NutritionProgressModel {
  final String title;
  final String value;
  final String target;
  final double progress;
  final String unit;

  const NutritionProgressModel({
    required this.title,
    required this.value,
    required this.target,
    required this.progress,
    required this.unit,
  });
}
