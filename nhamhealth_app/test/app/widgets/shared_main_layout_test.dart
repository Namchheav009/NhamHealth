import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/views/assistant/assistant_view.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/assistant/assistant_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/assistant/assistant_message.dart';
import 'package:nhamhealth_flutter/app/routes/app_pages.dart';
import 'package:nhamhealth_flutter/app/modules/bindings/community/community_binding.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_page.dart';
import 'package:nhamhealth_flutter/app/theme/app_spacing.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/app/widgets/app_bottom_navigation.dart';
import 'package:nhamhealth_flutter/app/widgets/page_skeleton.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('shared bottom navigation keeps its dimensions and labels', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 856);
    addTearDown(tester.view.reset);
    var selected = -1;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(25, 0, 25, 14),
            child: AppBottomNavigation(
              selectedIndex: 0,
              onSelect: (index) => selected = index,
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AppBottomNavigation)).height, 84);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Community'), findsOneWidget);
    expect(find.text('Favorites'), findsNothing);
    expect(find.text('Chat'), findsNothing);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('nav-chatbot')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('nav-home')));
    expect(selected, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation item positions stay fixed after selection', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 856);
    addTearDown(tester.view.reset);

    Future<void> pumpBar(int selectedIndex) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            bottomNavigationBar: SafeArea(
              top: false,
              minimum: AppSpacing.navigationMargin,
              child: AppBottomNavigation(
                selectedIndex: selectedIndex,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    const keys = [
      ValueKey<String>('nav-home'),
      ValueKey<String>('nav-meals'),
      ValueKey<String>('nav-community'),
      ValueKey<String>('nav-settings'),
    ];

    await pumpBar(0);
    final initialCenters = [
      for (final key in keys) tester.getCenter(find.byKey(key)),
    ];

    await pumpBar(4);
    final updatedCenters = [
      for (final key in keys) tester.getCenter(find.byKey(key)),
    ];

    expect(updatedCenters, initialCenters);
    expect(tester.getSize(find.byType(AppBottomNavigation)).height, 84);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Community control keeps its size across page text scales', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 856);
    addTearDown(tester.view.reset);

    Future<Size> communitySize({
      required double textScale,
      required int selectedIndex,
    }) async {
      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              bottomNavigationBar: AppBottomNavigation(
                selectedIndex: selectedIndex,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      return tester.getSize(
        find.byKey(const ValueKey<String>('nav-community')),
      );
    }

    final homeSize = await communitySize(textScale: 1.2, selectedIndex: 0);
    final mealsSize = await communitySize(textScale: 1, selectedIndex: 1);
    final selectedCommunitySize = await communitySize(
      textScale: 1.5,
      selectedIndex: 2,
    );

    expect(mealsSize, homeSize);
    expect(selectedCommunitySize, homeSize);
    expect(mealsSize.height, 72);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chatbot stays separate on the right of the four-item bar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 856);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: AppSpacing.navigationMargin,
            child: AppBottomNavigation(selectedIndex: 0, onSelect: (_) {}),
          ),
        ),
      ),
    );

    final chatbot = find.byKey(const ValueKey<String>('nav-chatbot'));
    final settings = find.byKey(const ValueKey<String>('nav-settings'));

    expect(tester.getSize(chatbot), const Size(72, 72));
    expect(
      tester.getCenter(chatbot).dx,
      greaterThan(tester.getCenter(settings).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('chatbot opens the AI assistant page', (tester) async {
    Get.put<AuthService>(AuthService());
    addTearDown(Get.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        getPages: AppPages.pages,
        home: Scaffold(
          bottomNavigationBar: SafeArea(
            child: AppBottomNavigation(selectedIndex: 0, onSelect: (_) {}),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('nav-chatbot')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(AssistantView), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('assistant-suggested-questions')),
      findsOneWidget,
    );

    Get.find<AssistantController>().messages.add(
      const AssistantMessage(role: 'user', content: 'Another question'),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('assistant-suggested-questions')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('community skeleton fits the reference phone width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 856);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: PageSkeleton.community(),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PageSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Community uses the shared bar and loading shell', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(381, 856);
    addTearDown(tester.view.reset);
    Get.put<AuthService>(_CommunityAuthService());

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        initialRoute: '/community',
        getPages: [
          GetPage<void>(
            name: '/community',
            page: () => const CommunityPage(),
            binding: CommunityBinding(),
          ),
          GetPage<void>(
            name: '/home',
            page: () => const Scaffold(body: Text('Home destination')),
          ),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppBottomNavigation), findsOneWidget);
    expect(find.byType(PageSkeleton), findsOneWidget);
    expect(tester.getSize(find.byType(AppBottomNavigation)).height, 84);

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 400));
  });
}

class _CommunityAuthService extends AuthService {
  @override
  Future<AuthenticatedUser?> restoreSession() async => null;

  @override
  Future<String?> readAccessToken() async => null;
}
