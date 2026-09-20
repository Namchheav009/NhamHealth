import '../../models/wellness/food_nutrition_model.dart';
import '../../models/wellness/plate_item_model.dart';
import 'ingredient_visual_service.dart';

/// Service that analyzes a composite food item and decomposes it into its
/// realistic culinary constituent ingredients.
///
/// This avoids redundant whole-dish ingredients (e.g. "Fried Rice" inside "Fried Rice")
/// and provides users with actionable, granular ingredient breakdowns including
/// accurate portion weights, macronutrient contributions, and culinary roles.
class FoodDecompositionService {
  FoodDecompositionService._();

  /// Decomposes [food] into a list of constituent [PlateItemState] ingredients.
  static List<PlateItemState> decompose(FoodNutritionModel food) {
    // 1. Check if the existing components already represent true, granular ingredients
    if (_hasGranularIngredients(food)) {
      return _mapExistingComponents(food);
    }

    // 2. Resolve a matching recipe template
    final template = _findTemplate(food);
    if (template != null) {
      return template.buildItems(food);
    }

    // 3. Fallback: dynamic heuristic decomposition based on macronutrient profile
    return _buildHeuristicDecomposition(food);
  }

  /// Determines whether the existing components already represent distinct,
  /// granular ingredients (and not just the whole dish repeated).
  static bool _hasGranularIngredients(FoodNutritionModel food) {
    if (food.components.isEmpty) return false;

    final normFoodName = food.name.trim().toLowerCase();
    final normMealName = food.mealName.trim().toLowerCase();

    // A single component is valid for simple foods and uniform dishes. Keep
    // the provider's image-grounded result instead of inventing a recipe.
    if (food.components.length == 1) {
      return food.components.first.name.trim().isNotEmpty;
    }

    // Check if any component is identical or nearly identical to the whole meal
    for (final c in food.components) {
      final cName = c.name.trim().toLowerCase();
      if (cName == normFoodName || cName == normMealName) {
        return false; // contains whole dish as a component
      }
      if (normFoodName.length > 4 && cName.contains(normFoodName)) {
        return false;
      }
    }

    // One or two visible components can be a complete analysis (for example,
    // steak with sauce). Requiring three caused valid AI results to be replaced
    // by generic template ingredients that were not necessarily visible.
    return true;
  }

  static List<PlateItemState> _mapExistingComponents(FoodNutritionModel food) {
    final list = <PlateItemState>[];
    for (var i = 0; i < food.components.length; i++) {
      final c = food.components[i];
      final visual = IngredientVisualService.resolve(
        c.name,
        componentType: c.componentType,
        visibleEvidence: c.visibleEvidence,
      );
      final servingSize =
          c.estimatedAmount > 0
              ? c.estimatedAmount
              : (c.liquidVolumeMl > 0 ? c.liquidVolumeMl : 100);
      final unit =
          c.liquidVolumeMl > 0 ? 'ml' : (c.unit.isNotEmpty ? c.unit : 'g');

      list.add(
        PlateItemState(
          id: 'comp_${i}_${DateTime.now().microsecondsSinceEpoch}',
          name: c.name,
          baseCalories: c.calories > 0 ? c.calories : 50,
          baseProtein: c.protein,
          baseCarbs: c.carbohydrates,
          baseFat: c.fat,
          baseSugar: c.sugar,
          baseFiber: c.fiber,
          baseSodium: c.sodium,
          baseServingSize: servingSize.toDouble(),
          unit: unit,
          portionMultiplier: 1.0,
          isSelected: true,
          componentType: c.componentType,
          confidence: c.confidence > 0 ? c.confidence : 0.9,
          portionConfidence: c.portionConfidence,
          preparationMethod: c.preparationMethod,
          visibleEvidence: c.visibleEvidence,
          databaseMatched: c.databaseMatched,
          databaseMatchConfidence: c.databaseMatchConfidence,
          nutritionSource: c.nutritionSource,
          requiresUserConfirmation: c.requiresUserConfirmation,
          role: visual.defaultRole,
          imageUrl:
              c.imageUrl?.isNotEmpty == true ? c.imageUrl : visual.imageUrl,
        ),
      );
    }
    return list;
  }

  static _DecompositionTemplate? _findTemplate(FoodNutritionModel food) {
    final query = '${food.name} ${food.mealName} ${food.cuisine}'.toLowerCase();

    for (final t in _templates) {
      if (t.matches(query)) {
        return t;
      }
    }
    return null;
  }

