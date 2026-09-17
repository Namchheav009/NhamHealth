import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/community/community_post_detail_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post_draft.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/app/modules/views/community/community_post_detail_page.dart';
import 'package:nhamhealth_flutter/app/translations/app_translations.dart';
import 'package:nhamhealth_flutter/app/widgets/app_back_header.dart';
import 'package:nhamhealth_flutter/app/widgets/app_background.dart';
import 'package:nhamhealth_flutter/app/widgets/page_skeleton.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('loading state uses the shared community page chrome', (
    tester,
  ) async {
    Get.testMode = true;
    final auth = _DetailAuthService();
    final repository = _PendingDetailRepository(auth);
    Get.put<CommunityRepository>(repository);
    Get.put(
      CommunityPostDetailController(
        postId: '42',
        repository: repository,
        authService: auth,
      ),
    );

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const CommunityPostDetailPage(),
      ),
    );
    await tester.pump();

    expect(find.byType(AppBackground), findsOneWidget);
    expect(find.byType(AppBackHeader), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('community-post-back-button')),
      findsOneWidget,
    );
    expect(find.text('Community post'), findsOneWidget);
    expect(find.byType(PageSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'loads an owned post and updates it without closing the detail flow',
    () async {
      final auth = _DetailAuthService();
      final repository = _DetailRepository(auth);
      final controller = CommunityPostDetailController(
        postId: '42',
        repository: repository,
        authService: auth,
      );

      await controller.load();

      expect(controller.post.value?.id, '42');
      expect(controller.canEdit, isTrue);
      expect(controller.errorMessage.value, isNull);

      final updated = await controller.updatePost(
        const CommunityPostDraft(
          description: 'Updated post',
          imageBytes: [],
          removeImage: false,
          visibility: CommunityPostVisibility.public,
          allowComments: true,
          allowReplies: true,
          tagIds: [],
          categoryId: 3,
        ),
      );

      expect(updated.description, 'Updated post');
      expect(updated.categoryId, 3);
      expect(controller.post.value?.description, 'Updated post');
    },
  );

  test('rejects an invalid deep link before calling the repository', () async {
    final auth = _DetailAuthService();
    final repository = _DetailRepository(auth);
    final controller = CommunityPostDetailController(
      postId: 'not-a-post',
      repository: repository,
      authService: auth,
    );

    await controller.load();

    expect(repository.getPostCalls, 0);
    expect(controller.post.value, isNull);
    expect(controller.errorMessage.value, contains('invalid'));
  });

  test(
    'publishes the post before slow session restoration completes',
    () async {
      final auth = _SlowDetailAuthService();
      final repository = _DetailRepository(auth);
      final controller = CommunityPostDetailController(
        postId: '42',
        repository: repository,
        authService: auth,
      );

      final loading = controller.load();
      await Future<void>.delayed(Duration.zero);

      expect(controller.post.value?.id, '42');
      expect(controller.isLoading.value, isTrue);

      auth.complete();
      await loading;
      expect(controller.isLoading.value, isFalse);
    },
  );

  test('uses a preloaded notification post without fetching again', () async {
    final auth = _DetailAuthService();
    final repository = _DetailRepository(auth);
    final controller = CommunityPostDetailController(
      postId: '42',
      repository: repository,
      authService: auth,
      initialPost: CommunityPost(
        id: '42',
        description: 'Preloaded notification post',
        imageUrl: '',
        author: 'Post owner',
        role: 'Member',
      ),
    );

    await controller.load();

    expect(controller.post.value?.description, 'Preloaded notification post');
    expect(repository.getPostCalls, 0);
  });
}

class _DetailRepository extends CommunityRepository {
  _DetailRepository(AuthService authService) : super(authService: authService);

  int getPostCalls = 0;

  @override
  Future<CommunityPost> getPost(String postId) async {
    getPostCalls += 1;
    return CommunityPost(
      id: postId,
      description: 'Original post',
      imageUrl: '',
      author: 'Post owner',
      role: 'Member',
      authorId: 7,
    );
  }

  @override
  Future<CommunityPost> updatePost({
    required String postId,
    required String mealName,
    required String description,
    required int cookingTimeMinutes,
    required int servings,
    required String difficulty,
    required List<MealPostIngredient> ingredients,
    required List<MealPostStep> steps,
    List<Uint8List> imageBytes = const [],
    CommunityPostVisibility visibility = CommunityPostVisibility.public,
    bool allowComments = true,
    bool allowReplies = true,
    bool removeImage = false,
    List<int> tagIds = const [],
    int? categoryId,
  }) async => CommunityPost(
    id: postId,
    description: description,
    imageUrl: '',
    author: 'Post owner',
    role: 'Member',
    authorId: 7,
    mealName: mealName,
    cookingTimeMinutes: cookingTimeMinutes,
    servings: servings,
    difficulty: difficulty,
    categoryId: categoryId,
    ingredients: ingredients,
    steps: steps,
    visibility: visibility,
    allowComments: allowComments,
    allowReplies: allowReplies,
  );
}

class _PendingDetailRepository extends _DetailRepository {
  _PendingDetailRepository(super.authService);

  final _post = Completer<CommunityPost>();

  @override
  Future<CommunityPost> getPost(String postId) => _post.future;
}

class _DetailAuthService extends AuthService {
  @override
  Future<AuthenticatedUser?> restoreSession() async => const AuthenticatedUser(
    id: 7,
    email: 'owner@example.com',
    role: 'USER',
    fullName: 'Post owner',
  );
}

class _SlowDetailAuthService extends AuthService {
  final _session = Completer<AuthenticatedUser?>();

  @override
  Future<AuthenticatedUser?> restoreSession() => _session.future;

  void complete() => _session.complete(null);
}
