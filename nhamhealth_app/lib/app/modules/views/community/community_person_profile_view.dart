import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_back_header.dart';
import '../../models/community/community_person_profile.dart';
import '../../models/community/community_post.dart';
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

class _CommunityPersonProfileViewState
    extends State<CommunityPersonProfileView> {
  final CommunityRepository _repository = Get.find<CommunityRepository>();
  CommunityPersonProfile? _profile;
  List<CommunityPost> _posts = const [];
  String? _error;
  bool _isLoading = true;
  bool _isUpdatingFollow = false;
  final Set<String> _likingPostIds = <String>{};

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
      setState(() {
        _profile = results[0] as CommunityPersonProfile;
        _posts = results[1] as List<CommunityPost>;
        _isLoading = false;
      });
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
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Unfollow this member?'),
          content: Text(
            'You will stop seeing posts from ${profile.name} in your following feed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF278A3A),
              ),
              child: const Text('Unfollow'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final optimisticFollowing = !profile.isFollowing;
    setState(() {
      _isUpdatingFollow = true;
      _profile = _withFollowState(profile, optimisticFollowing);
    });
    try {
      final status = await _repository.toggleFollow('${profile.id}');
      if (!mounted) return;
      final isFollowing = status == 'FOLLOWING';
      setState(() {
        _profile = _withFollowState(profile, isFollowing);
        _isUpdatingFollow = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isUpdatingFollow = false;
      });
      unawaited(
        AppAlert.error(
          title: 'Could not update follow',
          message: error.toString(),
        ),
      );
    }
  }

  CommunityPersonProfile _withFollowState(
    CommunityPersonProfile profile,
    bool isFollowing,
  ) => CommunityPersonProfile(
    id: profile.id,
    name: profile.name,
    avatarUrl: profile.avatarUrl,
    role: profile.role,
    headline: profile.headline,
    joinedLabel: profile.joinedLabel,
    verified: profile.verified,
    posts: profile.posts,
    followers: (profile.followers + (isFollowing ? 1 : -1)).clamp(0, 1 << 31),
    following: profile.following,
    isFollowing: isFollowing,
  );

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
                      _topBar(context),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 120),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        _ProfileMessage(
                          message: _error!,
                          actionLabel: 'Retry',
                          onTap: _loadProfile,
                        )
                      else if (_profile != null) ...[
                        _identity(context, _profile!),
                        _stats(context, _profile!),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                          child: _followButton(context, _profile!),
                        ),
                        _postTab(context),
                        _postGrid(context),
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

  Widget _topBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
    child: Row(
      children: [
        AppBackButton(onPressed: Get.back),
        const Spacer(),
        _profileMenuButton(context),
      ],
    ),
  );

  Widget _profileMenuButton(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const shape = CircleBorder();

    return SizedBox.square(
      dimension: AppBackButton.layoutSize,
      child: Padding(
        padding: AppBackButton.outerMargin,
        child: Material(
          color: colors.surface.withValues(alpha: .9),
          shape: shape,
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: .16),
          child: InkWell(
            customBorder: shape,
            onTap: () => _showProfileOptions(context),
            child: Icon(
              Icons.more_horiz_rounded,
              color: colors.primary,
              size: AppBackButton.iconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _identity(BuildContext context, CommunityPersonProfile profile) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        child: Column(
          children: [
            Semantics(
              button: profile.avatarUrl.isNotEmpty,
              label:
                  profile.avatarUrl.isEmpty
                      ? '${profile.name} profile photo'
                      : 'View ${profile.name} full profile photo',
              child: Tooltip(
                message:
                    profile.avatarUrl.isEmpty
                        ? 'Profile photo'
                        : 'View profile photo',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap:
                      profile.avatarUrl.isEmpty
                          ? null
                          : () => _openProfileImage(profile),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00A857),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: context.appSoftGreen,
                      foregroundImage:
                          profile.avatarUrl.isEmpty
                              ? null
                              : CachedNetworkImageProvider(profile.avatarUrl),
                      child: Text(
                        _initials(profile.name),
                        style: const TextStyle(
                          color: Color(0xFF00A857),
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    profile.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 16,
                      letterSpacing: -.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.appSoftGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF329342).withValues(alpha: .12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF329342),
                    size: 13,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      _roleLabel(profile.role),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF329342),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (profile.joinedLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: context.appMutedText,
                    size: 12,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Member since ${profile.joinedLabel}',
                    style: TextStyle(color: context.appMutedText, fontSize: 11),
                  ),
                ],
              ),
            ],
          ],
        ),
      );

  String _roleLabel(String role) {
    final value = role.trim();
    if (value.isEmpty || value.toUpperCase() == 'USER') return 'Member';
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
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: context.appElevatedSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appBorder),
          ),
          child: Row(
            children: [
              _stat(context, _formatCount(profile.posts), 'Posts'),
              _divider(context),
              _stat(context, _formatCount(profile.followers), 'Followers'),
              _divider(context),
              _stat(context, _formatCount(profile.following), 'Following'),
            ],
          ),
        ),
      );

  Widget _stat(BuildContext context, String value, String label) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: context.appText,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(color: context.appMutedText, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _divider(BuildContext context) =>
      Container(width: 1, height: 34, color: context.appBorder);

  Widget _followButton(
    BuildContext context,
    CommunityPersonProfile profile,
  ) => SizedBox(
    width: double.infinity,
    height: 46,
    child: ElevatedButton.icon(
      onPressed: _isUpdatingFollow ? null : _toggleFollow,
      icon:
          _isUpdatingFollow
              ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      profile.isFollowing
                          ? const Color(0xFF278A3A)
                          : Colors.white,
                ),
              )
              : Icon(
                profile.isFollowing
                    ? Icons.check_rounded
                    : Icons.person_add_alt_1_rounded,
              ),
      label: Text(profile.isFollowing ? 'Following' : 'Follow'),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            profile.isFollowing
                ? const Color(0xFFEAF7EB)
                : const Color(0xFF359B46),
        foregroundColor:
            profile.isFollowing ? const Color(0xFF278A3A) : Colors.white,
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _postTab(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
    child: Row(
      children: [
        Text(
          'POSTS',
          style: TextStyle(
            color: context.appText,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: context.appSoftGreen,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '${_posts.length}',
            style: const TextStyle(
              color: Color(0xFF1B9650),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _postGrid(BuildContext context) {
    if (_posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(36),
        child: Center(child: Text('No posts are visible to you yet.')),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 42),
      child: Column(
        children: _posts
            .map(
              (post) => Padding(
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
                ),
              ),
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
          title: 'Could not update like',
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
        barrierLabel: 'Close profile photo',
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
      const _PersonPostOptionsSheet(),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
    if (!mounted || action == null) return;
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
                      'More options',
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
                    child: ListTile(
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
                      title: const Text(
                        'Report profile',
                        style: TextStyle(
                          color: Color(0xFFD94545),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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

  Future<void> _showShare(CommunityPost post) async {
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
    final user = await Get.find<AuthService>().restoreSession();
    if (!mounted) return;
    await showCommunityShareComposer(
      authorName: user?.displayName ?? 'Community member',
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

class _PersonPostOptionsSheet extends StatelessWidget {
  const _PersonPostOptionsSheet();

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
              'More options',
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
                _PersonPostOptionTile(
                  icon: Icons.article_outlined,
                  label: 'View details',
                  onTap: () => Get.back(result: 'details'),
                ),
                Divider(height: 1, indent: 58, color: context.appBorder),
                _PersonPostOptionTile(
                  icon: Icons.flag_outlined,
                  label: 'Report post',
                  destructive: true,
                  onTap: () => Get.back(result: 'report'),
                ),
              ],
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
              tooltip: 'Close',
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
          tooltip: 'Zoom in',
          onPressed: onZoomIn,
          color: Colors.white,
          icon: const Icon(Icons.add_rounded),
        ),
        IconButton(
          tooltip: 'Reset zoom',
          onPressed: onReset,
          color: Colors.white,
          icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
        ),
        IconButton(
          tooltip: 'Zoom out',
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
