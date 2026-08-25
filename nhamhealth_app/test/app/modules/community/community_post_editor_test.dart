import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_tag.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_post_editor_page.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post_draft.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    final authService = _ComposerAuthService();
    Get.put<CommunityRepository>(_ComposerRepository(authService));
  });

  tearDown(Get.reset);

  testWidgets('new post composer has no title and submits the message', (
    tester,
  ) async {
    CommunityPostDraft? submitted;
    await tester.pumpWidget(
      GetMaterialApp(
        home: CommunityPostEditorPage(
          authorName: 'Nham Member',
          authorAvatarUrl: '',
          onSubmit: (draft) async => submitted = draft,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Title (optional)'), findsNothing);
    expect(find.text('Add to your post'), findsOneWidget);
    expect(find.text('Post settings'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('community-post-message')),
      'Today I prepared a healthy lunch.',
    );
    await tester.tap(find.text('Publish'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.description, 'Today I prepared a healthy lunch.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing submits the existing message', (tester) async {
    CommunityPostDraft? submitted;
    await tester.pumpWidget(
      GetMaterialApp(
        home: CommunityPostEditorPage(
          post: CommunityPost(
            id: '7',
            description: 'Original message',
            imageUrl: '',
            author: 'Nham Member',
            role: 'Member',
          ),
          authorName: 'Nham Member',
          authorAvatarUrl: '',
          onSubmit: (draft) async => submitted = draft,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.description, 'Original message');
    expect(tester.takeException(), isNull);
  });
}

class _ComposerRepository extends CommunityRepository {
  _ComposerRepository(AuthService authService)
    : super(authService: authService);

  @override
  Future<List<CommunityTag>> getTags() async => const [];
}

class _ComposerAuthService extends AuthService {}
