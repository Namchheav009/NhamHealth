import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_realtime_event.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/post_delete_confirmation.dart';
import '../../controllers/community/community_controller.dart';
import '../../models/community/community_comment.dart';
import '../../models/community/community_post_draft.dart';
import '../../models/community/community_reply_address.dart';
import '../../repositories/community/community_repository.dart';
import '../profile/widgets/profile_post_card.dart';
import 'community_post_editor_page.dart';
import 'community_report_page.dart';
import 'community_share_actions.dart';
import 'widgets/community_shared_post_card.dart';
import 'widgets/post_likers_sheet.dart';

/// A full post discussion screen. Replies are displayed below their parent and
/// the composer switches context when a user chooses Reply.
class CommunityCommentsPage extends StatefulWidget {
  const CommunityCommentsPage({
    required this.post,
    this.onPostChanged,
    this.canEdit = false,
    this.onEditPost,
    this.onShareToFeed,
    this.titleKey = 'community.comments',
    super.key,
  });

  final CommunityPost post;
  final VoidCallback? onPostChanged;
  final bool canEdit;
  final String titleKey;
  final Future<CommunityPost> Function(CommunityPostDraft draft)? onEditPost;
  final Future<void> Function(
    String message,
    CommunityPostVisibility visibility,
  )?
  onShareToFeed;

  @override
  State<CommunityCommentsPage> createState() => _CommunityCommentsPageState();
}

