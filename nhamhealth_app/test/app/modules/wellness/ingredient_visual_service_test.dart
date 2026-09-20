import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/ingredient_visual_service.dart';

void main() {
  group('IngredientVisualService', () {
    test('uses a verified food photo for pork', () {
      final visual = IngredientVisualService.resolve('Grilled pork');

      expect(visual.imageUrl, contains('photo-1544025162-d76694265947'));
      expect(visual.defaultRole, 'Protein source');
    });

    test('prefers a precise fallback over an unrelated herb photo', () {
      final visual = IngredientVisualService.resolve('Cilantro');

      expect(visual.imageUrl, isNull);
      expect(visual.fallbackIcon, Icons.grass_rounded);
      expect(visual.defaultRole, 'Fresh herb');
    });

    test('unknown drinks receive a drink visual instead of a food photo', () {
      final visual = IngredientVisualService.resolve(
        'House beverage',
        componentType: 'drink',
      );

      expect(visual.imageUrl, isNull);
      expect(visual.fallbackIcon, Icons.local_drink_rounded);
      expect(visual.defaultRole, 'Drink');
    });
  });
}
