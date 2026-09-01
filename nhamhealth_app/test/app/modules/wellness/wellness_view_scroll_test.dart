import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/wellness_controller.dart';
import 'package:nhamhealth_flutter/app/modules/views/wellness/wellness_view.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('Daily Wellness scrolls as one page on a short phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 600);
    addTearDown(tester.view.reset);
    Get.put<WellnessController>(WellnessController());

    await tester.pumpWidget(const GetMaterialApp(home: WellnessView()));
    await tester.pump(const Duration(milliseconds: 100));

    final scroll = find.byKey(const ValueKey<String>('wellness-page-scroll'));
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: scroll, matching: find.byType(Scrollable)),
    );
    expect(scrollable.position.pixels, 0);

    await tester.drag(scroll, const Offset(0, -280));
    await tester.pump(const Duration(milliseconds: 400));

    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Daily Wellness remains pull-scrollable with short content', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 1200);
    addTearDown(tester.view.reset);
    Get.put<WellnessController>(WellnessController());

    await tester.pumpWidget(const GetMaterialApp(home: WellnessView()));
    await tester.pump(const Duration(milliseconds: 100));

    final scrollable = tester.widget<CustomScrollView>(
      find.byKey(const ValueKey<String>('wellness-page-scroll')),
    );
    expect(scrollable.physics, isA<AlwaysScrollableScrollPhysics>());
    expect(tester.takeException(), isNull);
  });
}
