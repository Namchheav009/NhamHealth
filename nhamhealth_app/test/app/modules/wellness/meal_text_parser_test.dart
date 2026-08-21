import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/services/wellness/meal_text_parser.dart';

void main() {
  const parser = MealTextParser();

  test('parses several foods and quantities', () {
    final items = parser.parse(
      'I ate 150 g chicken breast, 1 cup rice and banana',
    );

    expect(items, hasLength(3));
    expect(items.first.searchName, 'chicken breast');
    expect(items.first.amount, 150);
    expect(items.first.unit, 'g');
    expect(items[1].searchName, 'rice');
    expect(items[1].amount, 1);
    expect(items[1].unit, 'cup');
    expect(items[2].searchName, 'banana');
  });

  test('normalizes kilograms to grams', () {
    final item = parser.parse('0.5 kg watermelon').single;
    expect(item.amount, 500);
    expect(item.unit, 'g');
  });

  test('limits a request to twelve foods', () {
    final items = parser.parse(
      List.generate(20, (index) => 'food $index').join(','),
    );
    expect(items, hasLength(12));
  });
}
