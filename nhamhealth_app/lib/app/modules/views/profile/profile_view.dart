import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../../config/api_config.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import '../../../widgets/post_delete_confirmation.dart';
import '../../controllers/profile/profile_controller.dart';
import '../../models/community/community_post.dart';
import '../../repositories/community/community_repository.dart';
import '../community/community_comments_page.dart';
import '../community/community_post_editor_page.dart';
import '../community/community_share_actions.dart';
import '../community/widgets/community_composer_card.dart';
import '../community/widgets/post_likers_sheet.dart';
import 'widgets/health_stats_card.dart';
import 'widgets/insight_card.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_post_card.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  double _contentMaxWidth(BuildContext context) {
    final isTablet = AppSpacing.isTabletFor(context);
    if (isTablet) return AppSpacing.maxWideContentWidth;
    return AppSpacing.maxContentWidth;
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppSpacing.pageHorizontalFor(context);
    final maxWidth = _contentMaxWidth(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: context.appBackground,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.pageTop,
                  horizontalPadding,
                  0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: _buildTopBar(),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refreshProfile,
                  color: const Color(0xFF009B3E),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      AppSpacing.pageBottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Obx(() {
                              final message = controller.errorMessage.value;
                              if (message == null) {
                                return const SizedBox.shrink();
                              }
                              return _ProfileErrorBanner(
                                message: message,
                                onRetry: controller.loadProfile,
                              );
                            }),
                            const SizedBox(height: 8),
                            Obx(
                              () => LoadingContentTransition(
                                isLoading:
                                    controller.isLoading.value &&
                                    controller.dashboard.value == null,
                                loading: const PageSkeleton.profile(),
                                content: _profileContent(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return AppBackHeader(
      title: 'profile.title'.tr,
      backButtonKey: const ValueKey('profile-back-button'),
      onBack: controller.goBack,
      trailing: IconButton(
        key: const ValueKey('profile-settings-button'),
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => Get.toNamed<void>(AppRoutes.settings),
        tooltip: 'settings.title'.tr,
      ),
    );
  }

  Widget _profileContent(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 820) {
        return Column(
          children: [
            _profileOverview(),
            const SizedBox(height: 8),
            _profileFeed(context),
          ],
        );
      }

      return Row(
        key: const ValueKey<String>('profile-tablet-layout'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _profileOverview()),
          const SizedBox(width: 20),
          Expanded(child: _profileFeed(context)),
        ],
      );
    },
  );

  Widget _profileOverview() => const Column(
    children: [
      ProfileHeader(),
      SizedBox(height: 8),
      HealthStatsCard(),
      SizedBox(height: 8),
      InsightCard(),
    ],
  );

  Widget _profileFeed(BuildContext context) => Column(
    children: [
      CommunityComposerCard(
        onTap: _showCreatePost,
        onPhotoTap: () => _showCreatePost(pickPhoto: true),
        authorAvatarUrl:
            controller.authenticatedUser.value?.profileImageUrl ?? '',
      ),
      const SizedBox(height: 12),
      Obx(() {
        final selectedIndex = controller.selectedProfileContentTab.value;
        return Column(
          children: [
            ProfileContentTabs(
              selectedIndex: selectedIndex,
              onChanged: (index) {
                if (selectedIndex == index) return;
                controller.selectedProfileContentTab.value = index;
              },
            ),
            const SizedBox(height: 12),
            if (selectedIndex == 1)
              _MyPhotosGrid(
                photos: _profilePhotos,
                onOpen: (photo) => _showProfilePhoto(context, photo),
              )
            else if (controller.posts.isEmpty)
              const _EmptyPosts()
            else
              Column(
                children: controller.posts
                    .map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProfilePostCard(
                          post: post,
                          authorName: controller.name.value,
                          authorAvatarUrl:
                              controller
                                  .authenticatedUser
                                  .value
                                  ?.profileImageUrl ??
                              '',
                          membership: controller.membership.value,
                          onEdit: () => _showEditPost(post),
                          onDelete: () => _confirmDeletePost(post),
                          onFavorite: () => controller.togglePostSaved(post),
                          showFavoriteButton: false,
                          onViewDetails: () => _showComments(post),
                          onLike: () => controller.togglePostLike(post),
                          onShowLikes:
                              () => showPostLikers(
                                context,
                                post: post,
                                repository: Get.find<CommunityRepository>(),
                              ),
                          isLiking: controller.likingPostIds.contains(post.id),
                          onComment: () => _showComments(post),
                          onShare: () => _showShare(post),
                          onSharedPostTap:
                              post.sharedPost != null
                                  ? () =>
                                      _showComments(post.sharedPost!.toPost())
                                  : null,
                          onSharedAuthorTap:
                              (post.sharedPost != null &&
                                      post.sharedPost!.authorId > 0)
                                  ? () => Get.toNamed<void>(
                                    AppRoutes.communityPersonProfilePath(
                                      post.sharedPost!.authorId,
                                    ),
                                    arguments: post.sharedPost!.toPost(),
                                  )
                                  : null,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        );
      }),
    ],
  );

  List<_MyProfilePhoto> get _profilePhotos {
    final seen = <String>{};
    final photos = <_MyProfilePhoto>[];
    for (final post in controller.posts) {
      final urls =
          post.imageUrls.isNotEmpty
              ? post.imageUrls
              : post.imageUrl.isEmpty
              ? const <String>[]
              : <String>[post.imageUrl];
      for (final value in urls) {
        final url = _resolveProfilePhotoUrl(value);
        if (url.isNotEmpty && seen.add(url)) {
          photos.add(_MyProfilePhoto(url: url, post: post));
        }
      }
    }
    return photos;
  }

  String _resolveProfilePhotoUrl(String value) {
    final path = value.trim();
    if (path.isEmpty ||
        path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }
    return '${ApiConfig.baseUrl}${path.startsWith('/') ? '' : '/'}$path';
  }

  Future<void> _showProfilePhoto(BuildContext context, _MyProfilePhoto photo) =>
      showDialog<void>(
        context: context,
        barrierColor: Colors.black,
        builder:
            (dialogContext) => Material(
              color: Colors.black,
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        minScale: .8,
                        maxScale: 4,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: photo.url,
                            fit: BoxFit.contain,
                            errorWidget:
                                (_, _, _) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white70,
                                  size: 52,
                                ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _MyPhotoPostInformation(
                        post: photo.post,
                        authorName: controller.name.value,
                        onOpenPost: () {
                          Navigator.of(dialogContext).pop();
                          _showComments(photo.post);
                        },
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton.filled(
                        tooltip: 'profile.close_image'.tr,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );

  Future<void> _showEditPost(CommunityPost post) async {
    final user = controller.authenticatedUser.value;

    if (post.isShare) {
      await showCommunityShareComposer(
        post: post,
        authorName: user?.displayName ?? post.author,
        authorAvatarUrl: user?.profileImageUrl ?? post.authorAvatarUrl,
        initialMessage: post.description,
        initialVisibility: post.visibility,
        isEditing: true,
        submitButtonText: 'common.save'.tr,
        onShare: (message, visibility) async {
          await controller.updatePost(
            post: post,
            description: message,
            visibility: visibility,
          );
        },
      );
      return;
    }

    await Get.to<void>(
      () => CommunityPostEditorPage(
        post: post,
        authorName: user?.displayName ?? post.author,
        authorAvatarUrl: user?.profileImageUrl ?? post.authorAvatarUrl,
        onSubmit:
            (draft) => controller.updatePost(
              post: post,
              description: draft.description,
              imageBytes: draft.imageBytes,
              visibility: draft.visibility,
              allowComments: draft.allowComments,
              allowReplies: draft.allowReplies,
              removeImage: draft.removeImage,
              tagIds: draft.tagIds,
              categoryId: draft.categoryId,
            ),
      ),
      transition: Transition.rightToLeft,
    );
  }

  // ignore: unused_element
  Future<void> _showLegacyEditPost(CommunityPost post) async {
    final description = TextEditingController(text: post.description);
    await Get.dialog<void>(
      Dialog(
        backgroundColor: Get.context?.appSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_rounded, color: Color(0xFF009B46)),
                  const SizedBox(width: 10),
                  Text(
                    'profile.edit_post'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: description,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: _postInput(
                  Get.context!,
                  'What would you like to share?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: Get.back,
                    child: Text('common.cancel'.tr),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      if (description.text.trim().isEmpty) {
                        Get.snackbar(
                          'profile.add_post_message'.tr,
                          'profile.post_message_required'.tr,
                        );
                        return;
                      }
                      try {
                        await controller.updatePost(
                          post: post,
                          description: description.text,
                        );
                        Get.back<void>();
                        Get.snackbar(
                          'profile.post_updated'.tr,
                          'profile.changes_saved'.tr,
                        );
                      } on Object catch (error) {
                        Get.snackbar(
                          'profile.could_not_update_post'.tr,
                          error.toString(),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF009B46),
                    ),
                    child: Text('common.save_changes'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    description.dispose();
  }

  Future<void> _confirmDeletePost(CommunityPost post) async {
    final confirmed = await confirmPostDeletion(
      messageKey: 'profile.delete_post_warning',
    );
    if (confirmed != true) return;
    try {
      await controller.deletePost(post);
      await AppAlert.actionSuccess(
        title: 'profile.post_deleted',
        message: 'profile.post_removed',
      );
    } on Object catch (error) {
      await AppAlert.actionError(
        title: 'profile.could_not_delete_post',
        message: error.toString(),
      );
    }
  }

  Future<void> _showComments(CommunityPost post) async {
    await Get.to<void>(
      () => CommunityCommentsPage(
        post: post,
        onPostChanged: controller.posts.refresh,
        onShareToFeed:
            (message, visibility) => controller.sharePostToFeed(
              post,
              message: message,
              visibility: visibility,
            ),
        canEdit: true,
        onDeletePost:
            (deletedPost) => controller.posts.removeWhere(
              (item) => item.id == deletedPost.id,
            ),
        onEditPost:
            (draft) => controller.updatePost(
              post: post,
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
            ),
      ),
      transition: Transition.rightToLeft,
    );
  }

  Future<void> _showShare(CommunityPost post) async {
    final canShare =
        post.sharedPost != null ||
        post.visibility == CommunityPostVisibility.public;
    if (!canShare) {
      AppAlert.error(
        title: 'community.cannot_share_post',
        message: 'community.public_posts_only',
      );
      return;
    }
    final user = controller.authenticatedUser.value;
    await showCommunityShareComposer(
      post: post,
      authorName: user?.displayName ?? 'Community member',
      authorAvatarUrl: user?.profileImageUrl ?? '',
      onShare:
          (message, visibility) => controller.sharePostToFeed(
            post,
            message: message,
            visibility: visibility,
          ),
    );
  }

  Future<void> _showCreatePost({bool pickPhoto = false}) async {
    final user = controller.authenticatedUser.value;
    await Get.to<void>(
      () => CommunityPostEditorPage(
        initialPickImage: pickPhoto,
        authorName: user?.displayName ?? 'Community member',
        authorAvatarUrl: user?.profileImageUrl ?? '',
        onSubmit:
            (draft) => controller.addPost(
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
              tagIds: draft.tagIds,
              categoryId: draft.categoryId,
            ),
      ),
      transition: Transition.rightToLeft,
    );
  }

  InputDecoration _postInput(
    BuildContext context,
    String label, {
    bool alignLabelWithHint = false,
  }) => InputDecoration(
    labelText: label,
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: context.appField,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );
}

class ProfileContentTabs extends StatelessWidget {
  const ProfileContentTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: context.appBorder.withValues(alpha: .7)),
      boxShadow: context.appTileShadow,
    ),
    child: Row(
      children: [
        Expanded(
          child: _ProfileTabButton(
            key: const ValueKey<String>('my-profile-tab-all'),
            label: 'common.all'.tr,
            icon: Icons.grid_view_rounded,
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
        ),
        Expanded(
          child: _ProfileTabButton(
            key: const ValueKey<String>('my-profile-tab-photos'),
            label: 'profile.photos'.tr,
            icon: Icons.image_outlined,
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ),
      ],
    ),
  );
}

class _ProfileTabButton extends StatelessWidget {
  const _ProfileTabButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        context.appIsDark
            ? context.appColorScheme.primary
            : const Color(0xFF009B46);
    final activeBg =
        context.appIsDark
            ? context.appSoftGreen.withValues(alpha: .35)
            : const Color(0xFFDFF6E6);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? activeColor : context.appMutedText,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? activeColor : context.appMutedText,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyPhotosGrid extends StatelessWidget {
  const _MyPhotosGrid({required this.photos, required this.onOpen});

  final List<_MyProfilePhoto> photos;
  final ValueChanged<_MyProfilePhoto> onOpen;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 46,
              color: context.appMutedText,
            ),
            const SizedBox(height: 10),
            Text(
              'profile.no_photos_yet'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appMutedText, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder:
          (context, index) => Semantics(
            button: true,
            label: 'profile.open_photo_number'.trParams({
              'number': '${index + 1}',
            }),
            child: Material(
              color: context.appMutedSurface,
              borderRadius: BorderRadius.circular(2),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onOpen(photos[index]),
                child: CachedNetworkImage(
                  imageUrl: photos[index].url,
                  fit: BoxFit.cover,
                  placeholder:
                      (_, _) => ColoredBox(color: context.appMutedSurface),
                  errorWidget:
                      (_, _, _) => Icon(
                        Icons.broken_image_outlined,
                        color: context.appMutedText,
                      ),
                ),
              ),
            ),
          ),
    );
  }
}

class _MyProfilePhoto {
  const _MyProfilePhoto({required this.url, required this.post});

  final String url;
  final CommunityPost post;
}

class _MyPhotoPostInformation extends StatelessWidget {
  const _MyPhotoPostInformation({
    required this.post,
    required this.authorName,
    required this.onOpenPost,
  });

  final CommunityPost post;
  final String authorName;
  final VoidCallback onOpenPost;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontalFor(context),
      14,
      AppSpacing.pageHorizontalFor(context),
      18,
    ),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black.withValues(alpha: .25), Colors.black87],
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: '${'community.view_details'.tr}: $authorName',
          child: InkWell(
            onTap: onOpenPost,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white70,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (post.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            post.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          '${post.ageLabel}   •   ${(post.likes == 1 ? 'community.like_count_one' : 'community.like_count_many').trParams({'count': '${post.likes}'})}   •   ${(post.comments == 1 ? 'community.comment_count_one' : 'community.comment_count_many').trParams({'count': '${post.comments}'})}',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
  );
}

class _EmptyPosts extends StatelessWidget {
  const _EmptyPosts();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.appElevatedSurface.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.appBorder),
    ),
    child: Column(
      children: [
        const Icon(Icons.post_add_outlined, color: Color(0xFF009B46)),
        const SizedBox(height: 8),
        Text('profile.no_shared_posts'.tr),
      ],
    ),
  );
}

class _ProfileErrorBanner extends StatelessWidget {
  const _ProfileErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: context.appDangerSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD84A4A), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message.trOrSelf, style: const TextStyle(fontSize: 12)),
          ),
          TextButton(onPressed: onRetry, child: Text('common.retry'.tr)),
        ],
      ),
    );
  }
}
