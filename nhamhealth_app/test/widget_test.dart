<<<<<<< HEAD
import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/main.dart';
import 'package:nhamhealth_flutter/models/api_health.dart';
import 'package:nhamhealth_flutter/services/health_api.dart';

void main() {
  testWidgets('shows a successful API connection', (tester) async {
    await tester.pumpWidget(NhamHealthApp(api: _FakeHealthApi()));
    await tester.pumpAndSettle();

    expect(find.text('Connected to Spring API'), findsOneWidget);
    expect(find.text('Status: UP'), findsOneWidget);
    expect(find.text('Service: nhamhealth-api'), findsOneWidget);
  });
}

class _FakeHealthApi implements HealthApi {
  @override
  String get baseUrl => 'http://localhost:8080';

  @override
  Future<ApiHealth> getHealth() async {
    return ApiHealth(
      status: 'UP',
      service: 'nhamhealth-api',
      timestamp: DateTime.utc(2026, 7, 23),
    );
  }
}
=======
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nhamhealth_flutter/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
>>>>>>> 304f44ac267fdc5fbf67c1fa9366cff48e153fd7
