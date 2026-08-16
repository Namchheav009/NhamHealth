import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/profile/models/profile_dashboard_model.dart';

void main() {
  test('parses all daily nutrient progress values', () {
    final dashboard = ProfileDashboardModel.fromJson({
      'userId': 7,
      'email': 'user@example.com',
      'fiber': {'current': 18.5, 'goal': 25},
      'sugar': {'current': 21, 'goal': 50},
    });

    expect(dashboard.fiber?.current, 18.5);
    expect(dashboard.fiber?.goal, 25);
    expect(dashboard.sugar?.current, 21);
    expect(dashboard.sugar?.goal, 50);
  });
}
