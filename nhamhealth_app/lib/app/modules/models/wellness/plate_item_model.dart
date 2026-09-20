/// State representing an individual food/drink component on a scanned plate.
class PlateItemState {
  PlateItemState({
    required this.id,
    required this.name,
    required this.baseCalories,
    required this.baseProtein,
    required this.baseCarbs,
    required this.baseFat,
    this.baseSugar = 0,
    this.baseFiber = 0,
    this.baseSodium = 0,
    this.baseServingSize = 100,
    this.unit = 'g',
    this.portionMultiplier = 1.0,
    this.isSelected = true,
    this.componentType = 'food',
    this.confidence = 0.9,
    this.preparationMethod = '',
    this.visibleEvidence = '',
    this.role = '',
    this.imageUrl,
  });

  final String id;
  String name;
  double baseCalories;
  double baseProtein;
  double baseCarbs;
  double baseFat;
  double baseSugar;
  double baseFiber;
  double baseSodium;
  double baseServingSize;
  String unit;
  double portionMultiplier;
  bool isSelected;
  String componentType;
  double confidence;
  String preparationMethod;
  String visibleEvidence;
  String role;
  String? imageUrl;

  double get calories => baseCalories * portionMultiplier;
  double get protein => baseProtein * portionMultiplier;
  double get carbs => baseCarbs * portionMultiplier;
  double get fat => baseFat * portionMultiplier;
  double get sugar => baseSugar * portionMultiplier;
  double get fiber => baseFiber * portionMultiplier;
  double get sodium => baseSodium * portionMultiplier;
  double get servingSize => baseServingSize * portionMultiplier;

  bool get isHighConfidence => confidence >= 0.8;
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.8;

  String get portionLabel {
    if (portionMultiplier == 0.5) return 'Small (0.5x)';
    if (portionMultiplier == 1.0) return 'Regular (1.0x)';
    if (portionMultiplier == 1.5) return 'Large (1.5x)';
    if (portionMultiplier == 2.0) return 'X-Large (2.0x)';
    return '${portionMultiplier.toStringAsFixed(1)}x';
  }

  PlateItemState clone() => PlateItemState(
    id: id,
    name: name,
    baseCalories: baseCalories,
    baseProtein: baseProtein,
    baseCarbs: baseCarbs,
    baseFat: baseFat,
    baseSugar: baseSugar,
    baseFiber: baseFiber,
    baseSodium: baseSodium,
    baseServingSize: baseServingSize,
    unit: unit,
    portionMultiplier: portionMultiplier,
    isSelected: isSelected,
    componentType: componentType,
    confidence: confidence,
    preparationMethod: preparationMethod,
    visibleEvidence: visibleEvidence,
    role: role,
    imageUrl: imageUrl,
  );
}
