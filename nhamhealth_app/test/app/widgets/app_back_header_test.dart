import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/widgets/app_back_header.dart';

void main() {
  testWidgets('shared back button has one consistent size and action', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: AppBackButton(
            buttonKey: const ValueKey<String>('shared-back-button'),
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    final button = find.byKey(const ValueKey<String>('shared-back-button'));
    expect(
      tester.getSize(find.byType(AppBackButton)),
      const Size.square(AppBackButton.layoutSize),
    );
    expect(tester.getSize(button), const Size.square(AppBackButton.visualSize));
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    await tester.tap(button);
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back header uses the shared back button', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: AppBackHeader(title: 'Profile', onBack: () {})),
      ),
    );

    expect(find.byType(AppBackButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
