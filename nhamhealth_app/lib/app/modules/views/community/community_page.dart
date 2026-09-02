import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
import '../profile/widgets/profile_post_card.dart';
import 'community_comments_page.dart';
import 'community_post_editor_page.dart';
import 'community_report_page.dart';
import 'community_share_actions.dart';
import 'widgets/community_composer_card.dart';
import 'widgets/community_empty_state.dart';
import 'widgets/community_tab_switcher.dart';

class CommunityPage extends GetView<CommunityController> {
  const CommunityPage({super.key});

  static const Color green = AppColors.primaryGreen;

  static const double _mobileBreakpoint = 720;
  static const double _feedTwoColumnBreakpoint = 820;
  static const double _cardRadius = 18;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: context.appBackground,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Obx(() => _header(context)),
              const SizedBox(height: 10),
              Obx(() => _mainTabs(context)),
              const SizedBox(height: 4),
              Expanded(
                child: Obx(
                  () => LoadingContentTransition(
                    isLoading:
                        controller.isLoading.value &&
                        !controller.hasLoaded.value,
                    loading: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontalFor(context),
                        6,
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
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ---------------------------------------------------------------------------
  // Top-level layout
  // ---------------------------------------------------------------------------

  Widget _header(BuildContext context) => _contentWidth(
    Padding(
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
    return switch (controller.section.value) {
      CommunitySection.feed => _feed(context),
      CommunitySection.people => _people(context),
    };
  }

  Widget _contentWidth(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: AppSpacing.maxWidePaddedContentWidth,
      ),
      child: child,
    ),
  );

  // ---------------------------------------------------------------------------
  // People
  // ---------------------------------------------------------------------------

  Widget _people(BuildContext context) {
    final view = controller.friendsView.value;
    final isDiscover = view == FriendsView.addFriends;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontalFor(context),
        10,
        AppSpacing.pageHorizontalFor(context),
        115,
      ),
      children: [
        _contentWidth(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _peopleSections(context),
              const SizedBox(height: 14),
              _PeopleSearchField(
                key: ValueKey<String>('people-search-${view.name}'),
                hintText:
                    isDiscover
                        ? 'Search people by name'
                        : 'Search ${_resultLabel(view)}',
                onChanged: controller.updateSearch,
              ),
              if (isDiscover) ...[
                const SizedBox(height: 10),
                _peopleFilters(context),
              ],
              const SizedBox(height: 18),
              _peopleResults(context, view),
            ],
          ),
        ),
      ],
    );
  }

  Widget _peopleSections(BuildContext context) {
    const labels = ['Friends', 'Followers', 'Following', 'Discover'];
    const icons = [
      Icons.people_alt_rounded,
      Icons.person_add_alt_1_rounded,
      Icons.favorite_rounded,
      Icons.explore_rounded,
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FriendsView.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final section = FriendsView.values[index];
          final selected = controller.friendsView.value == section;

          return Semantics(
            selected: selected,
            button: true,
            label: '${labels[index]} people filter',
            child: Material(
              color:
                  selected
                      ? context.appSoftGreen
                      : context.appSurfaceLow.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                key: ValueKey<String>('people-section-${section.name}'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => controller.selectFriendsView(section),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          selected
                              ? green.withValues(alpha: .28)
                              : context.appBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icons[index],
                        size: 16,
                        color: selected ? green : context.appMutedText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: selected ? green : context.appMutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _peopleFilters(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.appMutedSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          _peopleFilterOption(
            context: context,
            icon: Icons.public_rounded,
            label: 'Everyone',
            filter: PeopleFilter.all,
          ),
          _peopleFilterOption(
            context: context,
            icon: Icons.people_alt_rounded,
            label: 'Mutual friends',
            filter: PeopleFilter.mutualFriends,
          ),
        ],
      ),
    );
  }

  Widget _peopleFilterOption({
    required BuildContext context,
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
            color: selected ? context.appSurfaceLow : Colors.transparent,
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
                size: 16,
                color: selected ? green : context.appMutedText,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? green : context.appMutedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _peopleResults(BuildContext context, FriendsView view) {
    final people = controller.filteredPeople;
    final hasQuery = controller.searchQuery.value.trim().isNotEmpty;

    if (people.isEmpty) {
      return CommunityEmptyState(
        icon: hasQuery ? Icons.search_off_rounded : _viewIcon(view),
        title: hasQuery ? 'No matching people' : _emptyTitle(view),
        message: hasQuery ? 'Try another name.' : _emptyMessage(view),
      );
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth < _mobileBreakpoint) {
          return Column(
            children: people
                .map((person) => _personCard(context, person, view))
                .toList(growable: false),
          );
        }

        final cardWidth = (constraints.maxWidth - 14) / 2;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: people
              .map(
                (person) => SizedBox(
                  width: cardWidth,
                  child: _personCard(
                    context,
                    person,
                    view,
                    addBottomMargin: false,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _personCard(
    BuildContext context,
    CommunityPerson person,
    FriendsView view, {
    bool addBottomMargin = true,
  }) {
    return Container(
      key: ValueKey<String>('people-card-${person.id}'),
      margin: EdgeInsets.only(bottom: addBottomMargin ? 10 : 0),
      decoration: BoxDecoration(
        color: context.appSurfaceLow.withValues(alpha: .98),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color:
              view == FriendsView.addFriends
                  ? green.withValues(alpha: .20)
                  : context.appBorder,
        ),
        boxShadow: context.appTileShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_cardRadius),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            children: [
              InkWell(
                key: ValueKey<String>('people-profile-area-${person.id}'),
                onTap: () => _openPersonProfile(person),
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    _personAvatar(context, person),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.name.trim().isEmpty
                                ? 'Community member'
                                : person.name.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.appText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: context.appMutedText,
                    ),
                  ],
                ),
              ),
              if (person.tags.isNotEmpty) ...[
                const SizedBox(height: 11),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: person.tags
                        .take(3)
                        .map(
                          (tag) => _personTag(context, tag, Icons.eco_outlined),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Obx(() => _personAction(context, person, view)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _personAvatar(BuildContext context, CommunityPerson person) {
    final fallback = Container(
      color: context.appSoftGreen,
      alignment: Alignment.center,
      child: Text(
        _initials(person.name),
        style: const TextStyle(
          color: green,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Semantics(
      image: true,
      label: '${person.name} profile photo',
      child: Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: green.withValues(alpha: .20), width: 1.5),
        ),
        child: ClipOval(
          child:
              person.avatarUrl.trim().isEmpty
                  ? fallback
                  : Image.network(
                    person.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback,
                  ),
        ),
      ),
    );
  }

  Widget _personTag(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.appSoftGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: green),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _personAction(
    BuildContext context,
    CommunityPerson person,
    FriendsView view,
  ) {
    final status = _effectiveConnectionStatus(person);
    final isFriend = status == 'FRIEND' || view == FriendsView.friends;
    final isUpdating = controller.updatingConnectionIds.contains(person.id);

    if (isFriend) {
      return SizedBox(
        width: double.infinity,
        height: 40,
        child: _profileButton(context, person, expandedLabel: true),
      );
    }

    final isFollowing = status == 'FOLLOWING';

    final label =
        isFollowing
            ? 'Following'
            : view == FriendsView.followers || status == 'FOLLOWS_YOU'
            ? 'Follow back'
            : 'Follow';

    final followButton =
        isFollowing
            ? OutlinedButton(
              key: ValueKey<String>('people-action-${person.id}'),
              onPressed:
                  isUpdating
                      ? null
                      : () => controller.updateConnection(person, view),
              style: OutlinedButton.styleFrom(
                foregroundColor: green,
                backgroundColor: context.appSurfaceLow.withValues(alpha: .72),
                side: BorderSide(color: green.withValues(alpha: .34)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _followButtonContent(
                label: 'Following',
                icon: Icons.check_rounded,
                isLoading: isUpdating,
                spinnerColor: green,
              ),
            )
            : FilledButton(
              key: ValueKey<String>('people-action-${person.id}'),
              onPressed:
                  isUpdating
                      ? null
                      : () => controller.updateConnection(person, view),
              style: FilledButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _followButtonContent(
                label: label,
                icon: Icons.person_add_alt_1_rounded,
                isLoading: isUpdating,
                spinnerColor: Colors.white,
              ),
            );

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(flex: 4, child: _profileButton(context, person)),
          const SizedBox(width: 8),
          Expanded(flex: 5, child: followButton),
        ],
      ),
    );
  }

  Widget _followButtonContent({
    required String label,
    required IconData icon,
    required bool isLoading,
    required Color spinnerColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              key: const ValueKey<String>('people-follow-progress'),
              strokeWidth: 2,
              color: spinnerColor,
            ),
          )
        else
          Icon(icon, size: 17),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _profileButton(
    BuildContext context,
    CommunityPerson person, {
    bool expandedLabel = false,
  }) {
    return OutlinedButton.icon(
      key: ValueKey<String>('people-profile-${person.id}'),
      onPressed: () => _openPersonProfile(person),
      style: OutlinedButton.styleFrom(
        foregroundColor: context.appText,
        backgroundColor: context.appSurfaceLow.withValues(alpha: .72),
        side: BorderSide(color: context.appBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.person_outline_rounded, size: 17),
      label: Text(
        expandedLabel ? 'View profile' : 'Profile',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Feed
  // ---------------------------------------------------------------------------

  Widget _feed(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontalFor(context),
        10,
        AppSpacing.pageHorizontalFor(context),
        115,
      ),
      children: [
        _contentWidth(
          LayoutBuilder(
            builder: (_, constraints) {
              if (constraints.maxWidth < _feedTwoColumnBreakpoint) {
                return _compactFeed(context);
              }

              return Row(
                key: const ValueKey<String>('community-tablet-layout'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 290, child: _feedControls(context)),
                  const SizedBox(width: 20),
                  Expanded(child: _feedPosts(context)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _compactFeed(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controller.errorMessage.value != null) ...[
          _feedErrorBanner(context, controller.errorMessage.value!),
          const SizedBox(height: 10),
        ],
        _feedControls(context),
        const SizedBox(height: 12),
        _feedPosts(context, showError: false),
      ],
    );
  }

  Widget _feedControls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommunityComposerCard(
          onTap: _showCreatePost,
          authorAvatarUrl:
              controller.authenticatedUser.value?.profileImageUrl ?? '',
        ),
        const SizedBox(height: 10),
        _feedFilters(context),
      ],
    );
  }

  Widget _feedFilters(BuildContext context) {
    const labels = ['For You', 'Following', 'Latest'];
    const icons = [
      Icons.auto_awesome_rounded,
      Icons.people_outline_rounded,
      Icons.schedule_rounded,
    ];

    return Obx(() {
      final selectedFilter = controller.feedFilter.value;

      return Container(
        // Keep every segment at least 48 px high so it is comfortable to tap
        // on a phone, including around the label and icon.
        height: 52,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: context.appSurfaceLow.withValues(alpha: .92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appBorder),
        ),
        child: Row(
          children: List.generate(CommunityFeedFilter.values.length, (index) {
            final filter = CommunityFeedFilter.values[index];
            final selected = selectedFilter == filter;
            final borderRadius = BorderRadius.circular(11);

            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: '${labels[index]} feed filter',
                child: Material(
                  color: Colors.transparent,
                  borderRadius: borderRadius,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey<String>(
                      'community-feed-filter-${filter.name}',
                    ),
                    onTap: () => controller.selectFeedFilter(filter),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        // Do not delay the selected state: switching filters
                        // should be visible in the frame immediately after tap.
                        color:
                            selected
                                ? context.appSoftGreen
                                : Colors.transparent,
                        borderRadius: borderRadius,
                        border:
                            selected
                                ? Border.all(
                                  color: green.withValues(alpha: .18),
                                )
                                : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[index],
                            size: 16,
                            color: selected ? green : context.appMutedText,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              labels[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected ? green : context.appMutedText,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  Widget _feedPosts(BuildContext context, {bool showError = true}) {
    return Obx(() {
      final visiblePosts = controller.visiblePosts;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showError && controller.errorMessage.value != null) ...[
            _feedErrorBanner(context, controller.errorMessage.value!),
            const SizedBox(height: 12),
          ],
          if (visiblePosts.isEmpty)
            const CommunityEmptyState(
              icon: Icons.dynamic_feed_outlined,
              title: 'Nothing here yet',
              message: 'Follow more people or try another feed filter.',
            )
          else
            ...visiblePosts.map(_postCard),
        ],
      );
    });
  }

  Widget _feedErrorBanner(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFDAD4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFD85245),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF78453F),
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ),
          TextButton(onPressed: controller.reload, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _postCard(CommunityPost post) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ProfilePostCard(
        post: post,
        onAuthorTap: () => _openAuthorProfile(post),
        onLike: () => controller.togglePostLike(post),
        onComment: () => _showComments(post),
        onShare: () => _showShareOptions(post),
        onOptions: () => _showPostOptions(post),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Post actions
  // ---------------------------------------------------------------------------

  void _openAuthorProfile(CommunityPost post) {
    final currentUserId = controller.authenticatedUser.value?.id;

    if (post.authorId <= 0) return;

    if (post.authorId == currentUserId) {
      Get.toNamed<void>(
        AppRoutes.profile,
        arguments: controller.authenticatedUser.value,
      );
      return;
    }

    Get.toNamed<void>(
      AppRoutes.communityPersonProfilePath(post.authorId),
      arguments: post,
    );
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
                    _CommunityPostAction.viewDetails,
                    'View details',
                    Icons.article_outlined,
                  ),
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
                    _CommunityPostAction.viewDetails,
                    'View details',
                    Icons.article_outlined,
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

    if (action != null) {
      await _handlePostOption(action, post);
    }
  }

  Future<void> _handlePostOption(
    _CommunityPostAction action,
    CommunityPost post,
  ) async {
    switch (action) {
      case _CommunityPostAction.edit:
        await _showEditPost(post);
        return;

      case _CommunityPostAction.delete:
        await _confirmDeletePost(post);
        return;

      case _CommunityPostAction.report:
        await Get.to<void>(
          () => CommunityReportPage(postId: post.id, subject: 'post'),
        );
        return;

      case _CommunityPostAction.viewDetails:
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

  Future<void> _confirmDeletePost(CommunityPost post) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete this post?'),
        content: const Text(
          'This will remove the post from Community. '
          'You cannot undo this action.',
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
    final canShare =
        post.sharedPost != null ||
        post.visibility == CommunityPostVisibility.public;

    if (!canShare) {
      unawaited(
        AppAlert.error(
          title: 'Cannot share this post',
          message: 'Only public posts can be shared to your feed.',
        ),
      );
      return;
    }

    final user = controller.authenticatedUser.value;

    await showCommunityShareComposer(
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

  // ---------------------------------------------------------------------------
  // People helpers
  // ---------------------------------------------------------------------------

  String _resultLabel(FriendsView view) =>
      const ['friends', 'followers', 'people you follow', 'people'][view.index];

  IconData _viewIcon(FriendsView view) =>
      const [
        Icons.people_alt_rounded,
        Icons.person_add_alt_1_rounded,
        Icons.favorite_rounded,
        Icons.explore_rounded,
      ][view.index];

  String _emptyTitle(FriendsView view) =>
      const [
        'No friends yet',
        'No followers yet',
        'You are not following anyone',
        'No suggestions right now',
      ][view.index];

  String _emptyMessage(FriendsView view) =>
      const [
        'Discover people and follow each other to become friends.',
        'Share useful posts to help more people find you.',
        'Discover people whose wellness journey inspires you.',
        'Pull to refresh and check again soon.',
      ][view.index];

  String _effectiveConnectionStatus(CommunityPerson person) {
    final local = controller.connectionStatuses[person.id]?.toUpperCase();

    if (local == 'FOLLOWING') return 'FOLLOWING';
    if (local == 'FOLLOW') return 'NONE';

    return person.connectionStatus.toUpperCase();
  }

  String _initials(String name) {
    final parts =
        name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .toList();

    if (parts.isEmpty) return 'NH';

    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  void _openPersonProfile(CommunityPerson person) {
    final userId = int.tryParse(person.id);

    if (userId == null || userId <= 0) return;

    Get.toNamed<void>(AppRoutes.communityPersonProfilePath(userId));
  }

  // ---------------------------------------------------------------------------
  // Bottom navigation
  // ---------------------------------------------------------------------------

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

class _PeopleSearchField extends StatefulWidget {
  const _PeopleSearchField({
    required this.hintText,
    required this.onChanged,
    super.key,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  State<_PeopleSearchField> createState() => _PeopleSearchFieldState();
}

class _PeopleSearchFieldState extends State<_PeopleSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey<String>('people-search-field'),
      controller: _controller,
      onChanged: (value) {
        widget.onChanged(value);
        setState(() {});
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: context.appMutedText, fontSize: 13),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: CommunityPage.green,
          size: 21,
        ),
        suffixIcon:
            _controller.text.isEmpty
                ? null
                : IconButton(
                  key: const ValueKey<String>('people-search-clear'),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: context.appMutedText,
                  ),
                ),
        filled: true,
        fillColor: context.appSurfaceLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.appBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CommunityPage.green, width: 1.4),
        ),
      ),
    );
  }
}

enum _CommunityPostAction { viewDetails, edit, delete, report }

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
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
        decoration: BoxDecoration(
          color: context.appSurfaceLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 38,
                decoration: BoxDecoration(
                  color: context.appMutedText.withValues(alpha: .35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: context.appMutedSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.appBorder),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    _OptionTile(option: actions[index]),
                    if (index < actions.length - 1)
                      Divider(height: 1, indent: 58, color: context.appBorder),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.option});

  final _CommunityOption option;

  @override
  Widget build(BuildContext context) {
    final color =
        option.isDestructive ? const Color(0xFFD94545) : context.appText;

    return ListTile(
      onTap: () => Get.back(result: option.value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Icon(option.icon, color: color, size: 24),
      title: Text(
        option.label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
