import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/main.dart';
import 'package:nhamhealth_flutter/app/modules/views/splash/splash_view.dart';

void main() {
  testWidgets('shows the splash screen on launch', (tester) async {
    await tester.pumpWidget(const NhamHealthApp());

    expect(find.byType(SplashView), findsOneWidget);
  });

  testWidgets('finishes splash navigation outside animation notification', (
    tester,
  ) async {
    await tester.pumpWidget(const NhamHealthApp());

    // Complete the splash animation, then run the post-frame navigation that
    // safely removes its inherited-widget tree.
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
