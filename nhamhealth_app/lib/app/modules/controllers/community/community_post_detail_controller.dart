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
    final fallbackPost = current.sharedPost;
    final effectiveMealName = draft.mealName.trim().isNotEmpty
        ? draft.mealName.trim()
        : (current.mealName.trim().isNotEmpty
            ? current.mealName.trim()
            : (fallbackPost?.mealName.trim().isNotEmpty == true
                ? fallbackPost!.mealName.trim()
                : 'Shared Post'));
    final effectiveCookingTime = draft.cookingTimeMinutes > 0
        ? draft.cookingTimeMinutes
        : ((current.cookingTimeMinutes != null && current.cookingTimeMinutes! > 0)
            ? current.cookingTimeMinutes!
            : (fallbackPost?.cookingTimeMinutes != null &&
                    fallbackPost!.cookingTimeMinutes! > 0
                ? fallbackPost.cookingTimeMinutes!
                : 1));
    final effectiveServings = draft.servings > 0
        ? draft.servings
        : ((current.servings != null && current.servings! > 0)
            ? current.servings!
            : (fallbackPost?.servings != null && fallbackPost!.servings! > 0
                ? fallbackPost.servings!
                : 1));
    final effectiveDifficulty = draft.difficulty.trim().isNotEmpty
        ? draft.difficulty.trim()
        : (current.difficulty.trim().isNotEmpty
            ? current.difficulty.trim()
            : (fallbackPost?.difficulty.trim().isNotEmpty == true
                ? fallbackPost!.difficulty.trim()
                : 'EASY'));
    final effectiveIngredients = draft.ingredients.isNotEmpty
        ? draft.ingredients
        : (current.ingredients.isNotEmpty
            ? current.ingredients
            : fallbackPost?.ingredients ?? const []);
    final effectiveSteps = draft.steps.isNotEmpty
        ? draft.steps
        : (current.steps.isNotEmpty
            ? current.steps
            : fallbackPost?.steps ?? const []);
    final effectiveCategoryId = draft.categoryId ?? current.categoryId ?? 1;

    final updated = await _repository.updatePost(
      postId: current.id,
      mealName: effectiveMealName,
      description: draft.description,
      cookingTimeMinutes: effectiveCookingTime,
      servings: effectiveServings,
      difficulty: effectiveDifficulty,
      ingredients: effectiveIngredients,
      steps: effectiveSteps,
      imageBytes: draft.imageBytes,
      visibility: draft.visibility,
      allowComments: draft.allowComments,
      allowReplies: draft.allowReplies,
      removeImage: draft.removeImage,
      tagIds: draft.tagIds,
      categoryId: effectiveCategoryId,
    );
    post.value = updated;
    return updated;
  }
}
