import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/models/profile/profile_dashboard_model.dart';

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
    expect(dashboard.phoneVerified, isFalse);
  });

  test('parses phoneVerified when true', () {
    final dashboard = ProfileDashboardModel.fromJson({
      'userId': 7,
      'email': 'user@example.com',
      'phone': '012345678',
      'phoneVerified': true,
    });

    expect(dashboard.phone, '012345678');
    expect(dashboard.phoneVerified, isTrue);
  });

  test('parses a phone-only dashboard when email is null', () {
    final dashboard = ProfileDashboardModel.fromJson({
      'userId': 8,
      'email': null,
      'fullName': 'Phone User',
      'phone': '85512345678',
      'phoneVerified': true,
    });

    expect(dashboard.email, isEmpty);
    expect(dashboard.phone, '85512345678');
    expect(dashboard.phoneVerified, isTrue);
  });
}
