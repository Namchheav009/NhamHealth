import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/profile/help_support_controller.dart';
import 'package:nhamhealth_flutter/app/modules/views/profile/help_support_view.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('help and support uses dark surfaces and expands FAQs', (
    tester,
  ) async {
    Get.put(HelpSupportController());

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark, home: const HelpSupportView()),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppTheme.dark.scaffoldBackgroundColor);

    final contactCard = tester.widget<Container>(
      find.byKey(const ValueKey<String>('help-contact-card')),
    );
    final contactDecoration = contactCard.decoration! as BoxDecoration;
    expect(contactDecoration.color, isNot(Colors.white));

    final firstFaq = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey<String>('help-faq-0')),
    );
    final faqDecoration = firstFaq.decoration! as BoxDecoration;
    expect(faqDecoration.color, isNot(Colors.white));

    await tester.tap(find.text('How do I Change my password?'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Go to Settings > Password & Security'),
      findsOneWidget,
    );
  });
}