  /// Dynamic fallback decomposition for foods without an explicit template.
  static List<PlateItemState> _buildHeuristicDecomposition(
    FoodNutritionModel food,
  ) {
    final totalCalories = food.calories > 0 ? food.calories : 400.0;
    final totalProtein = food.protein > 0 ? food.protein : 15.0;
    final totalCarbs = food.carbs > 0 ? food.carbs : 50.0;
    final totalFat = food.fat > 0 ? food.fat : 12.0;
    final totalFiber = food.fiber > 0 ? food.fiber : 3.0;
    final totalSodium = food.sodium > 0 ? food.sodium : 500.0;
    final totalWeight =
        food.servingSize > 30
            ? food.servingSize
            : (food.servingUnit == 'ml' ? 350.0 : 320.0);

    final isDrink =
        food.mealType == 'drink' ||
        food.servingUnit == 'ml' ||
        food.requiresDrinkDetails;

    if (isDrink) {
      return _buildDrinkDecomposition(food, totalCalories, totalCarbs);
    }

    final items = <PlateItemState>[];
    final ts = DateTime.now().microsecondsSinceEpoch;

    // 1. Primary Carb / Grain component
    if (totalCarbs >= 15) {
      final carbWeight = (totalWeight * 0.48).roundToDouble();
      final carbCals = (totalCarbs * 4.0).clamp(0.0, totalCalories * 0.65);
      final carbName = _resolveCarbName(food.name);
      final visual = IngredientVisualService.resolve(carbName);
      items.add(
        PlateItemState(
          id: 'dec_carb_$ts',
          name: carbName,
          baseCalories: carbCals,
          baseProtein: totalProtein * 0.15,
          baseCarbs: totalCarbs * 0.85,
          baseFat: totalFat * 0.05,
          baseFiber: totalFiber * 0.3,
          baseServingSize: carbWeight,
          unit: 'g',
          portionMultiplier: 1.0,
          isSelected: true,
          confidence: 0.92,
          role: 'Carb base',
          imageUrl: visual.imageUrl,
        ),
      );
    }

    // 2. Primary Protein component
    if (totalProtein >= 6) {
      final proteinWeight = (totalWeight * 0.28).roundToDouble();
      final proteinCals = (totalProtein * 4.0 + totalFat * 0.4 * 9.0).clamp(
        0.0,
        totalCalories * 0.50,
      );
      final proteinName = _resolveProteinName(food.name);
      final visual = IngredientVisualService.resolve(proteinName);
      items.add(
        PlateItemState(
          id: 'dec_prot_$ts',
          name: proteinName,
          baseCalories: proteinCals,
          baseProtein: totalProtein * 0.75,
          baseCarbs: totalCarbs * 0.05,
          baseFat: totalFat * 0.40,
          baseServingSize: proteinWeight,
          unit: 'g',
          portionMultiplier: 1.0,
          isSelected: true,
          confidence: 0.90,
          role: 'Protein source',
          imageUrl: visual.imageUrl,
        ),
      );
    }

    // 3. Cooking Fat / Healthy Oils
    if (totalFat >= 5) {
      final oilWeight = (totalFat * 0.50).clamp(5.0, 25.0).roundToDouble();
      final oilCals = (totalFat * 0.50 * 9.0).clamp(0.0, totalCalories * 0.35);
      final visual = IngredientVisualService.resolve('Vegetable Cooking Oil');
      items.add(
        PlateItemState(
          id: 'dec_fat_$ts',
          name: 'Vegetable Cooking Oil',
          baseCalories: oilCals,
          baseProtein: 0,
          baseCarbs: 0,
          baseFat: totalFat * 0.50,
          baseServingSize: oilWeight,
          unit: 'g',
          portionMultiplier: 1.0,
          isSelected: true,
          confidence: 0.88,
          role: 'Cooking fat',
          imageUrl: visual.imageUrl,
        ),
      );
    }

    // 4. Fresh Vegetables / Greens
    final veggieWeight = (totalWeight * 0.16).roundToDouble();
    final visualVeg = IngredientVisualService.resolve('Fresh Mixed Vegetables');
    items.add(
      PlateItemState(
        id: 'dec_veg_$ts',
        name: 'Fresh Mixed Vegetables',
        baseCalories: (totalCalories * 0.06).clamp(15.0, 50.0),
        baseProtein: totalProtein * 0.08,
        baseCarbs: totalCarbs * 0.08,
        baseFat: 0.2,
        baseFiber: totalFiber * 0.7,
        baseServingSize: veggieWeight,
        unit: 'g',
        portionMultiplier: 1.0,
        isSelected: true,
        confidence: 0.86,
        role: 'Fresh greens',
        imageUrl: visualVeg.imageUrl,
      ),
    );

    // 5. Savory Seasoning & Aromatics
    final visualSeason = IngredientVisualService.resolve(
      'Savory Seasoning & Sauce',
    );
    items.add(
      PlateItemState(
        id: 'dec_season_$ts',
        name: 'Savory Seasoning & Sauce',
        baseCalories: 15.0,
        baseProtein: totalProtein * 0.02,
        baseCarbs: totalCarbs * 0.02,
        baseFat: 0.1,
        baseSodium: totalSodium,
        baseServingSize: 15.0,
        unit: 'ml',
        portionMultiplier: 1.0,
        isSelected: true,
        confidence: 0.90,
        role: 'Flavor seasoning',
        imageUrl: visualSeason.imageUrl,
      ),
    );

    return items;
  }

  static List<PlateItemState> _buildDrinkDecomposition(
    FoodNutritionModel food,
    double totalCalories,
    double totalCarbs,
  ) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final totalMl = food.servingSize > 50 ? food.servingSize : 350.0;
    final items = <PlateItemState>[];

