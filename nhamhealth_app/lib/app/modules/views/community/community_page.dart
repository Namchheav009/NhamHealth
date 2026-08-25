import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/nham_app_bar.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/community/community_controller.dart';
import 'community_comments_page.dart';
import 'community_post_editor_page.dart';
import 'community_report_page.dart';
import 'widgets/community_composer_card.dart';
import 'widgets/community_empty_state.dart';
import 'widgets/community_tab_switcher.dart';

class CommunityPage extends GetView<CommunityController> {
  const CommunityPage({super.key});
  static const green = Color(0xFF08A936);
  static const navy = Color(0xFF071A43);

  @override
  Widget build(BuildContext context) => Obx(
    () => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.homeBackground,
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(),
                _intro(),
                const SizedBox(height: 14),
                _mainTabs(),
                const SizedBox(height: 4),
                Expanded(
                  child: LoadingContentTransition(
                    isLoading:
                        controller.isLoading.value &&
                        !controller.hasLoaded.value,
                    loading: const SingleChildScrollView(
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        4,
                        AppSpacing.pageHorizontal,
                        110,
                      ),
                      child: PageSkeleton.community(),
                    ),
                    content: RefreshIndicator(
                      color: green,
                      onRefresh: controller.reload,
                      child: _body(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _bottomNav(),
      ),
    ),
  );

  Widget _header() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppSpacing.maxPaddedContentWidth,
      ),
      child: Padding(
        padding: AppSpacing.topBarPagePadding,
        child: NhamAppBar(
          user: controller.authenticatedUser.value,
          unreadNotificationCount: controller.unreadNotificationCount.value,
          onNotifications: () async {
            await Get.toNamed<void>(AppRoutes.notifications);
            await controller.loadTopBar();
          },
          onProfile:
              () => Get.toNamed<void>(
                AppRoutes.profile,
                arguments: controller.authenticatedUser.value,
              ),
        ),
      ),
    ),
  );

  Widget _intro() => _contentWidth(
    Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: navy,
                    letterSpacing: -.4,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Grow healthier, together.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF718078)),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _showCreatePost,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Post'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _mainTabs() => _contentWidth(
    Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: CommunityTabSwitcher(
        selected: controller.section.value,
        onChanged: controller.selectSection,
      ),
    ),
  );

  Widget _body() {
    switch (controller.section.value) {
      case CommunitySection.feed:
        return _feed();
      case CommunitySection.people:
        return _friends();
    }
  }

  Widget _friends() {
    final view = controller.friendsView.value;
    final isAdd = view == FriendsView.addFriends;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        12,
        AppSpacing.pageHorizontal,
        115,
      ),
      children: [
        _contentWidth(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title(view),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle(view),
                style: const TextStyle(fontSize: 12, color: Color(0xFF718078)),
              ),
              const SizedBox(height: 14),
              _peopleSections(),
              const SizedBox(height: 14),
              TextField(
                onChanged: controller.updateSearch,
                decoration: InputDecoration(
                  hintText:
                      isAdd
                          ? 'Search for people by name...'
                          : 'Search ${_title(view).toLowerCase()}...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.black,
                    size: 27,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FB),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (isAdd) ...[const SizedBox(height: 14), _peopleFilters()],
              const SizedBox(height: 24),
              if (!isAdd)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${controller.countFor(view)} ${_title(view).toLowerCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Text(
                      'Newest',
                      style: TextStyle(color: navy, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: navy,
                    ),
                  ],
                ),
              if (!isAdd) const SizedBox(height: 10),
              if (controller.filteredPeople.isEmpty)
                const CommunityEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No people found',
                  message: 'Try another name, interest, or filter.',
                ),
              ...controller.filteredPeople.map(
                (person) => _personTile(person, view),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _peopleSections() {
    const labels = ['Friends', 'Requests', 'Following', 'Discover'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FriendsView.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final section = FriendsView.values[index];
          final selected = controller.friendsView.value == section;
          return ChoiceChip(
            label: Text(labels[index]),
            selected: selected,
            onSelected: (_) => controller.selectFriendsView(section),
            showCheckmark: false,
            selectedColor: const Color(0xFFE3F6E8),
            backgroundColor: Colors.white,
            side: BorderSide(
              color:
                  selected ? const Color(0xFFB8E4C5) : const Color(0xFFE3E7E5),
            ),
            labelStyle: TextStyle(
              color: selected ? const Color(0xFF087B3A) : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      ),
    );
  }

  Widget _personTile(CommunityPerson person, FriendsView view) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .97),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE3EBE5)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08173D25),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFE9F4EC),
          backgroundImage: NetworkImage(person.avatarUrl),
          onBackgroundImageError: (_, _) {},
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                person.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10152A),
                ),
              ),
              if (person.detail != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      view == FriendsView.addFriends
                          ? Icons.group
                          : Icons.schedule,
                      size: 14,
                      color: const Color(0xFF6076A7),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        person.detail!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6076A7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (person.tags.isNotEmpty) ...[
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children:
                      person.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF7EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF078D35),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ],
          ),
        ),
        if (view == FriendsView.followers) ...[
          _outlineButton(
            'Accept',
            green,
            () => controller.updateConnection(person, view),
          ),
          const SizedBox(width: 6),
          _outlineButton(
            'Decline',
            Colors.red,
            () => controller.declineFollower(person),
          ),
        ] else
          _outlineButton(
            controller.connectionStatuses[person.id] ??
                (view == FriendsView.friends
                    ? 'Message'
                    : view == FriendsView.following
                    ? 'Following'
                    : 'Add'),
            green,
            () => controller.updateConnection(person, view),
          ),
        const SizedBox(width: 5),
        const Icon(Icons.more_vert, size: 22, color: Colors.black),
      ],
    ),
  );

  Widget _outlineButton(String text, Color color, VoidCallback onPressed) =>
      OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: .75)),
          minimumSize: const Size(62, 35),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
  Widget _peopleFilters() => Container(
    height: 42,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFFF2F5F3),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE1E8E3)),
    ),
    child: Row(
      children: [
        _peopleFilterOption(
          icon: Icons.people_alt_rounded,
          label: 'All people',
          filter: PeopleFilter.all,
        ),
        _peopleFilterOption(
          icon: Icons.group_outlined,
          label: 'Mutual friends',
          filter: PeopleFilter.mutualFriends,
        ),
      ],
    ),
  );

  Widget _peopleFilterOption({
    required IconData icon,
    required String label,
    required PeopleFilter filter,
  }) {
    final selected = controller.peopleFilter.value == filter;
    return Expanded(
      child: InkWell(
        onTap: () => controller.selectPeopleFilter(filter),
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow:
                selected
                    ? const [
                      BoxShadow(
                        color: Color(0x0D173D25),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? green : const Color(0xFF718078),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      selected
                          ? const Color(0xFF087B3A)
                          : const Color(0xFF59645D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feed() => ListView(
    physics: const AlwaysScrollableScrollPhysics(
      parent: BouncingScrollPhysics(),
    ),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontal,
      12,
      AppSpacing.pageHorizontal,
      115,
    ),
    children: [
      _contentWidth(
        Column(
          children: [
            _createPost(),
            _feedFilters(),
            const SizedBox(height: 14),
            if (controller.visiblePosts.isEmpty)
              const CommunityEmptyState(
                icon: Icons.dynamic_feed_outlined,
                title: 'Nothing here yet',
                message: 'Follow more people or check another feed filter.',
              ),
            ...controller.visiblePosts.map(_postCard),
          ],
        ),
      ),
    ],
  );

  Widget _createPost() => CommunityComposerCard(onTap: _showCreatePost);

  Widget _feedFilters() {
    const labels = ['For You', 'Following', 'Latest'];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CommunityFeedFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = CommunityFeedFilter.values[index];
          final selected = controller.feedFilter.value == filter;
          return ChoiceChip(
            label: Text(labels[index]),
            selected: selected,
            onSelected: (_) => controller.selectFeedFilter(filter),
            showCheckmark: false,
            selectedColor: const Color(0xFFE3F6E8),
            backgroundColor: Colors.white,
            side: BorderSide(
              color:
                  selected ? const Color(0xFFB8E4C5) : const Color(0xFFE3E7E5),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: selected ? const Color(0xFF087B3A) : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      ),
    );
  }

  Widget _postCard(CommunityPost post) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: _cardDecoration().copyWith(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE5ECE7)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: const Color(0xFFEAF7EE),
              backgroundImage:
                  post.authorAvatarUrl.isEmpty
                      ? null
                      : NetworkImage(post.authorAvatarUrl),
              child:
                  post.authorAvatarUrl.isEmpty
                      ? const Icon(Icons.person_outline_rounded, color: green)
                      : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF18231C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${post.ageLabel}  |  ${post.role}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A857D),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Post options',
              onPressed: () => _showPostOptions(post),
              icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF768178)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          post.title,
          style: const TextStyle(
            fontSize: 18,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C2720),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          post.description,
          style: const TextStyle(
            fontSize: 14,
            height: 1.42,
            color: Color(0xFF5E6961),
          ),
        ),
        if (post.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                post.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7EE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#${tag.replaceAll(' ', '')}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF178344),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
        if (post.imageBytes != null || post.imageUrls.isNotEmpty || post.imageUrl.isNotEmpty) ...[
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 218,
              width: double.infinity,
              child:
                  post.imageBytes != null
                      ? Image.memory(
                        post.imageBytes!,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      )
                      : PageView(
                        children: (post.imageUrls.isNotEmpty
                                ? post.imageUrls
                                : [post.imageUrl])
                            .map(
                              (url) => Image.network(
                                url,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, _, _) => Container(
                                  color: const Color(0xFFF3F7F4),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: Color(0xFF8D9990),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
            ),
          ),
        ],
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFEAF0EC))),
          ),
          child: Row(
            children: [
              Expanded(
                child: _PostMetricButton(
                  icon: post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  value: _compactCount(post.likes),
                  color: post.isLiked
                      ? const Color(0xFFE64657)
                      : const Color(0xFF69756D),
                  tooltip: 'Like post',
                  onTap: () => controller.togglePostLike(post),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _PostMetricButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  value: _compactCount(post.comments),
                  color: const Color(0xFF69756D),
                  tooltip: 'Comments',
                  onTap: () => _showComments(post),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _PostMetricButton(
                  icon: Icons.reply_rounded,
                  value: _compactCount(post.shares),
                  color: const Color(0xFF69756D),
                  tooltip: 'Share with friends',
                  onTap: () => _showShareToFriends(post),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  String _compactCount(int value) {
    if (value < 1000) return '$value';
    final compact = value / 1000;
    return '${compact == compact.roundToDouble() ? compact.toStringAsFixed(0) : compact.toStringAsFixed(1)}k';
  }

  Future<void> _showPostOptions(CommunityPost post) async {
    final isOwner = post.authorId == controller.authenticatedUser.value?.id;
    final action = await Get.bottomSheet<String>(
      _CommunityOptionsSheet(
        title: isOwner ? 'Post options' : 'More options',
        actions: isOwner
            ? const [
                _CommunityOption('edit', 'Edit post', Icons.edit_outlined),
                _CommunityOption('delete', 'Delete post', Icons.delete_outline_rounded, isDestructive: true),
              ]
            : const [
                _CommunityOption('about', 'About this post', Icons.info_outline_rounded),
                _CommunityOption('report', 'Report post', Icons.flag_outlined, isDestructive: true),
              ],
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
    if (action != null) await _handlePostOption(action, post);
  }

  Future<void> _handlePostOption(String action, CommunityPost post) async {
    switch (action) {
      case 'edit':
        await _showEditPost(post);
        return;
      case 'delete':
        await _confirmDeletePost(post);
        return;
      case 'report':
        await Get.to<void>(() => const CommunityReportPage(subject: 'post'));
        return;
      case 'about':
        await _showComments(post);
        return;
    }
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
          title: draft.title,
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
    final title = TextEditingController(text: post.title);
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
                  Icon(Icons.edit_rounded, color: green),
                  SizedBox(width: 10),
                  Text('Edit post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: title,
                textCapitalization: TextCapitalization.sentences,
                decoration: _postInput('Title (optional)'),
              ),
              const SizedBox(height: 12),
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
                          title: title.text,
                          description: description.text,
                        );
                        Get.back<void>();
                        Get.snackbar('Post updated', 'Your changes have been saved.');
                      } on Object catch (error) {
                        Get.snackbar('Could not update post', error.toString());
                      }
                    },
                    style: FilledButton.styleFrom(backgroundColor: green),
                    child: const Text('Save changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    title.dispose();
    description.dispose();
  }

  Future<void> _confirmDeletePost(CommunityPost post) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text('This will remove the post from Community. You cannot undo this action.'),
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

  Future<void> _showShareToFriends(CommunityPost post) async {
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
                const Text(
                  'Share with friends',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text('Choose friends to send this post to.'),
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
                        final selected = selectedIds.contains(friend.id);
                        return CheckboxListTile(
                          value: selected,
                          onChanged: (_) => setSheetState(() {
                            selected
                                ? selectedIds.remove(friend.id)
                                : selectedIds.add(friend.id);
                          }),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.trailing,
                          activeColor: green,
                          title: Text(friend.name),
                          secondary: CircleAvatar(
                            backgroundColor: const Color(0xFFEAF7EE),
                            backgroundImage: friend.avatarUrl.isEmpty
                                ? null
                                : NetworkImage(friend.avatarUrl),
                            child: friend.avatarUrl.isEmpty
                                ? const Icon(Icons.person_outline, color: green)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: selectedIds.isEmpty
                        ? null
                        : () async {
                            try {
                              await controller.sharePost(
                                post,
                                recipientIds: selectedIds.toList(),
                              );
                              Get.back<void>();
                              Get.snackbar(
                                'Post shared',
                                'Sent to ${selectedIds.length} friend${selectedIds.length == 1 ? '' : 's'}.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            } on Object catch (error) {
                              Get.snackbar(
                                'Could not share post',
                                error.toString(),
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send'),
                    style: FilledButton.styleFrom(backgroundColor: green),
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

  Future<void> _showComments(CommunityPost post) async {
    await Get.to<void>(
      () => CommunityCommentsPage(
        post: post,
        onPostChanged: controller.posts.refresh,
        canEdit: post.authorId == controller.authenticatedUser.value?.id,
        onEditPost: (draft) => controller.updatePost(
          post: post,
          title: draft.title,
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

  Future<void> _showCreatePost() async {
    final user = controller.authenticatedUser.value;
    await Get.to<void>(
      () => CommunityPostEditorPage(
        authorName: user?.displayName ?? 'Community member',
        authorAvatarUrl: user?.profileImageUrl ?? '',
        onSubmit: (draft) => controller.addPost(
          title: draft.title,
          description: draft.description,
          imageBytes: draft.imageBytes,
          visibility: draft.visibility,
          allowComments: draft.allowComments,
          allowReplies: draft.allowReplies,
          tagIds: draft.tagIds,
        ),
      ),
      transition: Transition.rightToLeft,
    );
  }

  // ignore: unused_element
  Future<void> _showLegacyCreatePost() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final imagePicker = ImagePicker();
    Uint8List? selectedImage;

    await Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 640),
          child: StatefulBuilder(
            builder:
                (context, setDialogState) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, color: green),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Create a post',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: Get.back,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              TextField(
                                controller: title,
                                autofocus: true,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: _postInput('Title (optional)'),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: description,
                                maxLines: 4,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: _postInput(
                                  'What would you like to share?',
                                  alignLabelWithHint: true,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (selectedImage != null) ...[
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.memory(
                                          selectedImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Material(
                                          color: Colors.black54,
                                          shape: const CircleBorder(),
                                          child: IconButton(
                                            onPressed:
                                                () => setDialogState(
                                                  () => selectedImage = null,
                                                ),
                                            tooltip: 'Remove image',
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.white,
                                              size: 19,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final image = await imagePicker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 82,
                                      maxWidth: 1600,
                                    );
                                    if (image == null) return;
                                    final bytes = await image.readAsBytes();
                                    if (context.mounted) {
                                      setDialogState(
                                        () => selectedImage = bytes,
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    selectedImage == null
                                        ? Icons.add_photo_alternate_outlined
                                        : Icons.image_outlined,
                                  ),
                                  label: Text(
                                    selectedImage == null
                                        ? 'Add image'
                                        : 'Change image',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: green,
                                    side: const BorderSide(
                                      color: Color(0xFFB8E4C5),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: Get.back,
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () async {
                              if (description.text.trim().isEmpty) {
                                Get.snackbar(
                                  'Add your message',
                                  'Write something you would like to share.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(16),
                                );
                                return;
                              }
                              try {
                                await controller.addPost(
                                  title: title.text,
                                  description: description.text,
                                  imageBytes: selectedImage == null ? const [] : [selectedImage!],
                                );
                                Get.back<void>();
                              } on Object catch (error) {
                                Get.snackbar(
                                  'Could not publish',
                                  error.toString(),
                                  snackPosition: SnackPosition.BOTTOM,
                                  margin: const EdgeInsets.all(16),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                            ),
                            child: const Text('Publish'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
    title.dispose();
    description.dispose();
  }

  InputDecoration _postInput(String label, {bool alignLabelWithHint = false}) =>
      InputDecoration(
        labelText: label,
        alignLabelWithHint: alignLabelWithHint,
        filled: true,
        fillColor: const Color(0xFFF7FAF8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white.withValues(alpha: .98),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFFE3EBE5)),
    boxShadow: const [
      BoxShadow(color: Color(0x0A173D25), blurRadius: 18, offset: Offset(0, 6)),
    ],
  );
  Widget _contentWidth(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppSpacing.maxPaddedContentWidth,
      ),
      child: child,
    ),
  );
  String _title(FriendsView view) =>
      const ['Friends', 'Followers', 'Following', 'Add Friends'][view.index];
  String _subtitle(FriendsView view) =>
      const [
        'Your accepted connections.',
        'People who want to connect with you.',
        'People and accounts you follow.',
        'Find and connect with new people.',
      ][view.index];
  Widget _bottomNav() => SafeArea(
    top: false,
    minimum: AppSpacing.navigationMargin,
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: AppBottomNavigation(
          selectedIndex: 2,
          onSelect: (index) {
            if (index == 0) Get.offNamed<void>(AppRoutes.home);
            if (index == 1) Get.offNamed<void>(AppRoutes.meals);
            if (index == 4) Get.offNamed<void>(AppRoutes.settings);
          },
        ),
      ),
    ),
  );
}

class _PostMetricButton extends StatelessWidget {
  const _PostMetricButton({
    required this.icon,
    required this.value,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 7),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 18,
    child: VerticalDivider(width: 1, color: Color(0xFFDCE6DF)),
  );
}

class _CommunityOption {
  const _CommunityOption(
    this.value,
    this.label,
    this.icon, {
    this.isDestructive = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool isDestructive;
}

class _CommunityOptionsSheet extends StatelessWidget {
  const _CommunityOptionsSheet({required this.title, required this.actions});

  final String title;
  final List<_CommunityOption> actions;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 5,
              width: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF9AA19C),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  _OptionTile(option: actions[index]),
                  if (index < actions.length - 1)
                    const Divider(height: 1, indent: 64, color: Color(0xFFE0E5E1)),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option});

  final _CommunityOption option;

  @override
  Widget build(BuildContext context) {
    final color = option.isDestructive ? const Color(0xFFD94545) : const Color(0xFF18231C);
    return ListTile(
      onTap: () => Get.back(result: option.value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      leading: Icon(option.icon, color: color, size: 27),
      title: Text(option.label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}
