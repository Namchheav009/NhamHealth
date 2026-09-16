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

  static const double _mobileBreakpoint = 720;
  static const double _feedTwoColumnBreakpoint = 820;
  static const double _cardRadius = 18;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      bottomNavigationBar: Obx(() => _communityBottomBar(context)),
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
        controller.isMultiSelectMode.value ? 190 : 115,
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
                _multiSelectControl(context),
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
            label: 'community.mutual_friends'.tr,
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

  Widget _multiSelectControl(BuildContext context) {
    final enabled = controller.isMultiSelectMode.value;
    final help = Text(
      enabled
          ? 'community.selected_count'.trParams({
            'count': '${controller.selectedFriendCount}',
          })
          : 'community.select_multiple_help'.tr,
      style: TextStyle(
        color: context.appMutedText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
    final action = TextButton.icon(
      key: const ValueKey<String>('friend-select-multiple'),
      onPressed:
          controller.submittingFollowConnections.value
              ? null
              : controller.toggleMultiSelectMode,
      icon: Icon(
        enabled ? Icons.close_rounded : Icons.library_add_check_rounded,
        size: 18,
      ),
      label: Text(
        enabled ? 'common.cancel'.tr : 'community.select_multiple'.tr,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    return LayoutBuilder(
      builder: (_, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              help,
              Align(alignment: Alignment.centerRight, child: action),
            ],
          );
        }
        return Row(children: [Expanded(child: help), action]);
      },
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
    final selected = controller.selectedFriendIds.contains(person.id);
    return Container(
      key: ValueKey<String>('people-card-${person.id}'),
      margin: EdgeInsets.only(bottom: addBottomMargin ? 10 : 0),
      decoration: BoxDecoration(
        color: context.appSurfaceLow,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color:
              selected
                  ? green
                  : view == FriendsView.addFriends
                  ? green.withValues(alpha: .20)
                  : context.appBorder,
          width: selected ? 2 : 1,
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
    FriendsView view, {
    bool includeFollowConnection = true,
  }) {
    if (view == FriendsView.addFriends && includeFollowConnection) {
      return Column(
        children: [
          _followConnectionAction(context, person),
          const SizedBox(height: 8),
          _personAction(context, person, view, includeFollowConnection: false),
        ],
      );
    }
    final status = _effectiveConnectionStatus(person);
    final isFriend =
        status == CommunityConnectionStatus.friend ||
        view == FriendsView.friends;
    final isUpdating = controller.updatingConnectionIds.contains(person.id);

    if (isFriend) {
      return SizedBox(
        width: double.infinity,
        height: 40,
        child: _profileButton(context, person, expandedLabel: true),
      );
    }

    final isFollowing = status == CommunityConnectionStatus.following;

    final label =
        isFollowing
            ? 'community.following'.tr
            : view == FriendsView.followers ||
                status == CommunityConnectionStatus.followsYou
            ? 'community.follow_back'.tr
            : 'community.follow'.tr;

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
                label: 'common.following'.tr,
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

  Widget _followConnectionAction(BuildContext context, CommunityPerson person) {
    final status = controller.friendshipStatusFor(person);
    final isUpdating = controller.updatingConnectionIds.contains(person.id);
    final selected = controller.selectedFriendIds.contains(person.id);

    if (status == FriendshipStatus.blocked) return const SizedBox.shrink();
    if (status == FriendshipStatus.incomingPending) {
      return SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: ValueKey<String>('friend-decline-${person.id}'),
                onPressed:
                    isUpdating
                        ? null
                        : () => controller.declineFollowConnection(person),
                child: Text('community.decline'.tr),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                key: ValueKey<String>('friend-accept-${person.id}'),
                onPressed:
                    isUpdating
                        ? null
                        : () => controller.acceptFollowConnection(person),
                style: FilledButton.styleFrom(backgroundColor: green),
                child:
                    isUpdating
                        ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text('community.accept'.tr),
              ),
            ),
          ],
        ),
      );
    }

    final label = switch (status) {
      FriendshipStatus.outgoingPending => 'community.requested'.tr,
      FriendshipStatus.friends => 'community.friends'.tr,
      _ when controller.isMultiSelectMode.value =>
        selected ? 'community.selected'.tr : 'community.select_friend'.tr,
      _ => 'community.add_friend'.tr,
    };
    final enabled =
        status == FriendshipStatus.none &&
        !isUpdating &&
        !controller.submittingFollowConnections.value &&
        !controller.followConnectionCooldownActive;

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        key: ValueKey<String>('friend-action-${person.id}'),
        onPressed:
            !enabled
                ? null
                : controller.isMultiSelectMode.value
                ? () => controller.toggleFriendSelection(person)
                : () async {
                  controller.selectSingleFriend(person);
                  await _confirmAndSendFollowConnections(context);
                },
        style: OutlinedButton.styleFrom(
          foregroundColor: green,
          backgroundColor: selected ? context.appSoftGreen : null,
          side: BorderSide(color: green.withValues(alpha: .42)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(
          status == FriendshipStatus.outgoingPending ||
                  status == FriendshipStatus.friends ||
                  selected
              ? Icons.check_rounded
              : Icons.person_add_alt_1_rounded,
          size: 18,
        ),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
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
        (expandedLabel ? 'community.view_profile' : 'community.profile').tr,
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
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis == Axis.vertical &&
            notification.metrics.extentAfter < 800) {
          unawaited(controller.loadMorePosts());
        }
        return false;
      },
      child: ListView(
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
      ),
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

  Widget _feedIntro(BuildContext context) => SizedBox(
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
  );

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
        height: 42,
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
              final borderRadius = BorderRadius.circular(21);

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
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 17),
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
        child: ProfilePostCard(
          post: post,
          onAuthorTap: () => _openAuthorProfile(post),
          relationshipLabel: _authorRelationshipLabel(post),
          onRelationshipTap: () => _toggleAuthorRelationship(post),
          onViewDetails: () => _showComments(post),
          onLike: () => controller.togglePostLike(post),
          onShowLikes: () => _showPostLikers(post),
          onComment: () => _showComments(post),
          onShare: () => _showShareOptions(post),
          onOptions: () => _showPostOptions(post),
        ),
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
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: Text('community.unfollow'.tr),
          content: Text(
            'community.unfollow_person_question'.trParams({
              'name': post.author,
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('common.cancel'.tr),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: Text('community.unfollow'.tr),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
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

  Widget _communityBottomBar(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.section.value == CommunitySection.people &&
            controller.friendsView.value == FriendsView.addFriends &&
            controller.isMultiSelectMode.value)
          _selectionSubmitBar(context),
        _bottomNav(),
      ],
    );
  }

  Widget _selectionSubmitBar(BuildContext context) {
    final count = controller.selectedFriendCount;
    return SafeArea(
      top: false,
      bottom: false,
      minimum: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontalFor(context),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSpacing.maxWidePaddedContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: FilledButton.icon(
              key: const ValueKey<String>('add-selected-friends'),
              onPressed:
                  count == 0 ||
                          controller.submittingFollowConnections.value ||
                          controller.followConnectionCooldownActive
                      ? null
                      : () => _confirmAndSendFollowConnections(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon:
                  controller.submittingFollowConnections.value
                      ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.group_add_rounded),
              label: Text(
                'community.add_x_friends'.trParams({'count': '$count'}),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndSendFollowConnections(BuildContext context) async {
    final selected = controller.selectedFriends;
    if (selected.isEmpty) return;
    final wasMultiSelect = controller.isMultiSelectMode.value;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: context.appSurfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => FractionallySizedBox(
            heightFactor: .72,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'community.confirm_follow_connections'.tr,
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'community.confirm_follow_connections_help'.trParams({
                      'count': '${selected.length}',
                    }),
                    style: TextStyle(color: sheetContext.appMutedText),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: selected.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final person = selected[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: sheetContext.appSoftGreen,
                            foregroundColor: green,
                            child: Text(_initials(person.displayName)),
                          ),
                          title: Text(
                            person.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle:
                              person.detail?.trim().isNotEmpty == true
                                  ? Text(person.detail!.trim())
                                  : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey<String>(
                            'cancel-follow-connections',
                          ),
                          onPressed:
                              () => Navigator.of(sheetContext).pop(false),
                          child: Text('common.cancel'.tr),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey<String>(
                            'confirm-follow-connections',
                          ),
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          style: FilledButton.styleFrom(backgroundColor: green),
                          child: Text('community.send_requests'.tr),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    if (confirmed != true) {
      if (!wasMultiSelect) controller.selectedFriendIds.clear();
      return;
    }

    final names = {
      for (final person in selected) person.id: person.displayName,
    };
    final summary = await controller.sendSelectedFollowConnections();
    if (!context.mounted) return;
    if (summary.failures.isNotEmpty) {
      await _showFollowConnectionFailures(context, summary, names);
    } else if (summary.successfulIds.isNotEmpty) {
      await AppAlert.actionSuccess(
        title: 'community.requests_sent'.tr,
        message: 'community.requests_sent_count'.trParams({
          'count': '${summary.successfulIds.length}',
        }),
      );
    }
  }

  Future<void> _showFollowConnectionFailures(
    BuildContext context,
    FollowConnectionBatchSummary summary,
    Map<String, String> names,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: context.appSurfaceLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  summary.isPartialSuccess
                      ? 'community.some_requests_failed'.tr
                      : 'community.requests_failed'.tr,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (summary.successfulIds.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'community.requests_sent_count'.trParams({
                      'count': '${summary.successfulIds.length}',
                    }),
                    style: const TextStyle(color: green),
                  ),
                ],
                const SizedBox(height: 12),
                ...summary.failures.entries.map(
                  (failure) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                    ),
                    title: Text(names[failure.key] ?? failure.key),
                    subtitle: Text(failure.value),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: FilledButton.styleFrom(backgroundColor: green),
                  child: Text('common.ok'.tr),
                ),
              ],
            ),
          ),
    );
  }

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