class _CommunityCommentsPageState extends State<CommunityCommentsPage> {
  static const _green = Color(0xFF08A936);
  final _message = TextEditingController();
  final _composerFocus = FocusNode();
  final _scrollController = ScrollController();
  late final CommunityRepository _repository;
  List<CommunityComment> _comments = const [];
  CommunityComment? _replyingTo;
  bool _loading = true;
  bool _sending = false;
  String? _likingCommentId;
  String? _deletingCommentId;
  bool _updatingPost = false;
  late CommunityPost _post;
  StreamSubscription<NotificationRealtimeEvent>? _realtimeSubscription;
  Timer? _discussionRefreshTimer;
  bool _discussionRefreshInFlight = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post.copyWith();
    _repository = Get.find<CommunityRepository>();
    _loadComments();
    _realtimeSubscription = PushNotificationService.instance?.events.listen(
      _handleRealtimeEvent,
    );
    if (!Get.testMode) {
      _discussionRefreshTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => unawaited(_refreshDiscussion()),
      );
    }
  }

  @override
  void didUpdateWidget(covariant CommunityCommentsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.post, widget.post)) {
      _post = widget.post.copyWith();
    }
  }

  @override
  void dispose() {
    _message.dispose();
    _composerFocus.dispose();
    _scrollController.dispose();
    _realtimeSubscription?.cancel();
    _discussionRefreshTimer?.cancel();
    super.dispose();
  }

  void _handleRealtimeEvent(NotificationRealtimeEvent event) {
    if (event.referenceType != 'POST' ||
        event.referenceId?.toString() != _post.id) {
      return;
    }
    unawaited(_refreshDiscussion());
  }

  Future<void> _refreshDiscussion() async {
    if (_discussionRefreshInFlight) return;
    _discussionRefreshInFlight = true;
    try {
      final results = await Future.wait<dynamic>([
        _repository.getPost(_post.id),
        _repository.getComments(_post.id),
      ]);
      if (!mounted) return;
      setState(() {
        _post = (results[0] as CommunityPost).copyWith();
        _comments = results[1] as List<CommunityComment>;
      });
      widget.onPostChanged?.call();
    } on Object {
      // Keep the current discussion visible if a realtime refresh fails.
    } finally {
      _discussionRefreshInFlight = false;
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _repository.getComments(_post.id);
      if (mounted) setState(() => _comments = comments);
    } on Object catch (error) {
      if (mounted) {
        Get.snackbar('community.could_not_load_comments'.tr, error.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final replyAddress =
        _replyingTo == null
            ? null
            : CommunityReplyAddress.fromComment(_replyingTo!);
    final replyBody =
        replyAddress?.removeFrom(_message.text).trim() ?? _message.text.trim();
    final text = _message.text.trim();
    if (replyBody.isEmpty || _sending || !_post.allowComments) return;
    setState(() => _sending = true);
    try {
      final comment = await _repository.addComment(
        _post.id,
        text,
        parentCommentId: _replyingTo?.id,
      );
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, comment];
        _replyingTo = null;
        _post = _post.copyWith(comments: _post.comments + 1);
      });
      _message.clear();
      widget.onPostChanged?.call();
    } on Object catch (error) {
      if (mounted) {
        Get.snackbar('community.could_not_comment'.tr, error.toString());
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _togglePostLike() async {
    if (_updatingPost) return;
    setState(() => _updatingPost = true);
    try {
      final updated = await _repository.toggleLike(_post.id);
      if (!mounted) return;
      setState(() {
        _post = _post.copyWith(likes: updated.likes, isLiked: updated.isLiked);
      });
      widget.onPostChanged?.call();
    } on Object catch (error) {
      if (mounted) {
        Get.snackbar('community.could_not_update_like'.tr, error.toString());
      }
    } finally {
      if (mounted) setState(() => _updatingPost = false);
    }
  }

  Future<void> _showPostLikers() =>
      showPostLikers(context, post: _post, repository: _repository);

  Future<void> _shareToFeed(
    String message,
    CommunityPostVisibility visibility,
  ) async {
    final share = widget.onShareToFeed;
    if (share == null) {
      await _repository.sharePostToFeed(
        _post.id,
        message: message,
        visibility: visibility,
      );
    } else {
      await share(message, visibility);
    }
    if (!mounted) return;
    setState(() => _post = _post.copyWith(shares: _post.shares + 1));
    widget.onPostChanged?.call();
  }

  Future<void> _showShareOptions() async {
    if (_updatingPost) return;
    final canShare =
        _post.sharedPost != null ||
        _post.visibility == CommunityPostVisibility.public;
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
      post: _post,
      authorName: user?.displayName ?? 'Community member',
      authorAvatarUrl: user?.profileImageUrl ?? '',
      onShare: (message, visibility) async {
        setState(() => _updatingPost = true);
        try {
          await _shareToFeed(message, visibility);
        } finally {
          if (mounted) setState(() => _updatingPost = false);
        }
      },
    );
  }

  Future<void> _toggleCommentLike(CommunityComment comment) async {
    if (_likingCommentId != null) return;
    setState(() => _likingCommentId = comment.id);
    try {
      final updated = await _repository.toggleCommentLike(_post.id, comment.id);
      if (!mounted) return;
      setState(() {
        _comments = _comments
            .map((item) => item.id == updated.id ? updated : item)
            .toList(growable: false);
      });
    } on Object catch (error) {
      if (mounted) {
        Get.snackbar('community.could_not_update_like'.tr, error.toString());
      }
    } finally {
      if (mounted) setState(() => _likingCommentId = null);
    }
  }

  Future<void> _showCommentOptions(CommunityComment comment) async {
    final action = await Get.bottomSheet<_DiscussionAction>(
      _CommentOptionsSheet(
        actions: [
          if (_post.allowReplies)
            _CommentOption(
              _DiscussionAction.reply,
              'community.reply'.tr,
              Icons.reply_rounded,
            ),
          if (comment.canDelete)
            _CommentOption(
              _DiscussionAction.delete,
              'community.delete_comment_action'.tr,
              Icons.delete_outline_rounded,
              isDestructive: true,
            )
          else
            _CommentOption(
              _DiscussionAction.report,
              'community.report_comment'.tr,
              Icons.flag_outlined,
              isDestructive: true,
            ),
        ],
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
    if (!mounted || action == null) return;
    if (action == _DiscussionAction.reply) {
      _beginReply(comment);
      return;
    }
    if (action == _DiscussionAction.delete) {
      await _confirmAndDeleteComment(comment);
      return;
    }
    await Get.to<void>(
      () => CommunityReportPage(
        postId: _post.id,
        commentId: comment.id,
        subject: 'comment',
      ),
    );
  }

  Future<void> _confirmAndDeleteComment(CommunityComment comment) async {
    if (_deletingCommentId != null) return;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('community.delete_comment'.tr),
        content: Text(
          'community.this_will_permanently_remove_this_comment_and_any_replies_to_it'
              .tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('common.cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD94545),
            ),
            child: Text('common.delete'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingCommentId = comment.id);
    try {
      await _repository.deleteComment(_post.id, comment.id);
      if (!mounted) return;
      final deletedIds = _commentAndDescendantIds(comment.id);
      var remainingCount = _post.comments - deletedIds.length;
      if (remainingCount < 0) remainingCount = 0;
      setState(() {
        _comments = _comments
            .where((item) => !deletedIds.contains(item.id))
            .toList(growable: false);
        if (_replyingTo != null && deletedIds.contains(_replyingTo!.id)) {
          _replyingTo = null;
          _message.clear();
        }
        _post = _post.copyWith(comments: remainingCount);
      });
      widget.onPostChanged?.call();
      unawaited(
        AppAlert.success(
          title: 'community.comment_deleted',
          message: 'community.comment_removed',
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        unawaited(
          AppAlert.error(
            title: 'community.could_not_delete_comment',
            message: error.toString(),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingCommentId = null);
    }
  }

  Set<String> _commentAndDescendantIds(String commentId) {
    final deletedIds = <String>{commentId};
    var foundDescendant = true;
    while (foundDescendant) {
      foundDescendant = false;
      for (final candidate in _comments) {
        if (candidate.parentCommentId != null &&
            deletedIds.contains(candidate.parentCommentId) &&
            deletedIds.add(candidate.id)) {
          foundDescendant = true;
        }
      }
    }
    return deletedIds;
  }

  Future<void> _showPostOptions() async {
    final currentUserId =
        Get.isRegistered<CommunityController>()
            ? Get.find<CommunityController>().authenticatedUser.value?.id
            : null;
    final isOwner =
        widget.canEdit ||
        (currentUserId != null && _post.authorId == currentUserId);
    final action = await Get.bottomSheet<_DiscussionAction>(
      _CommentOptionsSheet(
        title:
            (isOwner ? 'community.post_options' : 'community.more_options').tr,
        actions:
            isOwner
                ? [
                  if (widget.onEditPost != null)
                    _CommentOption(
                      _DiscussionAction.edit,
                      'community.edit_post'.tr,
                      Icons.edit_outlined,
                    ),
                  _CommentOption(
                    _DiscussionAction.delete,
                    'community.delete_post'.tr,
                    Icons.delete_outline_rounded,
                    isDestructive: true,
                  ),
                ]
                : [
                  _CommentOption(
                    _DiscussionAction.save,
                    (_post.isSaved
                            ? 'common.remove_from_favorites'
                            : 'common.add_to_favorites')
                        .tr,
                    _post.isSaved
                        ? Icons.bookmark_remove_rounded
                        : Icons.bookmark_add_outlined,
                  ),
                  _CommentOption(
                    _DiscussionAction.report,
                    'community.report_post'.tr,
                    Icons.flag_outlined,
                    isDestructive: true,
                  ),
                ],
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
    if (!mounted || action == null) return;
    if (action == _DiscussionAction.save) {
      await _togglePostSaved();
      return;
    }
    if (action == _DiscussionAction.edit) {
      await _editPost();
      return;
    }
    if (action == _DiscussionAction.delete) {
      await _confirmAndDeletePost();
      return;
    }
    if (action == _DiscussionAction.share) {
      await _showShareOptions();
      return;
    }
    await Get.to<void>(
      () => CommunityReportPage(postId: _post.id, subject: 'post'),
    );
  }

  Future<void> _togglePostSaved() async {
    final currentUserId =
        Get.isRegistered<CommunityController>()
            ? Get.find<CommunityController>().authenticatedUser.value?.id
            : null;
    if (widget.canEdit ||
        (currentUserId != null && _post.authorId == currentUserId)) {
      return;
    }
    final recipeId = _post.mealId;
    if (recipeId == null) {
      Get.snackbar(
        'common.favorites_unavailable'.tr,
        'This post cannot be saved right now.',
      );
      return;
    }
    try {
      final updated = await _repository.toggleSaved(
        _post.id,
        recipeId: recipeId,
      );
      if (!mounted) return;
      setState(() => _post = updated.copyWith());
      widget.onPostChanged?.call();
      if (Get.isRegistered<CommunityController>()) {
        final community = Get.find<CommunityController>();
        final idx = community.posts.indexWhere((item) => item.id == _post.id);
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

  Future<void> _confirmAndDeletePost() async {
    if (_updatingPost) return;
    final confirmed = await confirmPostDeletion(
      messageKey: 'community.delete_post_profile_warning',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updatingPost = true);
    try {
      final recipeId = _post.mealId;
      if (recipeId == null) {
        throw CommunityException('community.post_delete_unavailable'.tr);
      }
      await _repository.deletePost(recipeId);
      if (!mounted) return;
      widget.onPostChanged?.call();
      Get.back<void>();
      await Future<void>.delayed(Duration.zero);
      await AppAlert.actionSuccess(
        title: 'community.post_deleted',
        message: 'community.post_removed',
      );
    } on Object catch (error) {
      await AppAlert.actionError(
        title: 'community.could_not_delete_post',
        message: error.toString(),
      );
    } finally {
      if (mounted) setState(() => _updatingPost = false);
    }
  }

  Future<void> _editPost() async {
    final submit = widget.onEditPost;
    if (submit == null) return;

    if (_post.isShare) {
      final user = await Get.find<AuthService>().restoreSession();
      if (!mounted) return;
      await showCommunityShareComposer(
        post: _post,
        authorName: user?.displayName ?? _post.author,
        authorAvatarUrl: user?.profileImageUrl ?? _post.authorAvatarUrl,
        initialMessage: _post.description,
        initialVisibility: _post.visibility,
        isEditing: true,
        submitButtonText: 'common.save'.tr,
        onShare: (message, visibility) async {
          final updated = await _repository.updatePost(
            postId: _post.id,
            mealName: _post.mealName,
            description: message,
            cookingTimeMinutes: _post.cookingTimeMinutes ?? 0,
            servings: _post.servings ?? 0,
            difficulty: _post.difficulty,
            ingredients: _post.ingredients,
            steps: _post.steps,
            visibility: visibility,
            allowComments: _post.allowComments,
            allowReplies: _post.allowReplies,
            tagIds: _post.tagIds,
            categoryId: _post.categoryId,
          );
          if (mounted) setState(() => _post = updated.copyWith());
          widget.onPostChanged?.call();
        },
      );
      return;
    }

    final saved = await Get.to<bool>(
      () => CommunityPostEditorPage(
        post: _post,
        authorName: _post.author,
        authorAvatarUrl: _post.authorAvatarUrl,
        onSubmit: (draft) async {
          final updated = await submit(draft);
          if (mounted) setState(() => _post = updated.copyWith());
        },
      ),
      transition: Transition.rightToLeft,
    );
    if (saved == true && mounted) widget.onPostChanged?.call();
  }

  void _focusComposer() {
    if (!_post.allowComments) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    _composerFocus.requestFocus();
  }

  void _beginReply(CommunityComment comment) {
    if (!_post.allowReplies) return;
    final previousAddress =
        _replyingTo == null
            ? null
            : CommunityReplyAddress.fromComment(_replyingTo!);
    final address = CommunityReplyAddress.fromComment(comment);
    final text = address.applyTo(_message.text, replacing: previousAddress);
    setState(() => _replyingTo = comment);
    _setComposerText(text);
    _focusComposer();
  }

  void _cancelReply() {
    final target = _replyingTo;
    if (target == null) return;
    final text = CommunityReplyAddress.fromComment(
      target,
    ).removeFrom(_message.text);
    setState(() => _replyingTo = null);
    _setComposerText(text);
  }

  void _setComposerText(String text) {
    _message.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    body: AppBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSpacing.maxPaddedContentWidth,
                ),
                child: Padding(
                  padding: AppSpacing.topBarPagePadding,
                  child: AppBackHeader(
                    title: widget.titleKey.tr,
                    onBack: Get.back,
                    backButtonKey: const ValueKey<String>(
                      'comments-back-button',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: _green,
                onRefresh: _loadComments,
                child: ListView(
                  controller: _scrollController,
                  // ignore: deprecated_member_use
                  cacheExtent: 1200,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(
                      decelerationRate: ScrollDecelerationRate.normal,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    4,
                    AppSpacing.pageHorizontal,
                    24,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSpacing.maxContentWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _postSummary(),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Text(
                                  (_post.comments == 1
                                          ? 'community.comment_count_one'
                                          : 'community.comment_count_many')
                                      .trParams({'count': '${_post.comments}'}),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'community.discussion'.tr,
                                  style: TextStyle(
                                    color: _green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_loading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 38),
                                child: Center(
                                  child: SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: _green,
                                    ),
                                  ),
                                ),
                              )
                            else if (_comments.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 38,
                                ),
                                child: Center(
                                  child: Text(
                                    'community.be_the_first_to_comment'.tr,
                                  ),
                                ),
                              )
                            else
                              ..._threadWidgets(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _composer(),
          ],
        ),
      ),
    ),
  );

  Widget _postSummary() => Column(
    children: [
      ProfilePostCard(
        post: _post,
        onAuthorTap: _openAuthorProfile,
        onLike: _togglePostLike,
        onComment: _focusComposer,
        onShare: _showShareOptions,
        onOptions: _showPostOptions,
        isLiking: _updatingPost,
      ),
    ],
  );

  void _openAuthorProfile() {
    if (_post.authorId <= 0) return;
    if (widget.canEdit) {
      Get.toNamed<void>(AppRoutes.profile);
      return;
    }
    Get.toNamed<void>(
      AppRoutes.communityPersonProfilePath(_post.authorId),
      arguments: _post,
    );
  }

  // Kept temporarily as a reference while all post surfaces use the shared card.
  // ignore: unused_element
  Widget _legacyPostSummary() => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
    decoration: BoxDecoration(
      color: context.appElevatedSurface.withValues(alpha: .97),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: context.appBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A173D25),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _avatar(_post.authorAvatarUrl, radius: 23),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _post.author,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _post.role,
                    style: TextStyle(fontSize: 12, color: context.appMutedText),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _post.ageLabel,
                    style: TextStyle(fontSize: 12, color: context.appMutedText),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _showPostOptions,
              icon: Icon(Icons.more_horiz_rounded, color: context.appMutedText),
              tooltip: 'common.more_options'.tr,
            ),
          ],
        ),
        if (_post.description.isNotEmpty) ...[
          const SizedBox(height: 15),
          Text(
            _post.description,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: context.appText,
            ),
          ),
        ],
        if (_post.sharedPost != null) ...[
          const SizedBox(height: 13),
          CommunitySharedPostCard(post: _post.sharedPost!),
        ],
        if (_post.imageUrls.isNotEmpty || _post.imageUrl.isNotEmpty) ...[
          const SizedBox(height: 13),
          _ImageCarousel(
            imageUrls:
                _post.imageUrls.isNotEmpty ? _post.imageUrls : [_post.imageUrl],
          ),
        ],
        if (_post.likes > 0 || _post.comments > 0 || _post.shares > 0) ...[
          const SizedBox(height: 12),
          _engagementSummary(),
        ],
        Container(
          margin: const EdgeInsets.only(top: 7),
          padding: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.appBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _postMetric(
                  _post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  _post.isLiked ? 'community.liked'.tr : 'community.like'.tr,
                  color:
                      _post.isLiked
                          ? const Color(0xFFE64657)
                          : context.appMutedText,
                  onTap: _togglePostLike,
                ),
              ),
              const _DiscussionMetricDivider(),
              Expanded(
                child: _postMetric(
                  Icons.chat_bubble_outline_rounded,
                  'community.comment'.tr,
                  onTap: _focusComposer,
                ),
              ),
              const _DiscussionMetricDivider(),
              Expanded(
                child: _postMetric(
                  Icons.reply_rounded,
                  'community.share'.tr,
                  onTap: _showShareOptions,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _postMetric(
    IconData icon,
    String label, {
    Color? color,
    required VoidCallback onTap,
  }) {
    final effectiveColor = color ?? context.appMutedText;
    return InkWell(
      onTap: _updatingPost ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: effectiveColor, size: 20),
            const SizedBox(width: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: effectiveColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _engagementSummary() => Row(
    children: [
      if (_post.likes > 0)
        Semantics(
          button: true,
          label: 'community.likes_a11y'.trParams({'count': '${_post.likes}'}),
          child: InkWell(
            onTap: _showPostLikers,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    '${_post.likes}',
                    style: TextStyle(fontSize: 12, color: context.appMutedText),
                  ),
                ],
              ),
            ),
          ),
        ),
      const Spacer(),
      if (_post.comments > 0)
        Text(
          (_post.comments == 1
                  ? 'community.comment_count_one'
                  : 'community.comment_count_many')
              .trParams({'count': '${_post.comments}'}),
          style: TextStyle(fontSize: 12, color: context.appMutedText),
        ),
      if (_post.comments > 0 && _post.shares > 0)
        Text('  ·  ', style: TextStyle(color: context.appMutedText)),
      if (_post.shares > 0)
        Text(
          (_post.shares == 1
                  ? 'community.share_count_one'
                  : 'community.share_count_many')
              .trParams({'count': '${_post.shares}'}),
          style: TextStyle(fontSize: 12, color: context.appMutedText),
        ),
    ],
  );

  List<Widget> _threadWidgets() {
    final byParent = <String, List<CommunityComment>>{};
    final ids = _comments.map((comment) => comment.id).toSet();
    final roots = <CommunityComment>[];
    for (final comment in _comments) {
      final parentId = comment.parentCommentId;
      if (parentId == null || !ids.contains(parentId)) {
        roots.add(comment);
      } else {
        byParent.putIfAbsent(parentId, () => []).add(comment);
      }
    }
    final widgets = <Widget>[];
    for (final root in roots) {
      _appendThread(widgets, root, byParent, 0);
    }
    return widgets;
  }

  void _appendThread(
    List<Widget> widgets,
    CommunityComment comment,
    Map<String, List<CommunityComment>> byParent,
    int depth,
  ) {
    widgets.add(_commentTile(comment, depth));
    for (final reply in byParent[comment.id] ?? const []) {
      _appendThread(widgets, reply, byParent, depth + 1);
    }
  }

  Widget _commentTile(CommunityComment comment, int depth) => Padding(
    padding: EdgeInsets.only(
      left: (depth.clamp(0, 2) * 16).toDouble(),
      bottom: 14,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _avatar(comment.authorAvatarUrl, radius: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(13, 9, 13, 10),
                decoration: BoxDecoration(
                  color: context.appElevatedSurface.withValues(alpha: .94),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(17),
                    bottomLeft: Radius.circular(17),
                    bottomRight: Radius.circular(17),
                  ),
                  border: Border.all(color: context.appBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      comment.text,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: context.appText.withValues(alpha: .88),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Text(
                    _commentAge(comment.createdAt),
                    style: TextStyle(fontSize: 11, color: context.appMutedText),
                  ),
                  const SizedBox(width: 18),
                  if (_post.allowReplies)
                    InkWell(
                      onTap: () => _beginReply(comment),
                      borderRadius: BorderRadius.circular(6),
                      child: Text(
                        'notifications.reply'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _green,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed:
                  _likingCommentId == null
                      ? () => _toggleCommentLike(comment)
                      : null,
              icon: Icon(
                comment.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color:
                    comment.isLiked
                        ? const Color(0xFFE2344A)
                        : context.appMutedText,
              ),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              tooltip:
                  (comment.isLiked
                          ? 'community.unlike_comment'
                          : 'community.like_comment')
                      .tr,
            ),
            if (comment.likes > 0)
              Text(
                '${comment.likes}',
                style: TextStyle(fontSize: 11, color: context.appMutedText),
              ),
            SizedBox(
              width: 36,
              height: 30,
              child: IconButton(
                onPressed: () => _showCommentOptions(comment),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: context.appMutedText,
                ),
                tooltip: 'community.comment_options'.tr,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _composer() {
    if (!_post.allowComments) {
      return Material(
        color: context.appSurface,
        elevation: 9,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Center(
              child: Text(
                'community.comments_are_turned_off_for_this_post'.tr,
                style: TextStyle(color: context.appMutedText),
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      color: context.appSurface,
      elevation: 9,
      shadowColor: context.appShadow,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxPaddedContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                10,
                AppSpacing.pageHorizontal,
                12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_replyingTo != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 5, bottom: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'community.replying_to_name'.trParams({
                                'name': _replyingTo!.author,
                              }),
                              style: TextStyle(
                                fontSize: 12,
                                color: context.appMutedText,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _cancelReply,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: 'community.cancel_reply'.tr,
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: _message,
                    focusNode: _composerFocus,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          _replyingTo == null
                              ? 'community.write_a_comment'.tr
                              : 'community.write_a_reply'.tr,
                      filled: true,
                      fillColor: context.appMutedSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        onPressed: _sending ? null : _submit,
                        icon:
                            _sending
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _green,
                                  ),
                                )
                                : const Icon(Icons.send_rounded, color: _green),
                        tooltip: 'community.send'.tr,
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
  }

  Widget _avatar(String url, {required double radius}) => ClipOval(
    child: SizedBox.square(
      dimension: radius * 2,
      child: ColoredBox(
        color: context.appSoftGreen,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Icon(Icons.person_outline_rounded, color: _green),
            if (url.isNotEmpty)
              Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: 120,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    ),
  );

  String _commentAge(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'community.recently'.tr;
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'community.just_now'.tr;
    if (difference.inHours < 1) {
      return 'community.minutes_ago'.trParams({
        'count': '${difference.inMinutes}',
      });
    }
    if (difference.inDays < 1) {
      return 'community.hours_ago'.trParams({'count': '${difference.inHours}'});
    }
    return 'community.days_ago'.trParams({'count': '${difference.inDays}'});
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.imageUrls});

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
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: AspectRatio(
                    aspectRatio: 5 / 4,
                    child: PageView(
                      controller: _pageController,
                      children: widget.imageUrls
                          .map(
                            (url) => Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, _, _) => ColoredBox(
                                    color:
                                        context.appIsDark
                                            ? context.appElevatedSurface
                                            : const Color(0xFFEAF7EE),
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
                            ? (context.appIsDark
                                ? Colors.white
                                : const Color(0xFF1F2937))
                            : (context.appIsDark
                                ? context.appBorder
                                : const Color(0xFFD1D5DB)),
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

enum _DiscussionAction { reply, report, delete, edit, share, save }

class _DiscussionMetricDivider extends StatelessWidget {
  const _DiscussionMetricDivider();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 18,
    child: VerticalDivider(width: 1, color: context.appBorder),
  );
}

class _CommentOption {
  const _CommentOption(
    this.value,
    this.label,
    this.icon, {
    this.isDestructive = false,
  });

  final _DiscussionAction value;
  final String label;
  final IconData icon;
  final bool isDestructive;
}

class _CommentOptionsSheet extends StatelessWidget {
  const _CommentOptionsSheet({this.title, required this.actions});

  final String? title;
  final List<_CommentOption> actions;

  @override
  Widget build(BuildContext context) => SafeArea(
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
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: context.appMutedText.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title!,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            decoration: BoxDecoration(
              color: context.appMutedSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.appBorder),
            ),
            child: Column(
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  ListTile(
                    onTap: () => Get.back(result: actions[index].value),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 2,
                    ),
                    leading: Icon(
                      actions[index].icon,
                      color:
                          actions[index].isDestructive
                              ? const Color(0xFFD94545)
                              : context.appText,
                      size: 24,
                    ),
                    title: Text(
                      actions[index].label,
                      style: TextStyle(
                        color:
                            actions[index].isDestructive
                                ? const Color(0xFFD94545)
                                : context.appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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
