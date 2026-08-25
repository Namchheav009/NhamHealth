import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile/profile_controller.dart';
import '../../models/community/community_post.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/page_skeleton.dart';
import 'widgets/health_stats_card.dart';
import 'widgets/insight_card.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_post_card.dart';
import '../community/community_comments_page.dart';
import '../community/community_post_editor_page.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFFFBFC),
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: controller.refreshProfile,
            color: const Color(0xFF009B3E),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: AppSpacing.pagePadding,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildTopBar(),
                  Obx(() {
                    final message = controller.errorMessage.value;
                    if (message == null) return const SizedBox.shrink();
                    return _ProfileErrorBanner(
                      message: message,
                      onRetry: controller.loadProfile,
                    );
                  }),
                  const SizedBox(height: AppSpacing.topBarBottom),
                  Obx(
                    () => LoadingContentTransition(
                      isLoading:
                          controller.isLoading.value &&
                          controller.dashboard.value == null,
                      loading: const PageSkeleton.profile(),
                      content: Column(
                        children: [
                          const ProfileHeader(),
                          const SizedBox(height: 14),
                          const HealthStatsCard(),
                          const SizedBox(height: 14),
                          const InsightCard(),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              const Text(
                                'My posts',
                                style: TextStyle(
                                  color: Color(0xFF26322B),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF7EE),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${controller.posts.length} ${controller.posts.length == 1 ? 'post' : 'posts'}',
                                  style: const TextStyle(
                                    color: Color(0xFF178344),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (controller.posts.isEmpty)
                            const _EmptyPosts()
                          else
                            ...controller.posts.map(
                              (post) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ProfilePostCard(
                                  post: post,
                                  authorName: controller.name.value,
                                  authorAvatarUrl:
                                      controller.authenticatedUser.value?.profileImageUrl ?? '',
                                  membership: controller.membership.value,
                                  onEdit: () => _showEditPost(post),
                                  onDelete: () => _confirmDeletePost(post),
                                  onLike: () => controller.togglePostLike(post),
                                  onComment: () => _showComments(post),
                                  onShare: () => _showShare(post),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return AppBackHeader(
      title: 'Profile',
      backButtonKey: const ValueKey('profile-back-button'),
      onBack: controller.goBack,
    );
  }

  Future<void> _showEditPost(CommunityPost post) async {
    final user = controller.authenticatedUser.value;
    await Get.to<void>(
      () => CommunityPostEditorPage(
        post: post,
        authorName: user?.displayName ?? post.author,
        authorAvatarUrl: user?.profileImageUrl ?? post.authorAvatarUrl,
        onSubmit: (draft) => controller.updatePost(
          post: post,
          description: draft.description,
          imageBytes: draft.imageBytes,
          visibility: draft.visibility,
          allowComments: draft.allowComments,
          allowReplies: draft.allowReplies,
          removeImage: draft.removeImage,
          tagIds: draft.tagIds,
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_rounded, color: Color(0xFF009B46)),
                  SizedBox(width: 10),
                  Text('Edit post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: description,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: _postInput('What would you like to share?', alignLabelWithHint: true),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: Get.back, child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      if (description.text.trim().isEmpty) {
                        Get.snackbar('Add your message', 'A post needs a message.');
                        return;
                      }
                      try {
                        await controller.updatePost(
                          post: post,
                          description: description.text,
                        );
                        Get.back<void>();
                        Get.snackbar('Post updated', 'Your changes have been saved.');
                      } on Object catch (error) {
                        Get.snackbar('Could not update post', error.toString());
                      }
                    },
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF009B46)),
                    child: const Text('Save changes'),
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
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('This will remove the post from your profile and Community. You cannot undo this action.'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD94545)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await controller.deletePost(post);
      Get.snackbar('Post deleted', 'Your post has been removed.');
    } on Object catch (error) {
      Get.snackbar('Could not delete post', error.toString());
    }
  }

  Future<void> _showComments(CommunityPost post) async {
    await Get.to<void>(
      () => CommunityCommentsPage(
        post: post,
        onPostChanged: controller.posts.refresh,
        canEdit: true,
        onEditPost: (draft) => controller.updatePost(
          post: post,
          description: draft.description,
          imageBytes: draft.imageBytes,
          visibility: draft.visibility,
          allowComments: draft.allowComments,
          allowReplies: draft.allowReplies,
          removeImage: draft.removeImage,
          tagIds: draft.tagIds,
        ),
      ),
      transition: Transition.rightToLeft,
    );
  }

  Future<void> _showShare(CommunityPost post) async {
    try {
      await controller.loadFriends();
    } on Object catch (error) {
      Get.snackbar('Could not load friends', error.toString());
      return;
    }
    final selectedIds = <String>{};
    await Get.bottomSheet<void>(
      StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Share with friends', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                if (controller.friends.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Add friends before sharing posts privately.'),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.friends.length,
                      itemBuilder: (context, index) {
                        final friend = controller.friends[index];
                        return CheckboxListTile(
                          value: selectedIds.contains(friend.id),
                          title: Text(friend.name),
                          onChanged: (selected) => setSheetState(() {
                            selected == true ? selectedIds.add(friend.id) : selectedIds.remove(friend.id);
                          }),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: selectedIds.isEmpty
                        ? null
                        : () async {
                            try {
                              await controller.sharePost(post, recipientIds: selectedIds.toList());
                              Get.back<void>();
                              Get.snackbar('Post shared', 'Sent to ${selectedIds.length} friend${selectedIds.length == 1 ? '' : 's'}.');
                            } on Object catch (error) {
                              Get.snackbar('Could not share post', error.toString());
                            }
                          },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send'),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF009B46)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  InputDecoration _postInput(String label, {bool alignLabelWithHint = false}) =>
      InputDecoration(
        labelText: label,
        alignLabelWithHint: alignLabelWithHint,
        filled: true,
        fillColor: const Color(0xFFF7FAF8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );
}

class _EmptyPosts extends StatelessWidget {
  const _EmptyPosts();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      children: [
        Icon(Icons.post_add_outlined, color: Color(0xFF009B46)),
        SizedBox(height: 8),
        Text('You have not shared any posts yet.'),
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
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD84A4A), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message.tr, style: const TextStyle(fontSize: 12)),
          ),
          TextButton(onPressed: onRetry, child: Text('Retry'.tr)),
        ],
      ),
    );
  }
}
