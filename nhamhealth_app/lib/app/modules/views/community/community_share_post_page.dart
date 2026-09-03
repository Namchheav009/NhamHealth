import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/app_alert.dart';
import '../../models/community/community_post.dart';
import 'widgets/community_audience_picker.dart';
import 'widgets/community_shared_post_card.dart';

class CommunitySharePostPage extends StatefulWidget {
  const CommunitySharePostPage({
    required this.post,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.onShare,
    super.key,
  });

  final CommunityPost post;
  final String authorName;
  final String authorAvatarUrl;
  final Future<void> Function(
    String message,
    CommunityPostVisibility visibility,
  )
  onShare;

  @override
  State<CommunitySharePostPage> createState() => _CommunitySharePostPageState();
}

class _CommunitySharePostPageState extends State<CommunitySharePostPage> {
  static const _green = Color(0xFF08A936);
  final _message = TextEditingController();
  final _focusNode = FocusNode();
  CommunityPostVisibility _visibility = CommunityPostVisibility.public;
  bool _sharing = false;

  @override
  void dispose() {
    _message.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await widget.onShare(_message.text.trim(), _visibility);
      if (!mounted) return;
      Get.back<void>();
      unawaited(
        AppAlert.success(
          title: 'Post shared',
          message: 'The post is now on your Community feed.',
        ),
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
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _addEmoji() {
    final selection = _message.selection;
    final offset = selection.isValid ? selection.start : _message.text.length;
    final updated = _message.text.replaceRange(offset, offset, '😊');
    _message.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: offset + 2),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appSurface,
    appBar: AppBar(
      backgroundColor: context.appSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: 'Close'.tr,
        onPressed: () => Get.back<void>(),
      ),
      title: Text(
        'Share to Feed'.tr,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: context.appText,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton(
            key: const ValueKey<String>('community-share-submit'),
            onPressed: _sharing ? null : _share,
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child:
                _sharing
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text(
                      'Share',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: context.appBorder.withValues(alpha: 0.6),
        ),
      ),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                // Facebook-style Author Info Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: context.appSoftGreen,
                      foregroundImage:
                          widget.authorAvatarUrl.isEmpty
                              ? null
                              : NetworkImage(widget.authorAvatarUrl),
                      child:
                          widget.authorAvatarUrl.isEmpty
                              ? const Icon(
                                Icons.person_outline_rounded,
                                color: _green,
                                size: 22,
                              )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.authorName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.appText,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _AudiencePicker(
                                value: _visibility,
                                onChanged:
                                    (value) =>
                                        setState(() => _visibility = value),
                              ),
                              const _DestinationChip(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Responsive Write Text Section
                GestureDetector(
                  key: const ValueKey<String>('community-share-write-area'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _focusNode.requestFocus(),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 80),
                    alignment: Alignment.topLeft,
                    child: TextField(
                      key: const ValueKey<String>('community-share-message'),
                      focusNode: _focusNode,
                      controller: _message,
                      minLines: 3,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Say something about this...'.tr,
                        hintStyle: TextStyle(
                          color: context.appMutedText,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: context.appText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Embedded Shared Post Card Preview (Facebook Style)
                CommunitySharedPostCard(
                  post: CommunitySharedPost.fromPost(widget.post),
                ),
              ],
            ),
          ),

          // Facebook-style Bottom Action Toolbar
          Container(
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border(
                top: BorderSide(
                  color: context.appBorder.withValues(alpha: 0.6),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: context.appMutedSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appBorder),
              ),
              child: Row(
                children: [
                  Text(
                    'Add to your post'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.appMutedText,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Add emoji'.tr,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      color: Color(0xFFF7B125),
                      size: 22,
                    ),
                    onPressed: _addEmoji,
                  ),
                  IconButton(
                    tooltip: 'Choose audience'.tr,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(_visibility.icon, color: _green, size: 19),
                    onPressed: () async {
                      final selected = await showCommunityAudiencePicker(
                        context,
                        selected: _visibility,
                      );
                      if (selected != null) {
                        setState(() => _visibility = selected);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AudiencePicker extends StatelessWidget {
  const _AudiencePicker({required this.value, required this.onChanged});

  final CommunityPostVisibility value;
  final ValueChanged<CommunityPostVisibility> onChanged;

  @override
  Widget build(BuildContext context) => Material(
    color:
        context.appIsDark
            ? context.appColorScheme.surfaceContainerHigh
            : const Color(0xFFE4E6EB),
    borderRadius: BorderRadius.circular(6),
    child: InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () async {
        final selected = await showCommunityAudiencePicker(
          context,
          selected: value,
        );
        if (selected != null) onChanged(selected);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(value.icon, size: 13, color: context.appText),
            const SizedBox(width: 4),
            Text(
              value.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.appText,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: context.appText,
            ),
          ],
        ),
      ),
    ),
  );
}

class _DestinationChip extends StatelessWidget {
  const _DestinationChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color:
          context.appIsDark
              ? context.appColorScheme.surfaceContainerHigh
              : const Color(0xFFE4E6EB),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.dynamic_feed_rounded, size: 13, color: context.appText),
        const SizedBox(width: 4),
        Text(
          'Feed',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.appText,
          ),
        ),
        const SizedBox(width: 2),
        Icon(Icons.arrow_drop_down_rounded, size: 16, color: context.appText),
      ],
    ),
  );
}
