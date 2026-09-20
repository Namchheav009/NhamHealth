import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/views/auth/widgets/auth_flow_scaffold.dart';
import 'package:nhamhealth_flutter/app/modules/views/auth/widgets/auth_scaffold.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  group('AuthScaffold tablet responsiveness', () {
    testWidgets('renders two-column split layout on tablet in landscape', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const AuthScaffold(
            child: Text('Login Form Content'),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('auth-tablet-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('auth-tablet-portrait-layout')),
        findsNothing,
      );
      expect(find.text('Login Form Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders floating card layout on tablet in portrait', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1280);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const AuthScaffold(
            child: Text('Login Form Content'),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('auth-tablet-layout')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('auth-tablet-portrait-layout')),
        findsOneWidget,
      );
      expect(find.text('Login Form Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders phone bottom sheet layout on mobile phone', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const AuthScaffold(
            child: Text('Login Form Content'),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('auth-tablet-layout')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('auth-tablet-portrait-layout')),
        findsNothing,
      );
      expect(find.text('Login Form Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AuthFlowScaffold tablet responsiveness', () {
    testWidgets('renders AuthFlowScaffold on tablet landscape', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const AuthFlowScaffold(
            title: 'Forgot Password',
            subtitle: 'Enter your email to recover your account',
            illustrationAsset: 'assets/images/auth/illustration.png',
            child: Text('Flow Form Content'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('Flow Form Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders AuthFlowScaffold on tablet portrait', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1280);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const AuthFlowScaffold(
            title: 'Forgot Password',
            subtitle: 'Enter your email to recover your account',
            illustrationAsset: 'assets/images/auth/illustration.png',
            child: Text('Flow Form Content'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('Flow Form Content'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

