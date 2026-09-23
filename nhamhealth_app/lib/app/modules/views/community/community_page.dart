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
import '../../../widgets/post_delete_confirmation.dart';
import '../../../widgets/scroll_aware_scaffold.dart';
import '../../controllers/community/community_controller.dart';
import '../../repositories/community/community_repository.dart';
import '../profile/widgets/profile_post_card.dart';
import 'community_comments_page.dart';
import 'community_post_editor_page.dart';
import 'community_share_actions.dart';
import 'widgets/community_composer_card.dart';
import 'widgets/community_empty_state.dart';
import 'widgets/community_tab_switcher.dart';
import 'widgets/post_likers_sheet.dart';

class CommunityPage extends GetView<CommunityController> {
  const CommunityPage({super.key});

  static const Color green = AppColors.primaryGreen;

  static const double _mobileBreakpoint = 840;
  static const double _feedTwoColumnBreakpoint = 820;
  static const double _cardRadius = 18;

  @override
  Widget build(BuildContext context) {
    return ScrollAwareScaffold(
      backgroundColor: context.appBackground,
      extendBody: true,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Obx(() => _header(context)),
              const SizedBox(height: 8),
              _contentWidth(
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageHorizontalFor(context),
                  ),
                  child: _feedIntro(context),
                ),
              ),
              const SizedBox(height: 10),
              Obx(() => _mainTabs(context)),
              const SizedBox(height: 4),
              Expanded(
                child: Obx(
                  () => LoadingContentTransition(
                    isLoading:
                        controller.isLoading.value &&
                        (controller.posts.isEmpty ||
                            !controller.hasLoaded.value),
                    loading: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontalFor(context),
                        6,
                        AppSpacing.pageHorizontalFor(context),
                        AppSpacing.pagePaddingWithNavigationFor(
                              context,
                            ).bottom +
                            28,
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

  Widget _mainTabs(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontalFor(context),
        ),
        child: CommunityTabSwitcher(
          selected: controller.section.value,
          onChanged: controller.selectSection,
        ),
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

  Widget _singleColumnContent(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSpacing.maxWidePaddedContentWidth,
        ),
        child: child,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // People
  // ---------------------------------------------------------------------------

  Widget _people(BuildContext context) {
    final view = controller.friendsView.value;
    final isDiscover = view == FriendsView.addFriends;
    final bottomPadding =
        AppSpacing.pagePaddingWithNavigationFor(context).bottom + 28;

    return ListView(
      controller: controller.peopleScrollController,
      // ignore: deprecated_member_use
      cacheExtent: 1400,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.normal,
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontalFor(context),
        10,
        AppSpacing.pageHorizontalFor(context),
        bottomPadding,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxWidePaddedContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _peopleSections(context),
                const SizedBox(height: 14),
                _PeopleSearchField(
                  key: ValueKey<String>('people-search-${view.name}'),
                  hintText:
                      isDiscover
                          ? 'community.search_people'.tr
                          : 'community.search_group'.trParams({
                            'group': _resultLabel(view),
                          }),
                  onChanged: controller.updateSearch,
                ),
                if (isDiscover) ...[
                  const SizedBox(height: 10),
                  _peopleFilters(context),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 18),
                _peopleResults(context, view),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _peopleSections(BuildContext context) {
    const labelKeys = [
      'community.friends',
      'community.followers',
      'community.following',
      'community.discover',
    ];
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
        // ignore: deprecated_member_use
        cacheExtent: 600,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.normal,
          ),
        ),
        itemCount: FriendsView.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final section = FriendsView.values[index];
          final selected = controller.friendsView.value == section;

          return Semantics(
            selected: selected,
            button: true,
            label: 'community.people_filter_a11y'.trParams({
              'name': labelKeys[index].tr,
            }),
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
                        labelKeys[index].tr,
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
            label: 'community.everyone'.tr,
            filter: PeopleFilter.all,
          ),
          _peopleFilterOption(
            context: context,
            icon: Icons.people_alt_rounded,
            label: 'community.mutual_connections'.tr,
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
      if (controller.isLoading.value) {
        return const PageSkeleton.communityPeople();
      }
      return CommunityEmptyState(
        icon: hasQuery ? Icons.search_off_rounded : _viewIcon(view),
        title: hasQuery ? 'community.no_matching_people' : _emptyTitle(view),
        message: hasQuery ? 'community.try_another_name' : _emptyMessage(view),
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
        color: context.appSurfaceLow,
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
          padding: const EdgeInsets.all(14),
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
                            person.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.appText,
                            ),
                          ),
                          if (_personSummary(person).isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              _personSummary(person),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: context.appMutedText,
                              ),
                            ),
                          ],
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
        _initials(person.displayName),
        style: const TextStyle(
          color: green,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Semantics(
      image: true,
      label: 'profile.photo_with_name'.trParams({'name': person.displayName}),
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
    final isUpdating = controller.updatingConnectionIds.contains(person.id);
    final isFollowing = status.isFollowing;
    final isFriend = status == CommunityConnectionStatus.friend;
    final isFollowBack =
        !isFollowing &&
        (view == FriendsView.followers ||
            status == CommunityConnectionStatus.followsYou);

    final label =
        isFriend
            ? 'community.friends'.tr
            : isFollowing
            ? 'community.following'.tr
            : isFollowBack
            ? 'community.follow_back'.tr
            : 'community.follow'.tr;

    final icon =
        isFriend
            ? Icons.people_alt_rounded
            : isFollowing
            ? Icons.check_rounded
            : Icons.person_add_alt_1_rounded;

    final followButton =
        isFollowing
            ? OutlinedButton(
              key: ValueKey<String>('people-action-${person.id}'),
              onPressed:
                  isUpdating
                      ? null
                      : () => _confirmUnfollowPerson(context, person, view),
              style: OutlinedButton.styleFrom(
                foregroundColor: isFriend ? const Color(0xFF1B6B2E) : green,
                backgroundColor: context.appSurfaceLow.withValues(alpha: .72),
                side: BorderSide(
                  color: (isFriend ? const Color(0xFF1B6B2E) : green)
                      .withValues(alpha: .34),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _followButtonContent(
                label: label,
                icon: icon,
                isLoading: isUpdating,
                spinnerColor: isFriend ? const Color(0xFF1B6B2E) : green,
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
                icon: icon,
                isLoading: isUpdating,
                spinnerColor: Colors.white,
              ),
            );

    final isFollowerView =
        view == FriendsView.followers && status.followsViewer;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(flex: 4, child: _profileButton(context, person)),
          const SizedBox(width: 8),
          Expanded(flex: 5, child: followButton),
          if (isFollowerView) ...[
            const SizedBox(width: 4),
            IconButton(
              key: ValueKey<String>('remove-follower-${person.id}'),
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: context.appMutedText,
              ),
              tooltip: 'community.remove_follower'.tr,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 40),
              onPressed: () => _confirmRemoveFollower(context, person),
            ),
          ],
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

  Widget _profileButton(BuildContext context, CommunityPerson person) {
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
        'community.profile'.tr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Future<void> _confirmUnfollowPerson(
    BuildContext context,
    CommunityPerson person,
    FriendsView view,
  ) async {
    final confirmed = await AppAlert.confirmAction(
      context: context,
      title: 'community.unfollow_member_question',
      message: 'community.unfollow_member_warning'.trParams({
        'name': person.displayName,
      }),
      confirmText: 'community.unfollow',
      cancelText: 'common.cancel',
      icon: Icons.person_remove_rounded,
      confirmButtonColor: const Color(0xFF278A3A),
    );
    if (confirmed == true) {
      await controller.updateConnection(person, view);
      if (context.mounted) {
        AppAlert.toast(
          context: context,
          message: 'community.unfollowed_success'.trParams({
            'name': person.displayName,
          }),
        );
      }
    }
  }

  Future<void> _confirmRemoveFollower(
    BuildContext context,
    CommunityPerson person,
  ) async {
    final confirmed = await AppAlert.confirmAction(
      context: context,
      title: 'community.remove_follower',
      message: 'community.remove_follower_prompt'.trParams({
        'name': person.displayName,
      }),
      confirmText: 'community.remove_follower',
      cancelText: 'common.cancel',
      icon: Icons.person_remove_rounded,
      confirmButtonColor: Colors.red.shade700,
    );
    if (confirmed == true) {
      await controller.removeFollower(person);
      if (context.mounted) {
        AppAlert.toast(
          context: context,
          message: 'community.follower_removed_success'.trParams({
            'name': person.displayName,
          }),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Feed
  // ---------------------------------------------------------------------------

  Widget _feed(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification &&
            notification.metrics.axis == Axis.vertical &&
            notification.metrics.extentAfter < 800) {
          unawaited(controller.loadMorePosts());
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;
          final isTwoColumn =
              constraints.maxWidth >= _feedTwoColumnBreakpoint && isLandscape;
          final bottomPadding =
              AppSpacing.pagePaddingWithNavigationFor(context).bottom + 28;

          if (!isTwoColumn) {
            return Obx(() {
              final visiblePosts = controller.visiblePosts;
              final error = controller.errorMessage.value;
              final loadingMore = controller.isLoadingMore.value;
              return ListView.builder(
                controller: controller.feedScrollController,
                // ignore: deprecated_member_use
                cacheExtent: 700,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontalFor(context),
                  0,
                  AppSpacing.pageHorizontalFor(context),
                  bottomPadding,
                ),
                itemCount: visiblePosts.length + 1 + (loadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _singleColumnContent(
                      context,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (error != null) ...[
                            _feedErrorBanner(context, error),
                            const SizedBox(height: 10),
                          ],
                          _feedControls(context),
                          const SizedBox(height: 12),
                          if (visiblePosts.isEmpty)
                            const CommunityEmptyState(
                              icon: Icons.dynamic_feed_outlined,
                              title: 'community.empty_feed',
                              message: 'community.empty_feed_help',
                            ),
                        ],
                      ),
                    );
                  }
                  if (index > visiblePosts.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  return _singleColumnContent(
                    context,
                    _postCard(visiblePosts[index - 1], index - 1),
                  );
                },
              );
            });
          }
          return ListView(
            controller: controller.feedScrollController,
            // ignore: deprecated_member_use
            cacheExtent: 1400,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.normal,
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontalFor(context),
              0,
              AppSpacing.pageHorizontalFor(context),
              bottomPadding,
            ),
            children: [
              _contentWidth(
                Row(
                  key: const ValueKey<String>('community-tablet-layout'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 310,
                      child: _feedControls(context, isSidebar: true),
                    ),
                    const SizedBox(width: 20),
                    Expanded(child: _feedPosts(context)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _feedControls(BuildContext context, {bool isSidebar = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommunityComposerCard(
          onTap: _showCreatePost,
          onPhotoTap: () => _showCreatePost(pickPhoto: true),
          authorAvatarUrl:
              controller.authenticatedUser.value?.profileImageUrl ?? '',
        ),
        const SizedBox(height: 10),
        _feedFilters(context),
        if (isSidebar) ...[
          const SizedBox(height: 14),
          _sidebarDiscoverCard(context),
        ],
      ],
    );
  }

  Widget _sidebarDiscoverCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurfaceLow,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.appSoftGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  size: 18,
                  color: green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'community.discover'.tr,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'community.empty_feed_help'.tr,
            style: TextStyle(
              fontSize: 12,
              color: context.appMutedText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  () => controller.selectSection(CommunitySection.people),
              icon: const Icon(Icons.explore_rounded, size: 16),
              label: Text('community.search_people'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: green,
                side: BorderSide(color: green.withValues(alpha: .3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedIntro(BuildContext context) {
    final isTablet = AppSpacing.isTabletFor(context);
    final maxWidth =
        isTablet ? AppSpacing.maxWidePaddedContentWidth : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'common.navigation_community'.tr,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 24,
                  letterSpacing: -.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'community.tagline'.tr,
                style: TextStyle(fontSize: 13, color: context.appMutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedFilters(BuildContext context) {
    const labelKeys = [
      'community.for_you',
      'community.following',
      'community.latest',
    ];
    final colors = Theme.of(context).colorScheme;

    return Obx(() {
      final selectedFilter = controller.feedFilter.value;

      return SizedBox(
        height: 48,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.normal,
            ),
          ),
          child: Row(
            children: List.generate(CommunityFeedFilter.values.length, (index) {
              final filter = CommunityFeedFilter.values[index];
              final selected = selectedFilter == filter;
              final borderRadius = BorderRadius.circular(24);

              return Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: 'community.feed_filter_a11y'.trParams({
                    'name': labelKeys[index].tr,
                  }),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: borderRadius,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey<String>(
                        'community-feed-filter-${filter.name}',
                      ),
                      onTap: () => controller.selectFeedFilter(filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? colors.primaryContainer.withValues(
                                    alpha: .42,
                                  )
                                  : Colors.transparent,
                          borderRadius: borderRadius,
                          border: Border.all(
                            color:
                                selected
                                    ? colors.primary.withValues(alpha: .22)
                                    : colors.outlineVariant,
                          ),
                        ),
                        child: Text(
                          labelKeys[index].tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                selected
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
    });
  }

  Widget _feedPosts(BuildContext context, {bool showError = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showError)
          Obx(() {
            final error = controller.errorMessage.value;
            if (error == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _feedErrorBanner(context, error),
            );
          }),
        Obx(() {
          final visiblePosts = controller.visiblePosts;
          if (visiblePosts.isEmpty) {
            return const CommunityEmptyState(
              icon: Icons.dynamic_feed_outlined,
              title: 'community.empty_feed',
              message: 'community.empty_feed_help',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < visiblePosts.length; i++)
                _postCard(visiblePosts[i], i),
            ],
          );
        }),
        Obx(() {
          if (!controller.isLoadingMore.value) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'community.loading_more_posts'.tr,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.appMutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _feedErrorBanner(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(
          alpha: context.appIsDark ? .38 : .32,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.error.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: colors.error, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
          ),
          TextButton(
            onPressed: controller.reload,
            child: Text('common.retry'.tr),
          ),
        ],
      ),
    );
  }

  Widget _postCard(CommunityPost post, [int? index]) {
    return RepaintBoundary(
      key:
          index != null
              ? ValueKey<String>('community-feed-post-$index-${post.id}')
              : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Obx(() {
          controller.likeUpdates[post.id];
          final current =
              controller.posts.firstWhereOrNull((item) => item.id == post.id) ??
              post;
          final sharedAsPost = current.sharedPost?.toPost();
          return ProfilePostCard(
            post: current,
            onAuthorTap: () => _openAuthorProfile(current),
            relationshipLabel: _authorRelationshipLabel(current),
            onRelationshipTap: () => _toggleAuthorRelationship(current),
            onViewDetails: () => _showComments(current),
            onLike: () => controller.togglePostLike(current),
            onShowLikes: () => _showPostLikers(current),
            onComment: () => _showComments(current),
            onShare: () => _showShareOptions(current),
            onOptions: () => _showPostOptions(current),
            onSharedPostTap:
                sharedAsPost != null ? () => _showComments(sharedAsPost) : null,
            onSharedAuthorTap:
                sharedAsPost != null
                    ? () => _openAuthorProfile(sharedAsPost)
                    : null,
            sharedRelationshipLabel:
                sharedAsPost != null
                    ? _authorRelationshipLabel(sharedAsPost)
                    : null,
            onSharedRelationshipTap:
                sharedAsPost != null
                    ? () => _toggleAuthorRelationship(sharedAsPost)
                    : null,
            onSharedOptions:
                sharedAsPost != null
                    ? () => _showPostOptions(sharedAsPost)
                    : null,
          );
        }),
      ),
    );
  }

  Future<void> _showPostLikers(CommunityPost post) => showPostLikers(
    Get.context!,
    post: post,
    repository: Get.find<CommunityRepository>(),
  );

  String? _authorRelationshipLabel(CommunityPost post) {
    if (post.authorId <= 0) return null;

    final currentUserId = controller.authenticatedUser.value?.id;
    if (currentUserId != null && post.authorId == currentUserId) return null;

    final status = controller.connectionStatusFor(post.authorId);

    if (status == CommunityConnectionStatus.friend) {
      return 'community.friend'.tr;
    }
    if (status == CommunityConnectionStatus.following ||
        (status == null && post.isFollowingAuthor)) {
      return 'community.following'.tr;
    }
    if (status == CommunityConnectionStatus.none ||
        status == CommunityConnectionStatus.followsYou) {
      return 'community.follow'.tr;
    }

    return post.isFollowingAuthor
        ? 'community.following'.tr
        : 'community.follow'.tr;
  }

  Future<void> _toggleAuthorRelationship(CommunityPost post) async {
    if (post.authorId <= 0) return;

    final currentUserId = controller.authenticatedUser.value?.id;
    if (currentUserId != null && post.authorId == currentUserId) return;

    final status = controller.connectionStatusFor(post.authorId);
    final isFollowing = status?.isFollowing ?? post.isFollowingAuthor;

    if (isFollowing) {
      final confirmed = await AppAlert.confirmAction(
        title: 'community.unfollow_member_question',
        message: 'community.unfollow_member_warning'.trParams({
          'name': post.author,
        }),
        confirmText: 'community.unfollow',
        cancelText: 'common.cancel',
        icon: Icons.person_remove_rounded,
        confirmButtonColor: const Color(0xFF278A3A),
      );

      if (confirmed != true) return;
      await controller.togglePostAuthorFollow(post);
      AppAlert.toast(
        message: 'community.unfollowed_success'.trParams({'name': post.author}),
      );
      return;
    }

    await controller.togglePostAuthorFollow(post);
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
        title:
            (isOwner ? 'community.post_options' : 'community.more_options').tr,
        actions:
            isOwner
                ? [
                  _CommunityOption(
                    _CommunityPostAction.save,
                    (post.isSaved
                            ? 'common.remove_from_favorites'
                            : 'common.add_to_favorites')
                        .tr,
                    post.isSaved
                        ? Icons.bookmark_remove_rounded
                        : Icons.bookmark_add_outlined,
                  ),
                  _CommunityOption(
                    _CommunityPostAction.edit,
                    'community.edit_post'.tr,
                    Icons.edit_outlined,
                  ),
                  _CommunityOption(
                    _CommunityPostAction.delete,
                    'community.delete_post'.tr,
                    Icons.delete_outline_rounded,
                    isDestructive: true,
                  ),
                ]
                : [
                  _CommunityOption(
                    _CommunityPostAction.save,
                    (post.isSaved
                            ? 'common.remove_from_favorites'
                            : 'common.add_to_favorites')
                        .tr,
                    post.isSaved
                        ? Icons.bookmark_remove_rounded
                        : Icons.bookmark_add_outlined,
                  ),
                  _CommunityOption(
                    _CommunityPostAction.report,
                    'community.report_post'.tr,
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
      case _CommunityPostAction.save:
        await controller.togglePostSaved(post);
        return;

      case _CommunityPostAction.edit:
        await _showEditPost(post);
        return;

      case _CommunityPostAction.delete:
        await _confirmDeletePost(post);
        return;

      case _CommunityPostAction.report:
        await Get.toNamed<void>(AppRoutes.communityReportPath(post.id));
        return;
    }
  }

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
    final confirmed = await confirmPostDeletion(
      messageKey: 'community.delete_post_warning',
    );

    if (confirmed != true) return;

    try {
      await controller.deletePost(post);
      await AppAlert.actionSuccess(
        title: 'community.post_deleted',
        message: 'community.post_removed',
      );
    } on Object catch (error) {
      await AppAlert.actionError(
        title: 'community.could_not_delete_post',
        message: error.toString(),
      );
    }
  }

  Future<void> _showShareOptions(CommunityPost post) async {
    final canShare =
        post.sharedPost != null ||
        post.visibility == CommunityPostVisibility.public;

    if (!canShare) {
      unawaited(
        AppAlert.error(
          title: 'community.cannot_share_post',
          message: 'community.public_posts_only',
        ),
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

  // ---------------------------------------------------------------------------
  // People helpers
  // ---------------------------------------------------------------------------

  String _resultLabel(FriendsView view) =>
      const [
        'community.friends',
        'community.followers',
        'community.people_you_follow',
        'community.people',
      ][view.index].tr;

  String _personSummary(CommunityPerson person) {
    final details = <String>[];
    final location = person.detail?.trim() ?? '';
    if (location.isNotEmpty && !location.contains('@')) details.add(location);
    if (person.mutualFriends > 0) {
      details.add(
        (person.mutualFriends == 1
                ? 'community.mutual_connection_one'
                : 'community.mutual_connection_many')
            .trParams({'count': '${person.mutualFriends}'}),
      );
    }
    return details.join(' • ');
  }

  IconData _viewIcon(FriendsView view) =>
      const [
        Icons.people_alt_rounded,
        Icons.person_add_alt_1_rounded,
        Icons.favorite_rounded,
        Icons.explore_rounded,
      ][view.index];

  String _emptyTitle(FriendsView view) =>
      const [
        'community.no_friends',
        'community.no_followers',
        'community.not_following_anyone',
        'community.no_suggestions',
      ][view.index];

  String _emptyMessage(FriendsView view) =>
      const [
        'community.no_friends_help',
        'community.no_followers_help',
        'community.not_following_help',
        'community.no_suggestions_help',
      ][view.index];

  CommunityConnectionStatus _effectiveConnectionStatus(
    CommunityPerson person,
  ) =>
      controller.connectionStatusFor(int.tryParse(person.id) ?? -1) ??
      person.connection;

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
        constraints: const BoxConstraints(
          maxWidth: AppSpacing.maxNavigationWidth,
        ),
        child: AppBottomNavigation(
          selectedIndex: 3,
          onSelect: (index) {
            if (index == 0) Get.offNamed<void>(AppRoutes.home);
            if (index == 1) Get.offNamed<void>(AppRoutes.meals);
            if (index == 2) Get.offNamed<void>(AppRoutes.mealPlanner);
            if (index == 3) controller.selectSection(controller.section.value);
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
                  tooltip: 'common.clear_search'.tr,
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
        fillColor: context.appSearchSurface,
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

enum _CommunityPostAction { save, edit, delete, report }

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
            Material(
              color: context.appMutedSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: context.appBorder),
              ),
              clipBehavior: Clip.antiAlias,
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
