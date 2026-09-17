import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../../models/community/community_post.dart';
import '../../models/community/community_post_draft.dart';
import '../../repositories/community/community_repository.dart';

class CommunityPostDetailController extends GetxController {
  CommunityPostDetailController({
    required String postId,
    required CommunityRepository repository,
    required AuthService authService,
    CommunityPost? initialPost,
  }) : _postId = postId.trim(),
       _repository = repository,
       _authService = authService {
    post.value = initialPost;
  }

  final String _postId;
  final CommunityRepository _repository;
  final AuthService _authService;

  final post = Rxn<CommunityPost>();
  final user = Rxn<AuthenticatedUser>();
  final isLoading = false.obs;
  final errorMessage = RxnString();

  bool get canEdit {
    final currentPost = post.value;
    final currentUser = user.value;
    return currentPost != null &&
        currentUser != null &&
        currentPost.authorId == currentUser.id;
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  Future<void> load() async {
    if (isLoading.value) return;
    final parsedPostId = int.tryParse(_postId);
    if (parsedPostId == null || parsedPostId <= 0) {
      post.value = null;
      errorMessage.value = 'This community post link is invalid.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    final session = _authService.restoreSession();
    try {
      // Publish the post as soon as it is available so notification taps can
      // show the comments page without waiting for session restoration.
      post.value ??= await _repository.getPost(_postId);
    } on Object catch (error) {
      post.value = null;
      errorMessage.value = error.toString();
      isLoading.value = false;
      return;
    }

    try {
      user.value = await session;
    } on Object {
      // Reading the discussion does not require profile ownership metadata.
      user.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<CommunityPost> updatePost(CommunityPostDraft draft) async {
    final current = post.value;
    if (current == null || !canEdit) {
      throw const CommunityException('You cannot edit this post.');
    }
    final updated = await _repository.updatePost(
      postId: current.id,
      mealName: draft.mealName,
      description: draft.description,
      cookingTimeMinutes: draft.cookingTimeMinutes,
      servings: draft.servings,
      difficulty: draft.difficulty,
      ingredients: draft.ingredients,
      steps: draft.steps,
      imageBytes: draft.imageBytes,
      visibility: draft.visibility,
      allowComments: draft.allowComments,
      allowReplies: draft.allowReplies,
      removeImage: draft.removeImage,
      tagIds: draft.tagIds,
      categoryId: draft.categoryId,
    );
    post.value = updated;
    return updated;
  }
}
