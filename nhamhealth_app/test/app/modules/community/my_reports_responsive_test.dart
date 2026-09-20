import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/community/community_report_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_report.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_report_page.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

class _FakeCommunityReportRepository implements CommunityRepository {
  @override
  Future<List<CommunityReport>> getMyReports() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CommunityReportController controller;

  setUp(() {
    Get.testMode = true;
    controller = CommunityReportController(
      repository: _FakeCommunityReportRepository(),
    );
    Get.put<CommunityReportController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  Widget createApp() {
    return GetMaterialApp(
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      home: CommunityMyReportsPage(controller: controller),
    );
  }

  testWidgets('renders tablet landscape layout for My Reports', (
    tester,
  ) async {
    // 1280 x 800 tablet in landscape
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('my-reports-tablet-landscape')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('community-report-back-button')),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'renders centered constrained layout on tablet in portrait mode',
    (tester) async {
      // 800 x 1280 tablet in portrait
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(800, 1280);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('my-reports-tablet-portrait')),
        findsOneWidget,
      );

      final list = find.byKey(
        const ValueKey<String>('my-reports-tablet-portrait'),
      );
      final size = tester.getSize(list);
      expect(size.width, greaterThan(600.0));

      expect(
        find.byKey(const ValueKey<String>('community-report-back-button')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders mobile layout on phone', (tester) async {
    // 390 x 844 mobile phone
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('my-reports-mobile')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('community-report-back-button')),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });
}
