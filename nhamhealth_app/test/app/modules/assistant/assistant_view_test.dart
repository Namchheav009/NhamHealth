import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/assistant/assistant_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/assistant/assistant_message.dart';
import 'package:nhamhealth_flutter/app/modules/providers/assistant/assistant_provider.dart';
import 'package:nhamhealth_flutter/app/modules/views/assistant/assistant_view.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put(
      AssistantController(
        provider: AssistantProvider(authService: AuthService()),
      ),
    );
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('quick questions render without a GetX scope error', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: AssistantView()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Quick questions'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-question-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all questions remain available in the question sheet', (
    tester,
  ) async {
    await tester.pumpWidget(const GetMaterialApp(home: AssistantView()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const ValueKey('assistant-all-questions')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ask NhamHealth AI'), findsOneWidget);
    expect(find.text('How is my wellness progress today?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assistant reply formats bullets and numbered steps', (
    tester,
  ) async {
    Get.find<AssistantController>().messages.assignAll(const [
      AssistantMessage(
        role: 'assistant',
        content:
            'Today:\n- Calories: **3880 / 2000 kcal**\n- Protein: 220 / 120 g\n1. Drink one glass of water.',
      ),
    ]);

    await tester.pumpWidget(const GetMaterialApp(home: AssistantView()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey('assistant-reply-structured')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('assistant-reply-bullet-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('assistant-reply-bullet-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('assistant-reply-numbered-3')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
