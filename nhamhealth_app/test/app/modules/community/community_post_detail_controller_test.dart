import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/community/community_post_detail_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/auth/authenticated_user_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post.dart';
import 'package:nhamhealth_flutter/app/modules/models/community/community_post_draft.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/community/community_repository.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

void main() {
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
        ),
      );

      expect(updated.description, 'Updated post');
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
    required String description,
    List<Uint8List> imageBytes = const [],
    CommunityPostVisibility visibility = CommunityPostVisibility.public,
    bool allowComments = true,
    bool allowReplies = true,
    bool removeImage = false,
    List<int> tagIds = const [],
  }) async => CommunityPost(
    id: postId,
    description: description,
    imageUrl: '',
    author: 'Post owner',
    role: 'Member',
    authorId: 7,
    visibility: visibility,
    allowComments: allowComments,
    allowReplies: allowReplies,
  );
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
