import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/main.dart';
import 'package:nhamhealth_flutter/models/api_health.dart';
import 'package:nhamhealth_flutter/core/services/health_api.dart';

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
