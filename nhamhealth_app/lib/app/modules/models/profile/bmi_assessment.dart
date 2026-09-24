class BmiAssessment {
  const BmiAssessment._();

  static const double minimumHeightCm = 50;
  static const double maximumHeightCm = 300;
  static const double minimumWeightKg = 15;
  static const double maximumWeightKg = 500;

  static bool hasValidMeasurements({
    required double heightCm,
    required double weightKg,
  }) =>
      heightCm >= minimumHeightCm &&
      heightCm <= maximumHeightCm &&
      weightKg >= minimumWeightKg &&
      weightKg <= maximumWeightKg;

  static double calculate({
    required double heightCm,
    required double weightKg,
  }) {
    if (!hasValidMeasurements(heightCm: heightCm, weightKg: weightKg)) {
      return 0;
    }
    final heightMeters = heightCm / 100;
    return weightKg / (heightMeters * heightMeters);
  }

  static double rounded({required double heightCm, required double weightKg}) =>
      double.parse(
        calculate(heightCm: heightCm, weightKg: weightKg).toStringAsFixed(1),
      );

  static String statusKey({
    required int age,
    required double heightCm,
    required double weightKg,
  }) {
    final value = calculate(heightCm: heightCm, weightKg: weightKg);
    if (age <= 0 || value <= 0) return 'profile.not_set';
    if (age < 18) return 'profile.bmi_under_18';
    if (value < 18.5) return 'profile.bmi_underweight_range';
    if (value < 25) return 'profile.bmi_healthy_range';
    if (value < 30) return 'profile.bmi_overweight_range';
    return 'profile.bmi_obesity_range';
  }

  static String guidanceKey({required int age, required double bmi}) {
    if (age < 18) return 'bmi.guidance_under_18';
    if (bmi < 18.5) return 'bmi.guidance_underweight';
    if (bmi < 25) return 'bmi.guidance_healthy';
    if (bmi < 30) return 'bmi.guidance_overweight';
    return 'bmi.guidance_obesity';
  }

  static List<String> nutritionFocusKeys({
    required int age,
    required double bmi,
  }) {
    if (age < 18) {
      return const [
        'bmi.focus_balanced_meals',
        'bmi.focus_regular_meals',
        'bmi.focus_growth_support',
        'bmi.focus_professional_guidance',
      ];
    }
    if (bmi < 18.5) {
      return const [
        'bmi.focus_balanced_meals',
        'bmi.focus_adequate_nutrition',
        'bmi.focus_regular_meals',
        'bmi.focus_nutrient_rich_foods',
      ];
    }
    if (bmi < 25) {
      return const [
        'bmi.focus_balanced_meals',
        'bmi.focus_regular_activity',
        'bmi.focus_hydration',
        'bmi.focus_sleep',
      ];
    }
    return const [
      'bmi.focus_balanced_meals',
      'bmi.focus_appropriate_portions',
      'bmi.focus_regular_activity',
      'bmi.focus_sustainable_habits',
    ];
  }
}
