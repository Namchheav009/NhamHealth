import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/app_alert.dart';
import '../../models/community/community_post.dart';
import 'widgets/community_audience_picker.dart';

export 'community_share_post_page.dart';

Future<void> showCommunityShareComposer({
  required String authorName,
  required String authorAvatarUrl,
  required Future<void> Function(
    String message,
    CommunityPostVisibility visibility,
  )
  onShare,
  CommunityPost? post,
  String initialMessage = '',
  CommunityPostVisibility initialVisibility = CommunityPostVisibility.public,
  String? submitButtonText,
  bool isEditing = false,
}) async {
  await Get.bottomSheet<void>(
    _CommunityShareComposer(
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      onShare: onShare,
      post: post,
      initialMessage: initialMessage,
      initialVisibility: initialVisibility,
      submitButtonText: submitButtonText,
      isEditing: isEditing,
    ),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
  );
}

class _CommunityShareComposer extends StatefulWidget {
  const _CommunityShareComposer({
    required this.authorName,
    required this.authorAvatarUrl,
    required this.onShare,
    this.post,
    this.initialMessage = '',
    this.initialVisibility = CommunityPostVisibility.public,
    this.submitButtonText,
    this.isEditing = false,
  });

  final String authorName;
  final String authorAvatarUrl;
  final Future<void> Function(
    String message,
    CommunityPostVisibility visibility,
  )
  onShare;
  final CommunityPost? post;
  final String initialMessage;
  final CommunityPostVisibility initialVisibility;
  final String? submitButtonText;
  final bool isEditing;

  @override
  State<_CommunityShareComposer> createState() =>
      _CommunityShareComposerState();
}

class _CommunityShareComposerState extends State<_CommunityShareComposer> {
  late final TextEditingController _message;
  final _focusNode = FocusNode();
  late CommunityPostVisibility _visibility;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _message = TextEditingController(text: widget.initialMessage);
    _visibility = widget.initialVisibility;
    if (widget.isEditing && widget.initialMessage.isNotEmpty) {
      _message.selection = TextSelection.collapsed(
        offset: widget.initialMessage.length,
      );
    }
  }

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
          title: widget.isEditing ? 'Post updated' : 'Post shared',
          message:
              widget.isEditing
                  ? 'Your changes have been saved.'
                  : 'The post is now on your profile and Community feed.',
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        unawaited(
          AppAlert.error(
            title:
                widget.isEditing
                    ? 'Could not update post'
                    : 'Could not share post',
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

  Future<void> _chooseAudience() async {
    final selected = await showCommunityAudiencePicker(
      context,
      selected: _visibility,
    );
    if (selected != null && mounted) {
      setState(() => _visibility = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;

    final sheetBg = isDark ? context.appElevatedSurface : Colors.white;
    final pillBg =
        isDark
            ? context.appColorScheme.surfaceContainerHighest
            : const Color(0xFFE4E6EB);
    final handleColor =
        isDark ? context.appColorScheme.outline : const Color(0xFFCED0D4);

    return SafeArea(
      top: false,
      child: Material(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Author row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: context.appSoftGreen,
                    foregroundImage:
                        widget.authorAvatarUrl.isEmpty
                            ? null
                            : NetworkImage(widget.authorAvatarUrl),
                    child:
                        widget.authorAvatarUrl.isEmpty
                            ? const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.primaryGreen,
                              size: 20,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.appText,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Feed destination chip [Feed ▾]
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: pillBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Feed',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: context.appText,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    Icons.arrow_drop_down_rounded,
                                    size: 18,
                                    color: context.appText,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Audience chip [👥 Friends/Public ▾]
                            Material(
                              color: pillBg,
                              borderRadius: BorderRadius.circular(6),
                              child: InkWell(
                                key: const ValueKey<String>(
                                  'community-share-audience',
                                ),
                                borderRadius: BorderRadius.circular(6),
                                onTap: _chooseAudience,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _visibility.icon,
                                        size: 14,
                                        color: context.appText,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _visibility.label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: context.appText,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        size: 18,
                                        color: context.appText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Plain borderless text area with comfortable height
              GestureDetector(
                key: const ValueKey<String>('community-share-write-area'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _focusNode.requestFocus(),
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 60,
                    maxHeight: 140,
                  ),
                  alignment: Alignment.topLeft,
                  child: TextField(
                    key: const ValueKey<String>('community-share-message'),
                    focusNode: _focusNode,
                    controller: _message,
                    minLines: 2,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Say something...'.tr,
                      hintStyle: TextStyle(
                        color: context.appMutedText,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: context.appText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bottom toolbar: [😊 👥]               [Share now]
              Row(
                children: [
                  IconButton(
                    key: const ValueKey<String>('community-share-emoji-button'),
                    tooltip: 'Add emoji'.tr,
                    onPressed: _addEmoji,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.sentiment_satisfied_alt_outlined,
                      color: context.appMutedText,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Audience'.tr,
                    onPressed: _chooseAudience,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.person_add_alt_1_outlined,
                      color: context.appMutedText,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const ValueKey<String>('community-share-submit'),
                    onPressed: _sharing ? null : _share,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primaryGreen,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _sharing
                            ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              (widget.submitButtonText ??
                                      (widget.isEditing ? 'Save' : 'Share now'))
                                  .tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
