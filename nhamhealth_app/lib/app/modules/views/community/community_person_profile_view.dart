import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/community/community_controller.dart';
import '../../models/community/community_person_profile.dart';
import '../../repositories/community/community_repository.dart';
import '../profile/widgets/profile_post_card.dart';
import 'community_comments_page.dart';
import 'community_report_page.dart';
import 'community_share_actions.dart';
import 'widgets/post_likers_sheet.dart';

/// Read-only public profile for a community member.
class CommunityPersonProfileView extends StatefulWidget {
  const CommunityPersonProfileView({super.key});

  @override
  State<CommunityPersonProfileView> createState() =>
      _CommunityPersonProfileViewState();
}

enum _ProfileContentTab { all, photos }

class _CommunityPersonProfileViewState
    extends State<CommunityPersonProfileView> {
  final CommunityRepository _repository = Get.find<CommunityRepository>();
  CommunityPersonProfile? _profile;
  List<CommunityPost> _posts = const [];
  String? _error;
  bool _isLoading = true;
  bool _isUpdatingFollow = false;
  _ProfileContentTab _selectedTab = _ProfileContentTab.all;
  final Set<String> _likingPostIds = <String>{};

  List<_PersonProfilePhoto> get _photos {
    final seen = <String>{};
    final photos = <_PersonProfilePhoto>[];
    for (final post in _posts) {
      final urls =
          post.imageUrls.isNotEmpty
              ? post.imageUrls
              : post.imageUrl.isEmpty
              ? const <String>[]
              : <String>[post.imageUrl];
      for (final value in urls) {
        final url = _resolvePhotoUrl(value);
        if (url.isNotEmpty && seen.add(url)) {
          photos.add(_PersonProfilePhoto(url: url, post: post));
        }
      }
    }
    return photos;
  }

  String _resolvePhotoUrl(String value) {
    final path = value.trim();
    if (path.isEmpty ||
        path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }
    return '${ApiConfig.baseUrl}${path.startsWith('/') ? '' : '/'}$path';
  }

  int get _userId {
    final arguments = Get.arguments;
    if (arguments is CommunityPost && arguments.authorId > 0) {
      return arguments.authorId;
    }
    return int.tryParse(Get.parameters['userId'] ?? '') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_userId <= 0) {
      setState(() {
        _isLoading = false;
        _error = 'This profile is unavailable.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        _repository.getPersonProfile(_userId),
        _repository.getPersonPosts(_userId),
      ]);
      if (!mounted) return;
      final profile = results[0] as CommunityPersonProfile;
      setState(() {
        _profile = profile;
        _posts = results[1] as List<CommunityPost>;
        _isLoading = false;
      });
      _synchronizeCommunity(profile);
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Unable to load this profile. Pull down to try again.';
      });
    }
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null || _isUpdatingFollow) return;
    if (profile.isFollowing) {
      final confirmed = await AppAlert.confirmAction(
        context: context,
        title: 'community.unfollow_member_question',
        message: 'community.unfollow_member_warning'.trParams({
          'name': profile.name,
        }),
        confirmText: 'community.unfollow',
        cancelText: 'common.cancel',
        icon: Icons.person_remove_rounded,
        confirmButtonColor: const Color(0xFF278A3A),
      );
      if (confirmed != true || !mounted) return;
    }
    final wasFollowing = profile.isFollowing;
    final optimisticFollowing = !wasFollowing;
    final followsViewer = wasFollowing ? false : profile.followsViewer;
    final optimisticStatus = CommunityConnectionStatus.fromDirections(
      isFollowing: optimisticFollowing,
      followsViewer: followsViewer,
    );
    setState(() {
      _isUpdatingFollow = true;
      _profile = _withConnectionState(profile, optimisticStatus);
    });
    try {
      var status = CommunityConnectionStatus.fromApi(
        await _repository.toggleFollow('${profile.id}'),
      );
      // Keep compatibility with API versions that only return FOLLOWING/NONE.
      if (status.isFollowing && profile.followsViewer && !status.followsViewer) {
        status = CommunityConnectionStatus.fromDirections(
          isFollowing: status.isFollowing,
          followsViewer: true,
        );
      }
      if (!mounted) return;
      final updated = _withConnectionState(profile, status);
      setState(() {
        _profile = updated;
        _isUpdatingFollow = false;
      });
      _synchronizeCommunity(updated, refreshPeople: true);
      if (wasFollowing && mounted) {
        AppAlert.toast(
          context: context,
          message: 'community.unfollowed_success'.trParams({
            'name': profile.name,
          }),
        );
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isUpdatingFollow = false;
      });
      unawaited(
        AppAlert.error(
          title: 'community.could_not_update_follow',
          message: error.toString(),
        ),
      );
    }
  }

  CommunityPersonProfile _withConnectionState(
    CommunityPersonProfile profile,
    CommunityConnectionStatus status,
  ) {
    final followerDelta = switch ((profile.isFollowing, status.isFollowing)) {
      (false, true) => 1,
      (true, false) => -1,
      _ => 0,
    };
    return CommunityPersonProfile(
      id: profile.id,
      name: profile.name,
      avatarUrl: profile.avatarUrl,
      role: profile.role,
      headline: profile.headline,
      joinedLabel: profile.joinedLabel,
      verified: profile.verified,
      posts: profile.posts,
      followers: (profile.followers + followerDelta).clamp(0, 1 << 31),
      following: profile.following,
      isFollowing: status.isFollowing,
      followsViewer: status.followsViewer,
    );
  }

  void _synchronizeCommunity(
    CommunityPersonProfile profile, {
    bool refreshPeople = false,
  }) {
    if (!Get.isRegistered<CommunityController>()) return;
    final controller = Get.find<CommunityController>();
    controller.synchronizeFollowState(
      userId: profile.id,
      isFollowing: profile.isFollowing,
      followsViewer: profile.followsViewer,
    );
    if (refreshPeople) unawaited(controller.refreshPeople());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    body: AppBackground(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: const Color(0xFF319B47),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: Column(
                    children: [
                      _profileHero(context),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: PageSkeleton.profile(),
                        )
                      else if (_error != null)
                        _ProfileMessage(
                          message: _error!,
                          actionLabel: 'common.retry',
                          onTap: _loadProfile,
                        )
                      else if (_profile != null) ...[
                        _profileOverview(context, _profile!),
                        const SizedBox(height: 24),
                        _contentTabs(context),
                        const SizedBox(height: 12),
                        if (_selectedTab == _ProfileContentTab.all)
                          _postGrid(context)
                        else
                          _photoGrid(context),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _profileHero(BuildContext context) => SizedBox(
    height: 64,
    child: Stack(
      children: [
        Positioned(
          top: 10,
          left: 16,
          child: IconButton(
            tooltip: 'common.back'.tr,
            onPressed: Get.back,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
        ),
        Positioned(top: 10, right: 20, child: _profileMenuButton(context)),
      ],
    ),
  );

  Widget _profileOverview(
    BuildContext context,
    CommunityPersonProfile profile,
  ) => Container(
    key: const ValueKey<String>('other-profile-card'),
    margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
    decoration: BoxDecoration(
      color: context.appElevatedSurface.withValues(alpha: .95),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.appBorder.withValues(alpha: .7)),
      boxShadow: context.appTileShadow,
    ),
    child: Column(
      children: [
        _identity(context, profile),
        const SizedBox(height: 16),
        _stats(context, profile),
        if (profile.headline.isNotEmpty) ...[
          const SizedBox(height: 14),
          _headline(context, profile.headline),
        ],
      ],
    ),
  );

  Widget _profileMenuButton(BuildContext context) {
    return Material(
      color: context.appElevatedSurface.withValues(alpha: .94),
      shape: const CircleBorder(),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: .12),
      child: IconButton(
        tooltip: 'common.more_options'.tr,
        onPressed: () => _showProfileOptions(context),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 44, height: 44),
        icon: Icon(
          Icons.more_horiz_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
      ),
    );
  }

  Widget _profileAvatar(BuildContext context, CommunityPersonProfile profile) =>
      Semantics(
        button: profile.avatarUrl.isNotEmpty,
        label:
            profile.avatarUrl.isEmpty
                ? 'profile.photo_with_name'.trParams({'name': profile.name})
                : 'profile.view_full_photo_with_name'.trParams({
                  'name': profile.name,
                }),
        child: GestureDetector(
          key: const ValueKey<String>('other-profile-avatar'),
          behavior: HitTestBehavior.opaque,
          onTap:
              profile.avatarUrl.isEmpty
                  ? null
                  : () => _openProfileImage(profile),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: context.appElevatedSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00A85A).withValues(alpha: .5),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: context.appSoftGreen,
              foregroundImage:
                  profile.avatarUrl.isEmpty
                      ? null
                      : CachedNetworkImageProvider(profile.avatarUrl),
              child: Text(
                _initials(profile.name),
                style: TextStyle(
                  color:
                      context.appIsDark
                          ? context.appColorScheme.primary
                          : const Color(0xFF008C4B),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _identity(BuildContext context, CommunityPersonProfile profile) =>
      Container(
        key: const ValueKey<String>('other-profile-identity'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileAvatar(context, profile),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.appText,
                            fontSize: 18,
                            letterSpacing: -.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _followButton(context, profile),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.appSoftGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          color:
                              context.appIsDark
                                  ? context.appColorScheme.primary
                                  : const Color(0xFF178B4B),
                          size: 12,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _roleLabel(profile.role),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  context.appIsDark
                                      ? context.appColorScheme.primary
                                      : const Color(0xFF178B4B),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profile.joinedLabel.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: context.appMutedText,
                          size: 12,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _joinedLabel(profile.joinedLabel),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.appMutedText,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  String _joinedLabel(String date) {
    final joined = 'community.joined'.trParams({'date': date});
    if (joined != 'community.joined') return joined;
    return 'community.member_since'.trParams({'date': date});
  }

  String _roleLabel(String role) {
    final value = role.trim();
    if (value.isEmpty || value.toUpperCase() == 'USER') {
      return 'community.member'.tr;
    }
    return value
        .toLowerCase()
        .split(RegExp(r'[_\s]+'))
        .map(
          (word) =>
              word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  Widget _stats(BuildContext context, CommunityPersonProfile profile) =>
      Container(
        key: const ValueKey<String>('other-profile-stats'),
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            _stat(
              context,
              Icons.article_outlined,
              _formatCount(profile.posts),
              'common.posts'.tr,
            ),
            _divider(context),
            _stat(
              context,
              Icons.group_outlined,
              _formatCount(profile.followers),
              'community.followers'.tr,
            ),
            _divider(context),
            _stat(
              context,
              Icons.person_outline_rounded,
              _formatCount(profile.following),
              'community.following'.tr,
            ),
          ],
        ),
      );

  Widget _stat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) => Expanded(
    child: Semantics(
      label: '$value $label',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.appSoftGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color:
                  context.appIsDark
                      ? context.appColorScheme.primary
                      : const Color(0xFF009B46),
              size: 19,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _divider(BuildContext context) => Container(
    width: 1,
    height: 30,
    color: context.appBorder.withValues(alpha: .6),
  );

  Widget _followButton(BuildContext context, CommunityPersonProfile profile) {
    final status = profile.connection;
    final labelKey = switch (status) {
      CommunityConnectionStatus.friend => 'community.friend',
      CommunityConnectionStatus.following => 'community.following',
      CommunityConnectionStatus.followsYou => 'community.follow_back',
      CommunityConnectionStatus.none => 'community.follow',
    };
    final isFollowing = status.isFollowing;
    final themeGreen =
        context.appIsDark
            ? context.appColorScheme.primary
            : const Color(0xFF178B4B);
    return SizedBox(
      height: 28,
      child: Material(
        key: const ValueKey<String>('other-profile-follow-button'),
        color: isFollowing ? context.appSoftGreen : const Color(0xFF009B55),
        shape: StadiumBorder(
          side:
              isFollowing
                  ? BorderSide(color: themeGreen.withValues(alpha: .25))
                  : BorderSide.none,
        ),
        child: InkWell(
          onTap: _isUpdatingFollow ? null : _toggleFollow,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isUpdatingFollow)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: isFollowing ? themeGreen : Colors.white,
                    ),
                  )
                else ...[
                  Icon(
                    isFollowing
                        ? Icons.check_rounded
                        : Icons.person_add_alt_1_rounded,
                    size: 13,
                    color: isFollowing ? themeGreen : Colors.white,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    labelKey.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isFollowing ? themeGreen : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _headline(BuildContext context, String headline) => Container(
    key: const ValueKey<String>('other-profile-headline'),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: context.appSoftGreen.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Text(
          'â€œ',
          style: TextStyle(
            color:
                context.appIsDark
                    ? context.appColorScheme.primary
                    : const Color(0xFF178B4B),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            headline,
            style: TextStyle(
              color: context.appText,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.eco_rounded,
          color:
              context.appIsDark
                  ? context.appColorScheme.primary.withValues(alpha: .35)
                  : const Color(0xFF178B4B).withValues(alpha: .35),
          size: 24,
        ),
      ],
    ),
  );

  Widget _contentTabs(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
            key: const ValueKey<String>('profile-tab-all'),
            label: 'common.all'.tr,
            icon: Icons.grid_view_rounded,
            selected: _selectedTab == _ProfileContentTab.all,
            onTap: () => setState(() => _selectedTab = _ProfileContentTab.all),
          ),
        ),
        Expanded(
          child: _ProfileTabButton(
            key: const ValueKey<String>('profile-tab-photos'),
            label: 'profile.photos'.tr,
            icon: Icons.image_outlined,
            selected: _selectedTab == _ProfileContentTab.photos,
            onTap:
                () => setState(() => _selectedTab = _ProfileContentTab.photos),
          ),
        ),
      ],
    ),
  );

  Widget _photoGrid(BuildContext context) {
    final photos = _photos;
    if (photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 42),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 42),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: photos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          final photo = photos[index];
          return Semantics(
            button: true,
            label: 'profile.open_photo_number'.trParams({
              'number': '${index + 1}',
            }),
            child: Material(
              color: context.appMutedSurface,
              borderRadius: BorderRadius.circular(2),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openPostPhoto(photo),
                child: CachedNetworkImage(
                  imageUrl: photo.url,
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
          );
        },
      ),
    );
  }

  void _openPostPhoto(_PersonProfilePhoto photo) {
    final profile = _profile;
    if (profile == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder:
            (_) => _CommunityFullProfileImage(
              imageUrl: photo.url,
              memberName: profile.name,
            ),
      ),
    );
  }

  Widget _postGrid(BuildContext context) {
    if (_posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(36),
        child: Center(child: Text('community.no_visible_posts'.tr)),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 42),
      child: Column(
        children: _posts
            .map(
              (post) {
                final sharedAsPost = post.sharedPost?.toPost();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ProfilePostCard(
                    post: post,
                    authorName: _profile?.name,
                    authorAvatarUrl: _profile?.avatarUrl,
                    membership: _roleLabel(_profile?.role ?? post.role),
                    onLike: () => _togglePostLike(post),
                    onShowLikes:
                        () => showPostLikers(
                          context,
                          post: post,
                          repository: _repository,
                        ),
                    isLiking: _likingPostIds.contains(post.id),
                    onComment: () => _showComments(post),
                    onShare: () => _showShare(post),
                    onOptions: () => _showPostOptions(post),
                    onSharedPostTap:
                        sharedAsPost != null ? () => _showComments(sharedAsPost) : null,
                    onSharedAuthorTap:
                        (sharedAsPost != null && sharedAsPost.authorId > 0)
                            ? () => Get.toNamed<void>(
                                  AppRoutes.communityPersonProfilePath(sharedAsPost.authorId),
                                  arguments: sharedAsPost,
                                )
                            : null,
                    onSharedOptions:
                        sharedAsPost != null ? () => _showPostOptions(sharedAsPost) : null,
                  ),
                );
              },
            )
            .toList(growable: false),
      ),
    );
  }

  Future<void> _togglePostLike(CommunityPost post) async {
    if (_likingPostIds.contains(post.id)) return;
    setState(() => _likingPostIds.add(post.id));
    try {
      final updated = await _repository.toggleLike(post.id);
      if (!mounted) return;
      setState(() {
        final index = _posts.indexWhere((item) => item.id == post.id);
        if (index >= 0) _posts[index] = updated;
        _likingPostIds.remove(post.id);
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _likingPostIds.remove(post.id));
      unawaited(
        AppAlert.error(
          title: 'community.could_not_update_like',
          message: error.toString(),
        ),
      );
    }
  }

  void _openProfileImage(CommunityPersonProfile profile) {
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        barrierDismissible: true,
        barrierLabel: 'profile.close_photo'.tr,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder:
            (_, animation, _) => FadeTransition(
              opacity: animation,
              child: _CommunityFullProfileImage(
                imageUrl: profile.avatarUrl,
                memberName: profile.name,
              ),
            ),
      ),
    );
  }

  Future<void> _showComments(CommunityPost post) async {
    await Get.to<void>(
      () => CommunityCommentsPage(
        post: post,
        onPostChanged: () => setState(() {}),
        onShareToFeed:
            (message, visibility) => _repository.sharePostToFeed(
              post.id,
              message: message,
              visibility: visibility,
            ),
      ),
      transition: Transition.rightToLeft,
    );
  }

  Future<void> _showPostOptions(CommunityPost post) async {
    final action = await Get.bottomSheet<String>(
      _PersonPostOptionsSheet(post: post),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
    if (!mounted || action == null) return;
    if (action == 'save') {
      await _togglePostSaved(post);
      return;
    }
    if (action == 'details') {
      _openPost(post);
      return;
    }
    if (action == 'report') {
      await Get.to<void>(
        () => CommunityReportPage(postId: post.id, subject: 'post'),
        transition: Transition.rightToLeft,
      );
    }
  }

  Future<void> _togglePostSaved(CommunityPost post) async {
    final currentUserId = Get.isRegistered<CommunityController>()
        ? Get.find<CommunityController>().authenticatedUser.value?.id
        : null;
    if (currentUserId != null && post.authorId == currentUserId) {
      return;
    }
    final recipeId = post.mealId;
    if (recipeId == null) {
      Get.snackbar(
        'common.favorites_unavailable'.tr,
        'This post cannot be saved right now.',
      );
      return;
    }
    try {
      final updated = await _repository.toggleSaved(post.id, recipeId: recipeId);
      if (!mounted) return;
      setState(() {
        final index = _posts.indexWhere((item) => item.id == post.id);
        if (index >= 0) _posts[index] = updated;
      });
      if (Get.isRegistered<CommunityController>()) {
        final community = Get.find<CommunityController>();
        final idx = community.posts.indexWhere((item) => item.id == post.id);
        if (idx >= 0) {
          community.posts[idx] = updated;
          community.posts.refresh();
        }
      }
    } on Object catch (error) {
      if (!mounted) return;
      unawaited(
        AppAlert.error(
          title: 'common.favorites_unavailable',
          message: error.toString(),
        ),
      );
    }
  }

  Future<void> _showProfileOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
              decoration: BoxDecoration(
                color: sheetContext.appSurfaceLow,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: sheetContext.appMutedText.withValues(alpha: .35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'common.more_options'.tr,
                      style: TextStyle(
                        color: sheetContext.appText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: sheetContext.appMutedSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: sheetContext.appBorder),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            final profile = _profile;
                            if (profile == null) return;
                            Get.to<void>(
                              () => CommunityReportPage(
                                subject: 'profile',
                                profileUserId: profile.id,
                                subjectName: profile.name,
                              ),
                              transition: Transition.rightToLeft,
                            );
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 2,
                          ),
                          leading: const Icon(
                            Icons.flag_outlined,
                            color: Color(0xFFD94545),
                            size: 24,
                          ),
                          title: Text(
                            'community.report_profile'.tr,
                            style: const TextStyle(
                              color: Color(0xFFD94545),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _showShare(CommunityPost post) async {
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
    final user = await Get.find<AuthService>().restoreSession();
    if (!mounted) return;
    await showCommunityShareComposer(
      post: post,
      authorName: user?.displayName ?? 'community.member'.tr,
      authorAvatarUrl: user?.profileImageUrl ?? '',
      onShare:
          (message, visibility) => _repository.sharePostToFeed(
            post.id,
            message: message,
            visibility: visibility,
          ),
    );
  }

  void _openPost(CommunityPost post) {
    final postId = int.tryParse(post.id);
    if (postId != null) Get.toNamed<void>(AppRoutes.communityPostPath(postId));
  }

  String _initials(String name) =>
      name
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .take(2)
          .map((word) => word[0])
          .join()
          .toUpperCase();

  String _formatCount(int value) {
    if (value < 1000) return '$value';
    final abbreviated = value / 1000;
    return '${abbreviated == abbreviated.roundToDouble() ? abbreviated.toInt() : abbreviated.toStringAsFixed(1)}K';
  }
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

class _PersonProfilePhoto {
  const _PersonProfilePhoto({required this.url, required this.post});

  final String url;
  final CommunityPost post;
}

class _PersonPostOptionsSheet extends StatelessWidget {
  const _PersonPostOptionsSheet({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      width: double.infinity,
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
              width: 38,
              height: 4,
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
              'common.more_options'.tr,
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
            child: Builder(
              builder: (context) {
                final currentUserId = Get.isRegistered<CommunityController>()
                    ? Get.find<CommunityController>().authenticatedUser.value?.id
                    : null;
                final isOwner =
                    currentUserId != null && post.authorId == currentUserId;
                return Column(
                  children: [
                    if (!isOwner) ...[
                      _PersonPostOptionTile(
                        icon:
                            post.isSaved
                                ? Icons.bookmark_remove_rounded
                                : Icons.bookmark_add_outlined,
                        label:
                            (post.isSaved
                                    ? 'common.remove_from_favorites'
                                    : 'common.add_to_favorites')
                                .tr,
                        onTap: () => Get.back(result: 'save'),
                      ),
                      Divider(height: 1, indent: 58, color: context.appBorder),
                    ],
                    _PersonPostOptionTile(
                      icon: Icons.flag_outlined,
                      label: 'community.report_post'.tr,
                      destructive: true,
                      onTap: () => Get.back(result: 'report'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _CommunityFullProfileImage extends StatefulWidget {
  const _CommunityFullProfileImage({
    required this.imageUrl,
    required this.memberName,
  });

  final String imageUrl;
  final String memberName;

  @override
  State<_CommunityFullProfileImage> createState() =>
      _CommunityFullProfileImageState();
}

class _CommunityFullProfileImageState
    extends State<_CommunityFullProfileImage> {
  final TransformationController _transformation = TransformationController();

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final current = _transformation.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(.8, 4.0);
    _transformation.value = Matrix4.diagonal3Values(next, next, 1);
  }

  void _resetZoom() => _transformation.value = Matrix4.identity();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformation,
              minScale: .8,
              maxScale: 4,
              panEnabled: true,
              scaleEnabled: true,
              boundaryMargin: const EdgeInsets.all(80),
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl,
                  fit: BoxFit.contain,
                  placeholder:
                      (_, _) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                  errorWidget:
                      (_, _, _) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                          size: 48,
                        ),
                      ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 18,
            right: 68,
            child: Text(
              widget.memberName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 12,
            child: IconButton.filled(
              tooltip: 'common.close'.tr,
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: .55),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 18,
            child: _CommunityZoomControls(
              onZoomIn: () => _zoom(1.35),
              onZoomOut: () => _zoom(1 / 1.35),
              onReset: _resetZoom,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CommunityZoomControls extends StatelessWidget {
  const _CommunityZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: .58),
    borderRadius: BorderRadius.circular(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'community.zoom_in'.tr,
          onPressed: onZoomIn,
          color: Colors.white,
          icon: const Icon(Icons.add_rounded),
        ),
        IconButton(
          tooltip: 'community.reset_zoom'.tr,
          onPressed: onReset,
          color: Colors.white,
          icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
        ),
        IconButton(
          tooltip: 'community.zoom_out'.tr,
          onPressed: onZoomOut,
          color: Colors.white,
          icon: const Icon(Icons.remove_rounded),
        ),
      ],
    ),
  );
}

class _PersonPostOptionTile extends StatelessWidget {
  const _PersonPostOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFD94545) : context.appText;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}


class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({required this.message, this.actionLabel, this.onTap});
  final String message;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.appMutedText),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onTap, child: Text(actionLabel!)),
      ],
    ),
  );
}
