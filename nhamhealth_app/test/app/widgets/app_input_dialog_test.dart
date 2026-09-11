import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/app/widgets/app_input_dialog.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('AppInputDialog displays correctly and submits entered text', (
    tester,
  ) async {
    String? submittedValue;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  submittedValue = await AppInputDialog.show(
                    context: context,
                    title: 'Edit Full Name',
                    subtitle: 'Enter your full name for your profile.',
                    initialValue: 'John Doe',
                    labelText: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    prefixIcon: Icons.person_outline_rounded,
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Full Name'), findsOneWidget);
    expect(find.text('Enter your full name for your profile.'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsWidgets);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // Modify text
    await tester.enterText(find.byType(TextField), 'Jane Smith');
    await tester.pump();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(submittedValue, 'Jane Smith');
    expect(find.text('Edit Full Name'), findsNothing);
  });

  testWidgets('AppInputDialog shows inline validation error on invalid input', (
    tester,
  ) async {
    String? submittedValue;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  submittedValue = await AppInputDialog.show(
                    context: context,
                    title: 'Height',
                    initialValue: '170',
                    validator: (val) {
                      final n = double.tryParse(val);
                      if (n == null || n < 50 || n > 300) {
                        return 'Enter a height between 50 and 300 cm.';
                      }
                      return null;
                    },
                  );
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Enter invalid number
    await tester.enterText(find.byType(TextField), '20');
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pump();

    // Should display validation error and stay open
    expect(find.text('Enter a height between 50 and 300 cm.'), findsOneWidget);
    expect(submittedValue, isNull);

    // Cancel dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Height'), findsNothing);
  });
}
