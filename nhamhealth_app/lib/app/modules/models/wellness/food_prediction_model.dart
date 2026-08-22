class FoodPredictionModel {
  final String foodName;
  final double confidence;
  final int? classIndex;

  const FoodPredictionModel({
    required this.foodName,
    required this.confidence,
    this.classIndex,
  });
}
