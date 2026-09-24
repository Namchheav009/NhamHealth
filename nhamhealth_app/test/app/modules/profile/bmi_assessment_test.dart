import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/models/profile/bmi_assessment.dart';

void main() {
  group('BmiAssessment', () {
    test('calculates BMI from metric measurements', () {
      final bmi = BmiAssessment.calculate(heightCm: 170, weightKg: 65);

      expect(bmi.toStringAsFixed(1), '22.5');
    });

    test('rejects missing or invalid measurements', () {
      expect(BmiAssessment.calculate(heightCm: 0, weightKg: 65), 0);
      expect(BmiAssessment.calculate(heightCm: 170, weightKg: 0), 0);
      expect(BmiAssessment.calculate(heightCm: 49, weightKg: 65), 0);
      expect(BmiAssessment.calculate(heightCm: 170, weightKg: 501), 0);
    });

    test('rounds the displayed result to one decimal place', () {
      expect(BmiAssessment.rounded(heightCm: 170, weightKg: 65), 22.5);
    });

    test('does not apply adult categories below age 18', () {
      expect(
        BmiAssessment.statusKey(age: 17, heightCm: 170, weightKg: 90),
        'profile.bmi_under_18',
      );
    });

    test('classifies all adult BMI ranges', () {
      expect(
        BmiAssessment.statusKey(age: 18, heightCm: 170, weightKg: 50),
        'profile.bmi_underweight_range',
      );
      expect(
        BmiAssessment.statusKey(age: 18, heightCm: 170, weightKg: 65),
        'profile.bmi_healthy_range',
      );
      expect(
        BmiAssessment.statusKey(age: 18, heightCm: 170, weightKg: 75),
        'profile.bmi_overweight_range',
      );
      expect(
        BmiAssessment.statusKey(age: 18, heightCm: 170, weightKg: 90),
        'profile.bmi_obesity_range',
      );
    });

    test('returns neutral nutrition focus for users below 18', () {
      final keys = BmiAssessment.nutritionFocusKeys(age: 15, bmi: 31);

      expect(keys, contains('bmi.focus_growth_support'));
      expect(keys, isNot(contains('bmi.focus_appropriate_portions')));
    });
  });
}
