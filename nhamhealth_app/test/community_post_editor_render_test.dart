import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_post_editor_page.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post_draft.dart';
import 'package:nhamhealth_flutter/app/theme/app_theme.dart';

void main() {
  testWidgets('community post editor renders its basic information step', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: CommunityPostEditorPage(
          authorName: 'Test user',
          authorAvatarUrl: '',
          onSubmit: (CommunityPostDraft _) async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('New meal'), findsOneWidget);
    expect(find.text('Add a cover photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
