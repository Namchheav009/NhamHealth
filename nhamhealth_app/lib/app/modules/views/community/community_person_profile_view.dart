import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../models/community/community_person_profile.dart';
import '../../models/community/community_post.dart';
import '../../repositories/community/community_repository.dart';

/// Read-only public profile for a community member.
class CommunityPersonProfileView extends StatefulWidget {
  const CommunityPersonProfileView({super.key});

  @override
  State<CommunityPersonProfileView> createState() =>
      _CommunityPersonProfileViewState();
}

class _CommunityPersonProfileViewState extends State<CommunityPersonProfileView> {
  final CommunityRepository _repository = Get.find<CommunityRepository>();
  CommunityPersonProfile? _profile;
  List<CommunityPost> _posts = const [];
  String? _error;
  bool _isLoading = true;
  bool _isUpdatingFollow = false;

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
    setState(() => _isUpdatingFollow = true);
    try {
      final status = await _repository.toggleFollow('${profile.id}');
      if (!mounted) return;
      final isFollowing = status == 'FOLLOWING';
      setState(() {
        _profile = CommunityPersonProfile(
          id: profile.id,
          name: profile.name,
          avatarUrl: profile.avatarUrl,
          role: profile.role,
          headline: profile.headline,
          joinedLabel: profile.joinedLabel,
          verified: profile.verified,
          posts: profile.posts,
          followers: profile.followers + (isFollowing ? 1 : -1),
          following: profile.following,
          isFollowing: isFollowing,
        );
        _isUpdatingFollow = false;
      });
    } on Object {
      if (mounted) setState(() => _isUpdatingFollow = false);
    }
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
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
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
        _roundButton(context, Icons.arrow_back_ios_new_rounded, Get.back),
        Expanded(
          child: Text(
            'PROFILE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: .3,
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Profile options',
          onSelected: (_) {},
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'report', child: Text('Report profile')),
          ],
          child: _roundButton(context, Icons.more_horiz_rounded, null),
        ),
      ],
    ),
  );

  Widget _roundButton(BuildContext context, IconData icon, VoidCallback? onTap) =>
      Material(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: const Color(0xFF102342), size: 22),
          ),
        ),
      );

  Widget _identity(BuildContext context, CommunityPersonProfile profile) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFF00A857),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 39,
                backgroundColor: context.appSoftGreen,
                foregroundImage: profile.avatarUrl.isEmpty
                    ? null
                    : NetworkImage(profile.avatarUrl),
                child: Text(
                  _initials(profile.name),
                  style: const TextStyle(
                    color: Color(0xFF00A857),
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (profile.verified) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF45A654),
                    size: 17,
                  ),
                ],
              ],
            ),
            if (profile.joinedLabel.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                'Joined ${profile.joinedLabel}',
                style: TextStyle(color: context.appMutedText, fontSize: 10),
              ),
            ],
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7EB),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.eco_outlined,
                    color: Color(0xFF329342),
                    size: 13,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      profile.role.toUpperCase(),
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
          ],
        ),
      );

  Widget _stats(BuildContext context, CommunityPersonProfile profile) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: context.appMutedText, fontSize: 13)),
      ],
    ),
  );

  Widget _divider(BuildContext context) =>
      Container(width: 1, height: 42, color: context.appBorder);

  Widget _followButton(BuildContext context, CommunityPersonProfile profile) =>
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isUpdatingFollow ? null : _toggleFollow,
          icon: _isUpdatingFollow
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  profile.isFollowing
                      ? Icons.check_rounded
                      : Icons.person_add_alt_1_rounded,
                ),
          label: Text(profile.isFollowing ? 'Following' : 'Follow'),
          style: ElevatedButton.styleFrom(
            backgroundColor: profile.isFollowing
                ? const Color(0xFFEAF7EB)
                : const Color(0xFF359B46),
            foregroundColor: profile.isFollowing
                ? const Color(0xFF278A3A)
                : Colors.white,
            elevation: 0,
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
                child: _PostTile(post: post, onTap: () => _openPost(post)),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  void _openPost(CommunityPost post) {
    final postId = int.tryParse(post.id);
    if (postId != null) Get.toNamed<void>(AppRoutes.communityPostPath(postId));
  }

  String _initials(String name) => name
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

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post, required this.onTap});
  final CommunityPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = post.imageUrls.isNotEmpty
        ? post.imageUrls.first
        : post.imageUrl;
    return Material(
      color: context.appElevatedSurface,
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1.78,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isEmpty
                      ? ColoredBox(
                          color: context.appSoftGreen,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_outlined,
                                color: Color(0xFF5AC98D),
                                size: 30,
                              ),
                              SizedBox(height: 5),
                              Text(
                                'No image',
                                style: TextStyle(
                                  color: Color(0xFF5AC98D),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              ColoredBox(color: context.appSoftGreen),
                        ),
                  if (post.imageUrls.length > 1)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _imageCount(post.imageUrls.length),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: Row(
                children: [
                  _metric(context, Icons.favorite_border_rounded, post.likes),
                  const SizedBox(width: 14),
                  _metric(
                    context,
                    Icons.chat_bubble_outline_rounded,
                    post.comments,
                  ),
                  const Spacer(),
                  Text(
                    post.ageLabel,
                    style: TextStyle(color: context.appMutedText, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageCount(int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.photo_library_outlined,
          size: 13,
          color: Colors.white,
        ),
        const SizedBox(width: 3),
        Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    ),
  );

  Widget _metric(BuildContext context, IconData icon, int count) => Row(
    children: [
      Icon(icon, size: 16, color: context.appMutedText),
      const SizedBox(width: 4),
      Text('$count', style: TextStyle(color: context.appMutedText, fontSize: 12)),
    ],
  );
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
