import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/main.dart';
import 'package:nhamhealth_flutter/app/modules/views/splash/splash_view.dart';

void main() {
  testWidgets('shows the splash screen on launch', (tester) async {
    await tester.pumpWidget(const NhamHealthApp());

    expect(find.byType(SplashView), findsOneWidget);
  });
}
