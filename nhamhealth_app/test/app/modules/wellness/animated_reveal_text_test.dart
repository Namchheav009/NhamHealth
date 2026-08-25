import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/widgets/animated_reveal_text.dart';

void main() {
  testWidgets('reveals text and keeps the final layout size stable', (
    tester,
  ) async {
    const message = 'Here is your nutrition recommendation.';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedRevealText(
            text: message,
            duration: Duration(milliseconds: 600),
          ),
        ),
      ),
    );

    final initialSize = tester.getSize(find.byType(AnimatedRevealText));
    expect(
      tester.widgetList<Text>(find.byType(Text)).any((text) => text.data == ''),
      isTrue,
    );

    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(AnimatedRevealText)), initialSize);
    expect(find.text(message), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows complete text immediately when animations are disabled', (
    tester,
  ) async {
    const message = 'Animation-free recommendation.';
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AnimatedRevealText(text: message),
        ),
      ),
    );

    expect(find.text(message), findsOneWidget);
    expect(find.byType(Opacity), findsNothing);
  });
}