    // Liquid base
    final isMatcha = food.name.toLowerCase().contains('matcha');
    final isCoffee = food.name.toLowerCase().contains('coffee');
    final baseName =
        isMatcha
            ? 'Matcha Green Tea Base'
            : (isCoffee ? 'Brewed Coffee Base' : 'Brewed Tea Base');
    final baseVisual = IngredientVisualService.resolve(baseName);
    items.add(
      PlateItemState(
        id: 'dec_drink_base_$ts',
        name: baseName,
        baseCalories: 5,
        baseCarbs: 1,
        baseProtein: 0.5,
        baseFat: 0,
        baseServingSize: (totalMl * 0.65).roundToDouble(),
        unit: 'ml',
        portionMultiplier: 1.0,
        isSelected: true,
        confidence: 0.95,
        role: 'Liquid base',
        imageUrl: baseVisual.imageUrl,
      ),
    );

    // Milk / Creamer if calories indicate dairy
    if (totalCalories >= 80) {
      final milkVisual = IngredientVisualService.resolve('Fresh Milk / Cream');
      items.add(
        PlateItemState(
          id: 'dec_drink_milk_$ts',
          name: 'Fresh Milk / Cream',
          baseCalories: totalCalories * 0.45,
          baseProtein: food.protein * 0.85,
          baseCarbs: totalCarbs * 0.20,
          baseFat: food.fat * 0.85,
          baseServingSize: (totalMl * 0.25).roundToDouble(),
          unit: 'ml',
          portionMultiplier: 1.0,
          isSelected: true,
          confidence: 0.90,
          role: 'Creamy base',
          imageUrl: milkVisual.imageUrl,
        ),
      );
    }

    // Sugar / Sweetener
    if (food.sugar > 4 || totalCarbs > 15) {
      final sugarVisual = IngredientVisualService.resolve('Sweetener / Syrup');
      items.add(
        PlateItemState(
          id: 'dec_drink_sugar_$ts',
          name: 'Sweetener / Syrup',
          baseCalories: totalCalories * 0.35,
          baseProtein: 0,
          baseCarbs: food.sugar > 0 ? food.sugar : totalCarbs * 0.60,
          baseFat: 0,
          baseSugar: food.sugar > 0 ? food.sugar : totalCarbs * 0.60,
          baseServingSize: 25.0,
          unit: 'ml',
          portionMultiplier: 1.0,
          isSelected: true,
          confidence: 0.92,
          role: 'Added sugar',
          imageUrl: sugarVisual.imageUrl,
        ),
      );
    }

    // Boba pearls if present
    if (food.name.toLowerCase().contains('boba') ||
        food.name.toLowerCase().contains('pearl') ||
        food.name.toLowerCase().contains('tea')) {
      final bobaVisual = IngredientVisualService.resolve('Tapioca Pearls');
      items.add(
        PlateItemState(
          id: 'dec_drink_boba_$ts',
          name: 'Tapioca Pearls (Boba)',
          baseCalories: 85,
          baseProtein: 0,
          baseCarbs: 21,
          baseFat: 0,
          baseServingSize: 45.0,
          unit: 'g',
          portionMultiplier: 1.0,
          isSelected: true,
          confidence: 0.88,
          role: 'Boba topping',
          imageUrl: bobaVisual.imageUrl,
        ),
      );
    }

