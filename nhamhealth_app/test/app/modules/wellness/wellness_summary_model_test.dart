import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/models/wellness/wellness_summary_model.dart';

void main() {
  test('progress is clamped to the range accepted by progress indicators', () {
    const overTarget = WellnessSummaryModel(
      name: 'Sugar',
      current: '60',
      target: '50',
      unit: 'g',
      percentage: 120,
      icon: Icons.hexagon,
      color: Colors.pink,
      isLimit: true,
    );

    expect(overTarget.progress, 1);
    expect(overTarget.isLimit, isTrue);
  });
}
