import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_alert.dart';
import '../../models/community/community_comment.dart';
import '../../models/community/community_person.dart';
import '../../models/community/community_post.dart';
import '../../models/community/community_post_draft.dart';
import '../../models/community/community_reply_address.dart';
import '../../models/community/community_types.dart';
import '../../repositories/community/community_repository.dart';
import '../../../../core/services/auth_service.dart';
import 'community_post_editor_page.dart';
import 'community_report_page.dart';
import 'community_share_actions.dart';
import 'community_share_post_page.dart';
import 'widgets/community_shared_post_card.dart';
import '../profile/widgets/profile_post_card.dart';

/// A full post discussion screen. Replies are displayed below their parent and
/// the composer switches context when a user chooses Reply.
class CommunityCommentsPage extends StatefulWidget {
  const CommunityCommentsPage({
    required this.post,
    this.onPostChanged,
    this.canEdit = false,
    this.onEditPost,
    this.onShareToFeed,
    super.key,
  });

  final CommunityPost post;
  final VoidCallback? onPostChanged;
  final bool canEdit;
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

  @override
  void initState() {
    super.initState();
    _post = widget.post.copyWith();
    _repository = Get.find<CommunityRepository>();
    _loadComments();
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
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _repository.getComments(_post.id);
      if (mounted) setState(() => _comments = comments);
    } on Object catch (error) {
      if (mounted) Get.snackbar('Could not load comments', error.toString());
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
      if (mounted) Get.snackbar('Could not comment', error.toString());
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
      if (mounted) Get.snackbar('Could not update like', error.toString());
    } finally {
      if (mounted) setState(() => _updatingPost = false);
    }
  }

  Future<void> _showShareToFriends() async {
    if (_updatingPost) return;
    try {
      final people = await _repository.getPeople();
      final friends = people[FriendsView.friends] ?? const <CommunityPerson>[];
      final selectedIds = <String>{};
      var isSending = false;
      await Get.bottomSheet<void>(
        StatefulBuilder(
          builder:
              (context, setSheetState) => SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Share with friends',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose friends to send this post to.',
                        style: TextStyle(color: Color(0xFF667069)),
                      ),
                      const SizedBox(height: 12),
                      if (friends.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Add friends before sharing posts privately.',
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: friends.length,
                            separatorBuilder:
                                (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final friend = friends[index];
                              final selected = selectedIds.contains(friend.id);
                              return CheckboxListTile(
                                value: selected,
                                onChanged:
                                    isSending
                                        ? null
                                        : (_) => setSheetState(() {
                                          selected
                                              ? selectedIds.remove(friend.id)
                                              : selectedIds.add(friend.id);
                                        }),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                activeColor: _green,
                                title: Text(
                                  friend.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle:
                                    friend.detail == null
                                        ? null
                                        : Text(friend.detail!),
                                secondary: _avatar(
                                  friend.avatarUrl,
                                  radius: 20,
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              selectedIds.isEmpty || isSending
                                  ? null
                                  : () async {
                                    setSheetState(() => isSending = true);
                                    try {
                                      await _repository.sharePost(
                                        _post.id,
                                        recipientIds: selectedIds.toList(),
                                      );
                                      if (!mounted) return;
                                      setState(() {
                                        _post = _post.copyWith(
                                          shares:
                                              _post.shares + selectedIds.length,
                                        );
                                      });
                                      widget.onPostChanged?.call();
                                      Get.back<void>();
                                      unawaited(
                                        AppAlert.success(
                                          title: 'Post sent',
                                          message:
                                              'Sent to ${selectedIds.length} friend${selectedIds.length == 1 ? '' : 's'}.',
                                        ),
                                      );
                                    } on Object catch (error) {
                                      setSheetState(() => isSending = false);
                                      unawaited(
                                        AppAlert.error(
                                          title: 'Could not send post',
                                          message: error.toString(),
                                        ),
                                      );
                                    }
                                  },
                          icon:
                              isSending
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.send_rounded),
                          label: Text(isSending ? 'Sending...' : 'Send'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                          ),
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
    } on Object catch (error) {
      if (mounted) {
        unawaited(
          AppAlert.error(
            title: 'Could not share post',
            message: error.toString(),
          ),
        );
      }
    }
  }

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
    final action = await showCommunityShareActions(
      canShareToFeed:
          _post.sharedPost != null ||
          _post.visibility == CommunityPostVisibility.public,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case CommunityShareAction.shareNow:
        setState(() => _updatingPost = true);
        try {
          await _shareToFeed('', CommunityPostVisibility.public);
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
        } finally {
          if (mounted) setState(() => _updatingPost = false);
        }
      case CommunityShareAction.writePost:
        final user = await Get.find<AuthService>().restoreSession();
        if (!mounted) return;
        await Get.to<void>(
          () => CommunitySharePostPage(
            post: _post,
            authorName: user?.displayName ?? 'Community member',
            authorAvatarUrl: user?.profileImageUrl ?? '',
            onShare: _shareToFeed,
          ),
          transition: Transition.rightToLeft,
        );
      case CommunityShareAction.sendToFriends:
        await _showShareToFriends();
    }
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
      if (mounted) Get.snackbar('Could not update like', error.toString());
    } finally {
      if (mounted) setState(() => _likingCommentId = null);
    }
  }

  Future<void> _showCommentOptions(CommunityComment comment) async {
    final action = await Get.bottomSheet<_DiscussionAction>(
      _CommentOptionsSheet(
        actions: [
          if (_post.allowReplies)
            const _CommentOption(
              _DiscussionAction.reply,
              'Reply',
              Icons.reply_rounded,
            ),
          if (comment.canDelete)
            const _CommentOption(
              _DiscussionAction.delete,
              'Delete comment',
              Icons.delete_outline_rounded,
              isDestructive: true,
            )
          else
            const _CommentOption(
              _DiscussionAction.report,
              'Report comment',
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
        title: const Text('Delete comment?'),
        content: const Text(
          'This will permanently remove this comment and any replies to it.',
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
          title: 'Comment deleted',
          message: 'The comment has been removed.',
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        unawaited(
          AppAlert.error(
            title: 'Could not delete comment',
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
    final action = await Get.bottomSheet<_DiscussionAction>(
      _CommentOptionsSheet(
        title: 'Post options',
        actions: [
          if (widget.canEdit && widget.onEditPost != null)
            const _CommentOption(
              _DiscussionAction.edit,
              'Edit post',
              Icons.edit_outlined,
            ),
          const _CommentOption(
            _DiscussionAction.share,
            'Share post',
            Icons.reply_rounded,
          ),
          const _CommentOption(
            _DiscussionAction.report,
            'Report post',
            Icons.flag_outlined,
            isDestructive: true,
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
    if (!mounted || action == null) return;
    if (action == _DiscussionAction.edit) {
      await _editPost();
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

  Future<void> _editPost() async {
    final submit = widget.onEditPost;
    if (submit == null) return;
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
    backgroundColor: AppColors.homeBackground,
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
                    title: 'Comments',
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
                child:
                    _loading
                        ? const Center(
                          child: CircularProgressIndicator(color: _green),
                        )
                        : ListView(
                          controller: _scrollController,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _postSummary(),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Text(
                                          '${_post.comments} ${_post.comments == 1 ? 'Comment' : 'Comments'}',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Text(
                                          'Discussion',
                                          style: TextStyle(
                                            color: _green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    if (_comments.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 38,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Be the first to comment.',
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

  Widget _postSummary() => ProfilePostCard(
    post: _post,
    onLike: _togglePostLike,
    onComment: _focusComposer,
    onShare: _showShareOptions,
    onOptions: _showPostOptions,
    isLiking: _updatingPost,
  );

  // Kept temporarily as a reference while all post surfaces use the shared card.
  // ignore: unused_element
  Widget _legacyPostSummary() => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .97),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE3EBE5)),
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF778078),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _post.ageLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF778078),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _showPostOptions,
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFF768178),
              ),
              tooltip: 'Post options',
            ),
          ],
        ),
        if (_post.description.isNotEmpty) ...[
          const SizedBox(height: 15),
          Text(
            _post.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Color(0xFF505951),
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
                _post.imageUrls.isNotEmpty
                    ? _post.imageUrls
                    : [_post.imageUrl],
          ),
        ],
        if (_post.likes > 0 || _post.comments > 0 || _post.shares > 0) ...[
          const SizedBox(height: 12),
          _engagementSummary(),
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
                child: _postMetric(
                  _post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  _post.isLiked ? 'Liked' : 'Like',
                  color:
                      _post.isLiked
                          ? const Color(0xFFE64657)
                          : const Color(0xFF69756D),
                  onTap: _togglePostLike,
                ),
              ),
              const _DiscussionMetricDivider(),
              Expanded(
                child: _postMetric(
                  Icons.chat_bubble_outline_rounded,
                  'Comment',
                  onTap: _focusComposer,
                ),
              ),
              const _DiscussionMetricDivider(),
              Expanded(
                child: _postMetric(
                  Icons.reply_rounded,
                  'Share',
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
    Color color = const Color(0xFF69756D),
    required VoidCallback onTap,
  }) => InkWell(
    onTap: _updatingPost ? null : onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _engagementSummary() => Row(
    children: [
      if (_post.likes > 0) ...[
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
          style: const TextStyle(fontSize: 12, color: Color(0xFF69756D)),
        ),
      ],
      const Spacer(),
      if (_post.comments > 0)
        Text(
          '${_post.comments} ${_post.comments == 1 ? 'comment' : 'comments'}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF69756D)),
        ),
      if (_post.comments > 0 && _post.shares > 0)
        const Text('  ·  ', style: TextStyle(color: Color(0xFF98A19A))),
      if (_post.shares > 0)
        Text(
          '${_post.shares} ${_post.shares == 1 ? 'share' : 'shares'}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF69756D)),
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
                  color: Colors.white.withValues(alpha: .94),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(17),
                    bottomLeft: Radius.circular(17),
                    bottomRight: Radius.circular(17),
                  ),
                  border: Border.all(color: const Color(0xFFE4ECE6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D2922),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      comment.text,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF505951),
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
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8B938D),
                    ),
                  ),
                  const SizedBox(width: 18),
                  if (_post.allowReplies)
                    InkWell(
                      onTap: () => _beginReply(comment),
                      borderRadius: BorderRadius.circular(6),
                      child: const Text(
                        'Reply',
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
                        : const Color(0xFF758078),
              ),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              tooltip: comment.isLiked ? 'Unlike comment' : 'Like comment',
            ),
            if (comment.likes > 0)
              Text(
                '${comment.likes}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF758078)),
              ),
            SizedBox(
              width: 36,
              height: 30,
              child: IconButton(
                onPressed: () => _showCommentOptions(comment),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: Color(0xFF758078),
                ),
                tooltip: 'Comment options',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _composer() {
    if (!_post.allowComments) {
      return const Material(
        color: Colors.white,
        elevation: 9,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Center(
              child: Text(
                'Comments are turned off for this post.',
                style: TextStyle(color: Color(0xFF5E6961)),
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.white,
      elevation: 9,
      shadowColor: Colors.black12,
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
                              'Replying to ${_replyingTo!.author}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5E6961),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _cancelReply,
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: 'Cancel reply',
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
                              ? 'Write a comment...'
                              : 'Write a reply...',
                      filled: true,
                      fillColor: const Color(0xFFF3F7F4),
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
                        tooltip: 'Send',
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

  Widget _avatar(String url, {required double radius}) => CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xFFEAF7EE),
    backgroundImage: url.isEmpty ? null : NetworkImage(url),
    child:
        url.isEmpty
            ? const Icon(Icons.person_outline_rounded, color: _green)
            : null,
  );

  String _commentAge(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Recently';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
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
                                  (_, _, _) => const ColoredBox(
                                    color: Color(0xFFEAF7EE),
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

enum _DiscussionAction { reply, report, delete, edit, share }

class _DiscussionMetricDivider extends StatelessWidget {
  const _DiscussionMetricDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 18,
    child: VerticalDivider(width: 1, color: Color(0xFFDCE6DF)),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF9AA19C),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (title != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                for (var index = 0; index < actions.length; index++) ...[
                  ListTile(
                    onTap: () => Get.back(result: actions[index].value),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 3,
                    ),
                    leading: Icon(
                      actions[index].icon,
                      color:
                          actions[index].isDestructive
                              ? const Color(0xFFD94545)
                              : const Color(0xFF18231C),
                      size: 27,
                    ),
                    title: Text(
                      actions[index].label,
                      style: TextStyle(
                        color:
                            actions[index].isDestructive
                                ? const Color(0xFFD94545)
                                : const Color(0xFF18231C),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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