    return items;
  }

  static String _resolveCarbName(String foodName) {
    final n = foodName.toLowerCase();
    if (n.contains('noodle') || n.contains('kuy teav') || n.contains('pho')) {
      return 'Rice Noodles';
    }
    if (n.contains('pasta') || n.contains('spaghetti')) {
      return 'Spaghetti Pasta';
    }
    if (n.contains('bread') || n.contains('sandwich') || n.contains('toast')) {
      return 'Whole Grain Bread';
    }
    if (n.contains('potato') || n.contains('fries')) {
      return 'Potatoes';
    }
    return 'Cooked Jasmine Rice';
  }

  static String _resolveProteinName(String foodName) {
    final n = foodName.toLowerCase();
    if (n.contains('chicken')) return 'Chicken Breast';
    if (n.contains('beef') || n.contains('steak')) return 'Beef Tenderloin';
    if (n.contains('pork') || n.contains('bacon')) return 'Marinated Pork';
    if (n.contains('fish')) return 'Fresh Fish Fillet';
    if (n.contains('shrimp') || n.contains('seafood')) return 'Fresh Shrimp';
    if (n.contains('tofu')) return 'Organic Tofu';
    if (n.contains('egg') || n.contains('omelet')) return 'Farm Fresh Egg';
    return 'Tender Protein Cut';
  }

  // ---------------------------------------------------------------------------
  // Recipe Templates for Specific Meals
  // ---------------------------------------------------------------------------

  static final List<_DecompositionTemplate> _templates = [
    // 1. Fried Rice / Bai Cha
    _DecompositionTemplate(
      keywords: ['fried rice', 'bai cha', 'cha rice', 'fried-rice', 'បាយឆា'],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 510.0;
        final totalProt = food.protein > 0 ? food.protein : 18.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 72.0;
        final totalFat = food.fat > 0 ? food.fat : 17.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 350.0;

        final hasChicken = food.name.toLowerCase().contains('chicken');
        final hasPork = food.name.toLowerCase().contains('pork');
        final hasShrimp =
            food.name.toLowerCase().contains('shrimp') ||
            food.name.toLowerCase().contains('seafood');
        final hasBeef = food.name.toLowerCase().contains('beef');
        final hasAddedMeat = hasChicken || hasPork || hasShrimp || hasBeef;

        final meatName =
            hasChicken
                ? 'Diced Chicken Breast'
                : (hasPork
                    ? 'Diced Pork'
                    : (hasBeef ? 'Diced Beef' : 'Fresh Shrimp'));

        return [
              _IngredientFormula(
                name: 'Cooked Jasmine Rice',
                role: 'Carb base',
                weightRatio: hasAddedMeat ? 0.54 : 0.62,
                calRatio: hasAddedMeat ? 0.48 : 0.54,
                protRatio: 0.22,
                carbsRatio: 0.82,
                fatRatio: 0.06,
                fiberRatio: 0.25,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Scrambled Egg',
                role: 'Whole protein',
                weightRatio: hasAddedMeat ? 0.12 : 0.16,
                calRatio: 0.16,
                protRatio: hasAddedMeat ? 0.32 : 0.48,
                carbsRatio: 0.01,
                fatRatio: 0.32,
                confidence: 0.93,
              ),
              if (hasAddedMeat)
                _IngredientFormula(
                  name: meatName,
                  role: 'Lean protein',
                  weightRatio: 0.16,
                  calRatio: 0.18,
                  protRatio: 0.36,
                  carbsRatio: 0.02,
                  fatRatio: 0.15,
                  confidence: 0.91,
                ),
              _IngredientFormula(
                name: 'Vegetable Cooking Oil',
                role: 'Cooking fat',
                weightRatio: 0.04,
                calRatio: 0.20,
                protRatio: 0.0,
                carbsRatio: 0.0,
                fatRatio: 0.58,
                confidence: 0.92,
              ),
              _IngredientFormula(
                name: 'Spring Onions & Carrots',
                role: 'Fresh greens',
                weightRatio: 0.12,
                calRatio: 0.06,
                protRatio: 0.08,
                carbsRatio: 0.10,
                fatRatio: 0.01,
                fiberRatio: 0.70,
                confidence: 0.89,
              ),
              _IngredientFormula(
                name: 'Soy Sauce & Garlic',
                role: 'Flavor seasoning',
                weightRatio: 0.06,
                calRatio: 0.03,
                protRatio: 0.04,
                carbsRatio: 0.05,
                fatRatio: 0.01,
                sodiumRatio: 0.85,
                confidence: 0.91,
                unit: 'ml',
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),

    // 2. Beef Lok Lak
    _DecompositionTemplate(
      keywords: ['lok lak', 'loklak', 'shaking beef', 'ឡុកឡាក់'],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 560.0;
        final totalProt = food.protein > 0 ? food.protein : 38.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 42.0;
        final totalFat = food.fat > 0 ? food.fat : 25.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 380.0;

        return [
              _IngredientFormula(
                name: 'Beef Tenderloin Cubes',
                role: 'Protein source',
                weightRatio: 0.36,
                calRatio: 0.44,
                protRatio: 0.78,
                carbsRatio: 0.02,
                fatRatio: 0.60,
                confidence: 0.94,
              ),
              _IngredientFormula(
                name: 'Steamed Jasmine Rice',
                role: 'Carb base',
                weightRatio: 0.42,
                calRatio: 0.38,
                protRatio: 0.14,
                carbsRatio: 0.86,
                fatRatio: 0.04,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Crisp Lettuce & Tomatoes',
                role: 'Fresh greens',
                weightRatio: 0.14,
                calRatio: 0.05,
                protRatio: 0.04,
                carbsRatio: 0.08,
                fatRatio: 0.02,
                fiberRatio: 0.75,
                confidence: 0.90,
              ),
              _IngredientFormula(
                name: 'Lime & Black Pepper Sauce',
                role: 'Flavor seasoning',
                weightRatio: 0.05,
                calRatio: 0.05,
                protRatio: 0.02,
                carbsRatio: 0.04,
                fatRatio: 0.08,
                sodiumRatio: 0.70,
                confidence: 0.92,
                unit: 'ml',
              ),
              _IngredientFormula(
                name: 'Stir-Fry Garlic Oil',
                role: 'Cooking fat',
                weightRatio: 0.03,
                calRatio: 0.08,
                protRatio: 0.02,
                carbsRatio: 0.0,
                fatRatio: 0.26,
                confidence: 0.88,
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),

    // 3. Bai Sach Chrouk (Pork Rice)
    _DecompositionTemplate(
      keywords: [
        'bai sach chrouk',
        'pork rice',
        'grilled pork rice',
        'បាយសាច់ជ្រូក',
      ],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 500.0;
        final totalProt = food.protein > 0 ? food.protein : 25.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 65.0;
        final totalFat = food.fat > 0 ? food.fat : 16.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 370.0;

        return [
              _IngredientFormula(
                name: 'Grilled Marinated Pork',
                role: 'Protein source',
                weightRatio: 0.32,
                calRatio: 0.45,
                protRatio: 0.76,
                carbsRatio: 0.06,
                fatRatio: 0.65,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Broken Jasmine Rice',
                role: 'Carb base',
                weightRatio: 0.44,
                calRatio: 0.40,
                protRatio: 0.16,
                carbsRatio: 0.82,
                fatRatio: 0.06,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Pickled Daikon & Cucumber',
                role: 'Pickled veggies',
                weightRatio: 0.12,
                calRatio: 0.04,
                protRatio: 0.02,
                carbsRatio: 0.08,
                fatRatio: 0.0,
                fiberRatio: 0.60,
                confidence: 0.90,
              ),
              _IngredientFormula(
                name: 'Scallion & Garlic Oil',
                role: 'Cooking fat',
                weightRatio: 0.03,
                calRatio: 0.08,
                protRatio: 0.0,
                carbsRatio: 0.01,
                fatRatio: 0.26,
                confidence: 0.89,
              ),
              _IngredientFormula(
                name: 'Clear Scallion Broth',
                role: 'Broth base',
                weightRatio: 0.09,
                calRatio: 0.03,
                protRatio: 0.06,
                carbsRatio: 0.03,
                fatRatio: 0.03,
                confidence: 0.87,
                unit: 'ml',
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),

    // 4. Kuy Teav (Khmer Noodle Soup / Pho)
    _DecompositionTemplate(
      keywords: [
        'kuy teav',
        'kuyteav',
        'noodle soup',
        'rice noodle soup',
        'គុយទាវ',
        'pho',
      ],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 400.0;
        final totalProt = food.protein > 0 ? food.protein : 22.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 55.0;
        final totalFat = food.fat > 0 ? food.fat : 10.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 450.0;

        return [
              _IngredientFormula(
                name: 'Flat Rice Noodles',
                role: 'Noodle base',
                weightRatio: 0.36,
                calRatio: 0.46,
                protRatio: 0.16,
                carbsRatio: 0.84,
                fatRatio: 0.06,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Sliced Pork & Meatballs',
                role: 'Protein source',
                weightRatio: 0.20,
                calRatio: 0.32,
                protRatio: 0.65,
                carbsRatio: 0.02,
                fatRatio: 0.50,
                confidence: 0.92,
              ),
              _IngredientFormula(
                name: 'Savory Bone Broth',
                role: 'Broth base',
                weightRatio: 0.30,
                calRatio: 0.12,
                protRatio: 0.12,
                carbsRatio: 0.04,
                fatRatio: 0.20,
                confidence: 0.90,
                unit: 'ml',
              ),
              _IngredientFormula(
                name: 'Bean Sprouts & Fresh Herbs',
                role: 'Fresh greens',
                weightRatio: 0.11,
                calRatio: 0.04,
                protRatio: 0.05,
                carbsRatio: 0.08,
                fatRatio: 0.02,
                fiberRatio: 0.70,
                confidence: 0.88,
              ),
              _IngredientFormula(
                name: 'Fried Garlic Oil',
                role: 'Flavor seasoning',
                weightRatio: 0.03,
                calRatio: 0.06,
                protRatio: 0.02,
                carbsRatio: 0.02,
                fatRatio: 0.22,
                confidence: 0.90,
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),

    // 5. Num Banh Chok
    _DecompositionTemplate(
      keywords: ['num banh chok', 'nom banh chok', 'នំបញ្ចុក'],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 380.0;
        final totalProt = food.protein > 0 ? food.protein : 14.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 62.0;
        final totalFat = food.fat > 0 ? food.fat : 9.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 420.0;

        return [
              _IngredientFormula(
                name: 'Fermented Rice Noodles',
                role: 'Noodle base',
                weightRatio: 0.42,
                calRatio: 0.48,
                protRatio: 0.18,
                carbsRatio: 0.82,
                fatRatio: 0.05,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Fish Kroeung Curry Broth',
                role: 'Broth base',
                weightRatio: 0.35,
                calRatio: 0.38,
                protRatio: 0.68,
                carbsRatio: 0.08,
                fatRatio: 0.70,
                confidence: 0.92,
                unit: 'ml',
              ),
              _IngredientFormula(
                name: 'Banana Blossom & Cucumbers',
                role: 'Fresh greens',
                weightRatio: 0.18,
                calRatio: 0.08,
                protRatio: 0.08,
                carbsRatio: 0.08,
                fatRatio: 0.05,
                fiberRatio: 0.75,
                confidence: 0.90,
              ),
              _IngredientFormula(
                name: 'Fresh Mint & Basil',
                role: 'Fresh herbs',
                weightRatio: 0.05,
                calRatio: 0.06,
                protRatio: 0.06,
                carbsRatio: 0.02,
                fatRatio: 0.20,
                confidence: 0.88,
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),

    // 6. Fish Amok
    _DecompositionTemplate(
      keywords: ['fish amok', 'amok trey', 'amok', 'អាម៉ុកត្រី'],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 420.0;
        final totalProt = food.protein > 0 ? food.protein : 29.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 18.0;
        final totalFat = food.fat > 0 ? food.fat : 25.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 340.0;

        return [
              _IngredientFormula(
                name: 'Steamed River Fish Fillet',
                role: 'Healthy seafood',
                weightRatio: 0.40,
                calRatio: 0.40,
                protRatio: 0.75,
                carbsRatio: 0.02,
                fatRatio: 0.22,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Coconut Kroeung Curry Cream',
                role: 'Creamy curry',
                weightRatio: 0.35,
                calRatio: 0.44,
                protRatio: 0.12,
                carbsRatio: 0.25,
                fatRatio: 0.68,
                confidence: 0.93,
                unit: 'ml',
              ),
              _IngredientFormula(
                name: 'Noni Leaves & Red Chili',
                role: 'Fresh herbs',
                weightRatio: 0.15,
                calRatio: 0.08,
                protRatio: 0.08,
                carbsRatio: 0.15,
                fatRatio: 0.05,
                fiberRatio: 0.70,
                confidence: 0.90,
              ),
              _IngredientFormula(
                name: 'Steamed Jasmine Rice (Side)',
                role: 'Carb base',
                weightRatio: 0.10,
                calRatio: 0.08,
                protRatio: 0.05,
                carbsRatio: 0.58,
                fatRatio: 0.05,
                confidence: 0.88,
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),

    // 7. Chicken Rice
    _DecompositionTemplate(
      keywords: ['chicken rice', 'rice with chicken', 'hainanese', 'បាយមាន់'],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 520.0;
        final totalProt = food.protein > 0 ? food.protein : 32.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 65.0;
        final totalFat = food.fat > 0 ? food.fat : 15.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 380.0;

        return [
              _IngredientFormula(
                name: 'Steamed Tender Chicken',
                role: 'Lean protein',
                weightRatio: 0.34,
                calRatio: 0.42,
                protRatio: 0.76,
                carbsRatio: 0.02,
                fatRatio: 0.55,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Chicken Broth Jasmine Rice',
                role: 'Carb base',
                weightRatio: 0.46,
                calRatio: 0.44,
                protRatio: 0.16,
                carbsRatio: 0.86,
                fatRatio: 0.25,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Fresh Cucumber Slices',
                role: 'Fresh greens',
                weightRatio: 0.12,
                calRatio: 0.04,
                protRatio: 0.02,
                carbsRatio: 0.06,
                fatRatio: 0.0,
                fiberRatio: 0.60,
                confidence: 0.92,
              ),
              _IngredientFormula(
                name: 'Ginger Chili Dipping Sauce',
                role: 'Flavor seasoning',
                weightRatio: 0.08,
                calRatio: 0.10,
                protRatio: 0.06,
                carbsRatio: 0.06,
                fatRatio: 0.20,
                sodiumRatio: 0.75,
                confidence: 0.91,
                unit: 'ml',
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),

    // 8. Hamburger / Cheeseburger
    _DecompositionTemplate(
      keywords: ['burger', 'hamburger', 'cheeseburger'],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 420.0;
        final totalProt = food.protein > 0 ? food.protein : 23.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 31.0;
        final totalFat = food.fat > 0 ? food.fat : 23.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 220.0;
        final isCheese = food.name.toLowerCase().contains('cheese');

        return [
              _IngredientFormula(
                name: 'Toasted Sesame Bun',
                role: 'Baked carb',
                weightRatio: 0.38,
                calRatio: 0.36,
                protRatio: 0.16,
                carbsRatio: 0.78,
                fatRatio: 0.10,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Grilled Beef Patty',
                role: 'Protein source',
                weightRatio: 0.40,
                calRatio: 0.42,
                protRatio: 0.68,
                carbsRatio: 0.02,
                fatRatio: 0.62,
                confidence: 0.94,
              ),
              if (isCheese)
                _IngredientFormula(
                  name: 'Cheddar Cheese Slice',
                  role: 'Dairy / fat',
                  weightRatio: 0.10,
                  calRatio: 0.12,
                  protRatio: 0.10,
                  carbsRatio: 0.02,
                  fatRatio: 0.16,
                  confidence: 0.92,
                ),
              _IngredientFormula(
                name: 'Lettuce, Tomato & Onion',
                role: 'Fresh greens',
                weightRatio: 0.08,
                calRatio: 0.03,
                protRatio: 0.02,
                carbsRatio: 0.06,
                fatRatio: 0.01,
                fiberRatio: 0.65,
                confidence: 0.90,
              ),
              _IngredientFormula(
                name: 'Burger Sauce & Mustard',
                role: 'Flavor seasoning',
                weightRatio: 0.04,
                calRatio: 0.07,
                protRatio: 0.04,
                carbsRatio: 0.12,
                fatRatio: 0.11,
                confidence: 0.88,
                unit: 'ml',
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),

    // 9. Pizza
    _DecompositionTemplate(
      keywords: ['pizza'],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 285.0;
        final totalProt = food.protein > 0 ? food.protein : 12.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 36.0;
        final totalFat = food.fat > 0 ? food.fat : 10.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 150.0;

        return [
              _IngredientFormula(
                name: 'Crispy Pizza Crust',
                role: 'Baked carb',
                weightRatio: 0.48,
                calRatio: 0.45,
                protRatio: 0.20,
                carbsRatio: 0.80,
                fatRatio: 0.15,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Melted Mozzarella Cheese',
                role: 'Dairy / protein',
                weightRatio: 0.28,
                calRatio: 0.35,
                protRatio: 0.60,
                carbsRatio: 0.05,
                fatRatio: 0.60,
                confidence: 0.94,
              ),
              _IngredientFormula(
                name: 'Italian Tomato Pizza Sauce',
                role: 'Sauce base',
                weightRatio: 0.14,
                calRatio: 0.08,
                protRatio: 0.05,
                carbsRatio: 0.10,
                fatRatio: 0.05,
                fiberRatio: 0.45,
                confidence: 0.91,
              ),
              _IngredientFormula(
                name: 'Olive Oil & Herbs',
                role: 'Flavor seasoning',
                weightRatio: 0.10,
                calRatio: 0.12,
                protRatio: 0.15,
                carbsRatio: 0.05,
                fatRatio: 0.20,
                confidence: 0.88,
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),

    // 10. Sandwich
    _DecompositionTemplate(
      keywords: ['sandwich', 'toast'],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 350.0;
        final totalProt = food.protein > 0 ? food.protein : 20.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 38.0;
        final totalFat = food.fat > 0 ? food.fat : 13.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 200.0;

        return [
              _IngredientFormula(
                name: 'Sliced Whole Grain Bread',
                role: 'Baked carb',
                weightRatio: 0.42,
                calRatio: 0.42,
                protRatio: 0.18,
                carbsRatio: 0.78,
                fatRatio: 0.10,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Sliced Protein Filling',
                role: 'Lean protein',
                weightRatio: 0.32,
                calRatio: 0.34,
                protRatio: 0.65,
                carbsRatio: 0.04,
                fatRatio: 0.35,
                confidence: 0.93,
              ),
              _IngredientFormula(
                name: 'Sliced Cheese',
                role: 'Dairy / fat',
                weightRatio: 0.10,
                calRatio: 0.12,
                protRatio: 0.12,
                carbsRatio: 0.02,
                fatRatio: 0.35,
                confidence: 0.91,
              ),
              _IngredientFormula(
                name: 'Crisp Lettuce & Tomato',
                role: 'Fresh greens',
                weightRatio: 0.12,
                calRatio: 0.04,
                protRatio: 0.02,
                carbsRatio: 0.06,
                fatRatio: 0.0,
                fiberRatio: 0.60,
                confidence: 0.90,
              ),
              _IngredientFormula(
                name: 'Light Spread & Mustard',
                role: 'Flavor seasoning',
                weightRatio: 0.04,
                calRatio: 0.08,
                protRatio: 0.03,
                carbsRatio: 0.10,
                fatRatio: 0.20,
                confidence: 0.88,
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),

    // 11. Salad
    _DecompositionTemplate(
      keywords: ['salad', 'salads', 'greens bowl'],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 160.0;
        final totalProt = food.protein > 0 ? food.protein : 6.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 16.0;
        final totalFat = food.fat > 0 ? food.fat : 8.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 240.0;

        return [
              _IngredientFormula(
                name: 'Crisp Mixed Greens & Lettuce',
                role: 'Fresh greens',
                weightRatio: 0.55,
                calRatio: 0.22,
                protRatio: 0.35,
                carbsRatio: 0.45,
                fatRatio: 0.05,
                fiberRatio: 0.60,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Cherry Tomatoes & Cucumbers',
                role: 'Fresh greens',
                weightRatio: 0.25,
                calRatio: 0.16,
                protRatio: 0.15,
                carbsRatio: 0.35,
                fatRatio: 0.05,
                fiberRatio: 0.35,
                confidence: 0.93,
              ),
              _IngredientFormula(
                name: 'Extra Virgin Olive Oil Dressing',
                role: 'Cooking fat',
                weightRatio: 0.12,
                calRatio: 0.48,
                protRatio: 0.0,
                carbsRatio: 0.05,
                fatRatio: 0.85,
                confidence: 0.91,
                unit: 'ml',
              ),
              _IngredientFormula(
                name: 'Toasted Seeds & Seasoning',
                role: 'Texture crunch',
                weightRatio: 0.08,
                calRatio: 0.14,
                protRatio: 0.50,
                carbsRatio: 0.15,
                fatRatio: 0.05,
                confidence: 0.88,
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),

    // 12. Spaghetti / Pasta
    _DecompositionTemplate(
      keywords: ['spaghetti', 'pasta', 'bolognese', 'carbonara'],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 380.0;
        final totalProt = food.protein > 0 ? food.protein : 16.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 60.0;
        final totalFat = food.fat > 0 ? food.fat : 10.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 320.0;

        return [
              _IngredientFormula(
                name: 'Al Dente Spaghetti Pasta',
                role: 'Noodle base',
                weightRatio: 0.52,
                calRatio: 0.52,
                protRatio: 0.25,
                carbsRatio: 0.85,
                fatRatio: 0.08,
                confidence: 0.95,
              ),
              _IngredientFormula(
                name: 'Savory Tomato Meat Sauce',
                role: 'Protein sauce',
                weightRatio: 0.36,
                calRatio: 0.34,
                protRatio: 0.60,
                carbsRatio: 0.10,
                fatRatio: 0.65,
                confidence: 0.93,
              ),
              _IngredientFormula(
                name: 'Grated Parmesan Cheese',
                role: 'Dairy seasoning',
                weightRatio: 0.06,
                calRatio: 0.06,
                protRatio: 0.12,
                carbsRatio: 0.02,
                fatRatio: 0.15,
                confidence: 0.90,
              ),
              _IngredientFormula(
                name: 'Olive Oil & Italian Herbs',
                role: 'Flavor seasoning',
                weightRatio: 0.06,
                calRatio: 0.08,
                protRatio: 0.03,
                carbsRatio: 0.03,
                fatRatio: 0.12,
                confidence: 0.88,
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),

    // 13. Milk Tea / Boba
    _DecompositionTemplate(
      keywords: [
        'milk tea',
        'bubble tea',
        'boba tea',
        'pearl milk tea',
        'matcha tea',
        'green tea latte',
      ],
      builder: (food) {
        final totalCals = food.calories > 0 ? food.calories : 280.0;
        final totalProt = food.protein > 0 ? food.protein : 4.0;
        final totalCarbs = food.carbs > 0 ? food.carbs : 52.0;
        final totalFat = food.fat > 0 ? food.fat : 7.0;
        final totalWeight = food.servingSize > 50 ? food.servingSize : 450.0;
        final isMatcha = food.name.toLowerCase().contains('matcha');

        return [
              _IngredientFormula(
                name: isMatcha ? 'Matcha Green Tea Base' : 'Brewed Black Tea',
                role: 'Liquid base',
                weightRatio: 0.55,
                calRatio: 0.06,
                protRatio: 0.10,
                carbsRatio: 0.04,
                fatRatio: 0.02,
                confidence: 0.95,
                unit: 'ml',
              ),
              _IngredientFormula(
                name: 'Fresh Dairy Milk / Creamer',
                role: 'Creamy base',
                weightRatio: 0.25,
                calRatio: 0.36,
                protRatio: 0.80,
                carbsRatio: 0.18,
                fatRatio: 0.90,
                confidence: 0.92,
                unit: 'ml',
              ),
              _IngredientFormula(
                name: 'Tapioca Pearls (Boba)',
                role: 'Boba topping',
                weightRatio: 0.14,
                calRatio: 0.38,
                protRatio: 0.05,
                carbsRatio: 0.50,
                fatRatio: 0.05,
                confidence: 0.94,
              ),
              _IngredientFormula(
                name: 'Brown Sugar Cane Syrup',
                role: 'Added sugar',
                weightRatio: 0.06,
                calRatio: 0.20,
                protRatio: 0.05,
                carbsRatio: 0.28,
                fatRatio: 0.03,
                confidence: 0.91,
                unit: 'ml',
              ),
            ]
            .map(
              (f) => f.toState(
                food,
                totalWeight,
                totalCals,
                totalProt,
                totalCarbs,
                totalFat,
              ),
            )
            .toList();
      },
    ),
  ];
}

class _DecompositionTemplate {
  final List<String> keywords;
  final List<PlateItemState> Function(FoodNutritionModel) builder;

  const _DecompositionTemplate({required this.keywords, required this.builder});

  bool matches(String text) {
    for (final kw in keywords) {
      if (text.contains(kw)) return true;
    }
    return false;
  }

  List<PlateItemState> buildItems(FoodNutritionModel food) => builder(food);
}

class _IngredientFormula {
  final String name;
  final String role;
  final double weightRatio;
  final double calRatio;
  final double protRatio;
  final double carbsRatio;
  final double fatRatio;
  final double fiberRatio;
  final double sodiumRatio;
  final double confidence;
  final String unit;

  const _IngredientFormula({
    required this.name,
    required this.role,
    required this.weightRatio,
    required this.calRatio,
    required this.protRatio,
    required this.carbsRatio,
    required this.fatRatio,
    this.fiberRatio = 0.0,
    this.sodiumRatio = 0.0,
    required this.confidence,
    this.unit = 'g',
  });

  PlateItemState toState(
    FoodNutritionModel food,
    double totalWeight,
    double totalCals,
    double totalProt,
    double totalCarbs,
    double totalFat,
  ) {
    final visual = IngredientVisualService.resolve(name, customRole: role);
    final weight = (totalWeight * weightRatio).roundToDouble();

    return PlateItemState(
      id: 'dec_${name.hashCode}_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      baseCalories: (totalCals * calRatio).roundToDouble(),
      baseProtein: (totalProt * protRatio * 10).round() / 10,
      baseCarbs: (totalCarbs * carbsRatio * 10).round() / 10,
      baseFat: (totalFat * fatRatio * 10).round() / 10,
      baseFiber: (food.fiber * fiberRatio * 10).round() / 10,
      baseSodium: (food.sodium * sodiumRatio).roundToDouble(),
      baseServingSize: weight > 0 ? weight : 50,
      unit: unit,
      portionMultiplier: 1.0,
      isSelected: true,
      confidence: confidence,
      role: role,
      imageUrl: visual.imageUrl,
    );
  }
}
