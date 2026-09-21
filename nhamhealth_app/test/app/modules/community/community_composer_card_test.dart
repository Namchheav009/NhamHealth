import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/widgets/community_composer_card.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.clearTranslations();
    Get.addTranslations(AppTranslations().keys);
  });
  tearDown(Get.reset);

  testWidgets('CommunityComposerCard renders clean minimal layout and handles callbacks', (
    tester,
  ) async {
    var tappedText = false;
    var tappedPhoto = false;

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: CommunityComposerCard(
            onTap: () => tappedText = true,
            onPhotoTap: () => tappedPhoto = true,
            authorAvatarUrl: '',
          ),
        ),
      ),
    );

    // Verify prompt text exists
    expect(find.text("What's on your healthy mind?"), findsOneWidget);

    // Verify photo icon exists inside the card
    final photoIcon = find.byIcon(Icons.image_outlined);
    expect(photoIcon, findsOneWidget);

    // Verify avatar fallback icon exists
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

    // Tap the photo button
    await tester.tap(photoIcon);
    await tester.pumpAndSettle();
    expect(tappedPhoto, isTrue);
    expect(tappedText, isFalse);

    // Tap the composer prompt text
    await tester.tap(find.text("What's on your healthy mind?"));
    await tester.pumpAndSettle();
    expect(tappedText, isTrue);
  });
}

