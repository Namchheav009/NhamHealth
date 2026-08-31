import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/loading_content_transition.dart';
import '../../../widgets/nham_app_bar.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/community/community_controller.dart';
import 'community_comments_page.dart';
import 'community_post_editor_page.dart';
import 'community_report_page.dart';
import 'community_share_actions.dart';
import 'community_share_post_page.dart';
import 'widgets/community_composer_card.dart';
import 'widgets/community_empty_state.dart';
import 'widgets/community_shared_post_card.dart';
import 'widgets/community_tab_switcher.dart';
import '../profile/widgets/profile_post_card.dart';

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
        backgroundColor: context.appBackground,
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(context),
                _intro(context),
                const SizedBox(height: 14),
                _mainTabs(context),
                const SizedBox(height: 4),
                Expanded(
                  child: LoadingContentTransition(
                    isLoading:
                        controller.isLoading.value &&
                        !controller.hasLoaded.value,
                    loading: SingleChildScrollView(
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontalFor(context),
                        4,
                        AppSpacing.pageHorizontalFor(context),
                        110,
                      ),
                      child: const PageSkeleton.community(),
                    ),
                    content: RefreshIndicator(
                      color: green,
                      onRefresh: controller.reload,
                      child: _body(context),
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

  Widget _header(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppSpacing.maxWidePaddedContentWidth,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontalFor(context),
          AppSpacing.pageTop,
          AppSpacing.pageHorizontalFor(context),
          0,
        ),
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

  Widget _intro(BuildContext context) => _contentWidth(
    Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontalFor(context),
      ),
    ),
  );

  Widget _mainTabs(BuildContext context) => _contentWidth(
    Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontalFor(context),
      ),
      child: CommunityTabSwitcher(
        selected: controller.section.value,
        onChanged: controller.selectSection,
      ),
    ),
  );

  Widget _body(BuildContext context) {
    switch (controller.section.value) {
      case CommunitySection.feed:
        return _feed(context);
      case CommunitySection.people:
        return _friends(context);
    }
  }

  Widget _friends(BuildContext context) {
    final view = controller.friendsView.value;
    final isAdd = view == FriendsView.addFriends;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontalFor(context),
        12,
        AppSpacing.pageHorizontalFor(context),
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

  Widget _feed(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(
      parent: BouncingScrollPhysics(),
    ),
    padding: EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontalFor(context),
      12,
      AppSpacing.pageHorizontalFor(context),
      115,
    ),
    children: [
      _contentWidth(
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 820) return _compactFeed();

            return Row(
              key: const ValueKey<String>('community-tablet-layout'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 290, child: _feedControls()),
                const SizedBox(width: 18),
                Expanded(child: _feedPosts()),
              ],
            );
          },
        ),
      ),
    ],
  );

  Widget _compactFeed() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (controller.errorMessage.value != null) ...[
        _feedErrorBanner(controller.errorMessage.value!),
        const SizedBox(height: 12),
      ],
      _feedControls(),
      const SizedBox(height: 14),
      _feedPosts(showError: false),
    ],
  );

  Widget _feedControls() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CommunityComposerCard(
        onTap: _showCreatePost,
        authorAvatarUrl:
            controller.authenticatedUser.value?.profileImageUrl ?? '',
      ),
      const SizedBox(height: 14),
      _feedFilters(),
      const SizedBox(height: 14),
    ],
  );

  Widget _feedPosts({bool showError = true}) => Obx(() {
    final visiblePosts = controller.visiblePosts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showError && controller.errorMessage.value != null) ...[
          _feedErrorBanner(controller.errorMessage.value!),
          const SizedBox(height: 12),
        ],
        if (visiblePosts.isEmpty)
          const CommunityEmptyState(
            icon: Icons.dynamic_feed_outlined,
            title: 'Nothing here yet',
            message: 'Follow more people or check another feed filter.',
          ),
        ...visiblePosts.map(_postCard),
      ],
    );
  });

  Widget _feedFilters() {
    const labels = ['For You', 'Following', 'Latest'];
    const icons = [
      Icons.auto_awesome_rounded,
      Icons.people_outline_rounded,
      Icons.schedule_rounded,
    ];
    return Obx(
      () => Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFD9E6DE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D173D25),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: List.generate(CommunityFeedFilter.values.length, (index) {
            final filter = CommunityFeedFilter.values[index];
            final selected = controller.feedFilter.value == filter;
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: '${labels[index]} feed filter',
                child: InkWell(
                  key: ValueKey<String>(
                    'community-feed-filter-${filter.name}',
                  ),
                  onTap: () => controller.selectFeedFilter(filter),
                  borderRadius: BorderRadius.circular(13),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? const Color(0xFFEAF8EF)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(13),
                      border:
                          selected
                              ? Border.all(color: const Color(0xFFCDE8D7))
                              : null,
                      boxShadow:
                          selected
                              ? const [
                                BoxShadow(
                                  color: Color(0x12056E38),
                                  blurRadius: 7,
                                  offset: Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icons[index],
                          size: 16,
                          color:
                              selected
                                  ? const Color(0xFF087B3A)
                                  : const Color(0xFF738077),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  selected
                                      ? const Color(0xFF087B3A)
                                      : const Color(0xFF647168),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _feedErrorBanner(String message) => Container(
    padding: const EdgeInsets.fromLTRB(13, 11, 8, 11),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4F2),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFFD8D2)),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, color: Color(0xFFD85245), size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF78453F),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
        TextButton(onPressed: controller.reload, child: const Text('Retry')),
      ],
    ),
  );

  Widget _postCard(CommunityPost post) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: ProfilePostCard(
      post: post,
      onLike: () => controller.togglePostLike(post),
      onComment: () => _showComments(post),
      onShare: () => _showShareOptions(post),
      onOptions: () => _showPostOptions(post),
    ),
  );

  // Kept temporarily as a reference while all post surfaces use the shared card.
  // ignore: unused_element
  Widget _legacyPostCard(CommunityPost post) => Container(
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
                  Row(
                    children: [
                      Icon(
                        post.visibility.icon,
                        size: 13,
                        color: const Color(0xFF7A857D),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${post.ageLabel}  ·  ${post.role}${post.sharedPost == null ? '' : '  ·  Shared'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A857D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Post options',
              onPressed: () => _showPostOptions(post),
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFF768178),
              ),
            ),
          ],
        ),
        if (post.description.isNotEmpty) ...[
          const SizedBox(height: 15),
          Text(
            post.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.42,
              color: Color(0xFF5E6961),
            ),
          ),
        ],
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
        if (post.sharedPost != null) ...[
          const SizedBox(height: 14),
          CommunitySharedPostCard(post: post.sharedPost!),
        ],
        if (post.imageBytes != null ||
            post.imageUrls.isNotEmpty ||
            post.imageUrl.isNotEmpty) ...[
          const SizedBox(height: 15),
          _ImageCarousel(
            imageBytes: post.imageBytes,
            imageUrls:
                post.imageUrls.isNotEmpty ? post.imageUrls : [post.imageUrl],
          ),
        ],
        if (post.likes > 0 || post.comments > 0 || post.shares > 0) ...[
          const SizedBox(height: 11),
          _engagementSummary(post),
        ],
        Container(
          margin: const EdgeInsets.only(top: 7),
          padding: const EdgeInsets.only(top: 4),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFEAF0EC))),
          ),
          child: Row(
            children: [
              Expanded(
                child: _PostMetricButton(
                  icon:
                      post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                  label: post.isLiked ? 'Liked' : 'Like',
                  color:
                      post.isLiked
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
                  label: 'Comment',
                  color: const Color(0xFF69756D),
                  tooltip: 'Comments',
                  onTap: () => _showComments(post),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _PostMetricButton(
                  icon: Icons.reply_rounded,
                  label: 'Share',
                  color: const Color(0xFF69756D),
                  tooltip: 'Share post',
                  onTap: () => _showShareOptions(post),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _engagementSummary(CommunityPost post) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Row(
      children: [
        if (post.likes > 0) ...[
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFE64657),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 12,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _compactCount(post.likes),
            style: const TextStyle(fontSize: 12, color: Color(0xFF69756D)),
          ),
        ],
        const Spacer(),
        if (post.comments > 0)
          Text(
            '${_compactCount(post.comments)} ${post.comments == 1 ? 'comment' : 'comments'}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF69756D)),
          ),
        if (post.comments > 0 && post.shares > 0)
          const Text('  ·  ', style: TextStyle(color: Color(0xFF98A19A))),
        if (post.shares > 0)
          Text(
            '${_compactCount(post.shares)} ${post.shares == 1 ? 'share' : 'shares'}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF69756D)),
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
    final action = await Get.bottomSheet<_CommunityPostAction>(
      _CommunityOptionsSheet(
        title: isOwner ? 'Post options' : 'More options',
        actions:
            isOwner
                ? const [
                  _CommunityOption(
                    _CommunityPostAction.edit,
                    'Edit post',
                    Icons.edit_outlined,
                  ),
                  _CommunityOption(
                    _CommunityPostAction.delete,
                    'Delete post',
                    Icons.delete_outline_rounded,
                    isDestructive: true,
                  ),
                ]
                : const [
                  _CommunityOption(
                    _CommunityPostAction.about,
                    'About this post',
                    Icons.info_outline_rounded,
                  ),
                  _CommunityOption(
                    _CommunityPostAction.report,
                    'Report post',
                    Icons.flag_outlined,
                    isDestructive: true,
                  ),
                ],
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
    if (action != null) await _handlePostOption(action, post);
  }

  Future<void> _handlePostOption(
    _CommunityPostAction action,
    CommunityPost post,
  ) async {
    switch (action) {
      case _CommunityPostAction.edit:
        await _showEditPost(post);
      case _CommunityPostAction.delete:
        await _confirmDeletePost(post);
      case _CommunityPostAction.report:
        await Get.to<void>(
          () => CommunityReportPage(postId: post.id, subject: 'post'),
        );
      case _CommunityPostAction.about:
        await _showComments(post);
    }
  }

  Future<void> _showEditPost(CommunityPost post) async {
    final user = controller.authenticatedUser.value;
    await Get.to<void>(
      () => CommunityPostEditorPage(
        post: post,
        authorName: user?.displayName ?? post.author,
        authorAvatarUrl: user?.profileImageUrl ?? post.authorAvatarUrl,
        onSubmit:
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
                  Icon(Icons.edit_rounded, color: green),
                  SizedBox(width: 10),
                  Text(
                    'Edit post',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: description,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: _postInput(
                  'What would you like to share?',
                  alignLabelWithHint: true,
                ),
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
                        Get.snackbar(
                          'Add your message',
                          'A post needs a message.',
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
                          'Post updated',
                          'Your changes have been saved.',
                        );
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
    description.dispose();
  }

  Future<void> _confirmDeletePost(CommunityPost post) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text(
          'This will remove the post from Community. You cannot undo this action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD94545),
            ),
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

  Future<void> _showShareOptions(CommunityPost post) async {
    final action = await showCommunityShareActions(
      canShareToFeed:
          post.sharedPost != null ||
          post.visibility == CommunityPostVisibility.public,
    );
    if (action == null) return;
    switch (action) {
      case CommunityShareAction.shareNow:
        try {
          await controller.sharePostToFeed(post);
          unawaited(
            AppAlert.success(
              title: 'Post shared',
              message: 'The post is now on your Community feed.',
            ),
          );
        } on Object catch (error) {
          unawaited(
            AppAlert.error(
              title: 'Could not share post',
              message: error.toString(),
            ),
          );
        }
        break;
      case CommunityShareAction.writePost:
        final user = controller.authenticatedUser.value;
        await Get.to<void>(
          () => CommunitySharePostPage(
            post: post,
            authorName: user?.displayName ?? 'Community member',
            authorAvatarUrl: user?.profileImageUrl ?? '',
            onShare: (message, visibility) async {
              await controller.sharePostToFeed(
                post,
                message: message,
                visibility: visibility,
              );
            },
          ),
          transition: Transition.rightToLeft,
        );
        break;
    }
  }

  Future<void> _showComments(CommunityPost post) async {
    await Get.to<void>(
      () => CommunityCommentsPage(
        post: post,
        onPostChanged: controller.posts.refresh,
        onShareToFeed: (message, visibility) async {
          await controller.sharePostToFeed(
            post,
            message: message,
            visibility: visibility,
          );
        },
        canEdit: post.authorId == controller.authenticatedUser.value?.id,
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

  Future<void> _showCreatePost() async {
    final user = controller.authenticatedUser.value;
    await Get.to<void>(
      () => CommunityPostEditorPage(
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

  // ignore: unused_element
  Future<void> _showLegacyCreatePost() async {
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
                                controller: description,
                                autofocus: true,
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
                                  description: description.text,
                                  imageBytes:
                                      selectedImage == null
                                          ? const []
                                          : [selectedImage!],
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
        maxWidth: AppSpacing.maxWidePaddedContentWidth,
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

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.imageBytes, required this.imageUrls});

  final Uint8List? imageBytes;
  final List<String> imageUrls;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.toInt() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageCount = widget.imageUrls.length;
    final showCarousel = imageCount > 1;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: AspectRatio(
                    aspectRatio: 5 / 4,
                    child:
                        widget.imageBytes != null
                            ? Image.memory(
                              widget.imageBytes!,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                            )
                            : PageView(
                              controller: _pageController,
                              children: widget.imageUrls
                                  .map(
                                    (url) => Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.medium,
                                      errorBuilder:
                                          (_, _, _) => Container(
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
              ),
              // Carousel Counter
              if (showCarousel)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentPage + 1}/$imageCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Pagination Dots
        if (showCarousel) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imageCount,
              (index) => GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 8 : 6,
                  height: _currentPage == index ? 8 : 6,
                  decoration: BoxDecoration(
                    color:
                        _currentPage == index
                            ? const Color(0xFF1F2937)
                            : const Color(0xFFD1D5DB),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PostMetricButton extends StatelessWidget {
  const _PostMetricButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String label;
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
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
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

enum _CommunityPostAction { edit, delete, about, report }

class _CommunityOption {
  const _CommunityOption(
    this.value,
    this.label,
    this.icon, {
    this.isDestructive = false,
  });

  final _CommunityPostAction value;
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
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
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
                    const Divider(
                      height: 1,
                      indent: 64,
                      color: Color(0xFFE0E5E1),
                    ),
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
    final color =
        option.isDestructive
            ? const Color(0xFFD94545)
            : const Color(0xFF18231C);
    return ListTile(
      onTap: () => Get.back(result: option.value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      leading: Icon(option.icon, color: color, size: 27),
      title: Text(
        option.label,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
