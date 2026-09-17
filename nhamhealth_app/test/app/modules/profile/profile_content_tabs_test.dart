import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/profile_view.dart';

void main() {
  testWidgets('ProfileContentTabs renders All and Photos with correct icons and handles taps', (tester) async {
    var selected = 0;

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ProfileContentTabs(
              selectedIndex: selected,
              onChanged: (index) {
                setState(() => selected = index);
              },
            ),
          ),
        ),
      ),
    );

    // Initial state: All tab selected
    expect(find.byKey(const ValueKey<String>('my-profile-tab-all')), findsOneWidget);
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

    expect(find.byKey(const ValueKey<String>('my-profile-tab-photos')), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);

    // Tap Photos tab
    await tester.tap(find.byKey(const ValueKey<String>('my-profile-tab-photos')));
    await tester.pumpAndSettle();

    expect(selected, 1);
  });
}

