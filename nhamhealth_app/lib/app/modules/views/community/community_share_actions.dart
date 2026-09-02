import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/app_alert.dart';
import '../../models/community/community_post.dart';
import 'widgets/community_audience_picker.dart';

Future<void> showCommunityShareComposer({
  required String authorName,
  required String authorAvatarUrl,
  required Future<void> Function(
    String message,
    CommunityPostVisibility visibility,
  )
  onShare,
}) => Get.bottomSheet<void>(
  _CommunityShareComposer(
    authorName: authorName,
    authorAvatarUrl: authorAvatarUrl,
    onShare: onShare,
  ),
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
);

class _CommunityShareComposer extends StatefulWidget {
  const _CommunityShareComposer({
    required this.authorName,
    required this.authorAvatarUrl,
    required this.onShare,
  });

  final String authorName;
  final String authorAvatarUrl;
  final Future<void> Function(
    String message,
    CommunityPostVisibility visibility,
  )
  onShare;

  @override
  State<_CommunityShareComposer> createState() =>
      _CommunityShareComposerState();
}

class _CommunityShareComposerState extends State<_CommunityShareComposer> {
  static const _green = Color(0xFF087B3A);
  final _message = TextEditingController();
  CommunityPostVisibility _visibility = CommunityPostVisibility.public;
  bool _sharing = false;

  @override
  void dispose() {
    _message.dispose();
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
          message: 'The post is now on your profile and Community feed.',
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

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: context.appStrongBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 23,
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
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _AudiencePicker(
                      value: _visibility,
                      onChanged: (value) => setState(() => _visibility = value),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close share composer',
                onPressed: Get.back,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.appBorder),
            ),
            child: TextField(
              key: const ValueKey<String>('community-share-message'),
              controller: _message,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Say something about this...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                color: context.appText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const ValueKey<String>('community-share-submit'),
              onPressed: _sharing ? null : _share,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  _sharing
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Share now',
                        style: TextStyle(fontWeight: FontWeight.w700),
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
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey<String>('community-share-audience'),
    borderRadius: BorderRadius.circular(7),
    onTap: () async {
      final selected = await showCommunityAudiencePicker(
        context,
        selected: value,
      );
      if (selected != null) onChanged(selected);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: context.appMutedSurface,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(value.icon, size: 15, color: context.appMutedText),
          const SizedBox(width: 5),
          Text(
            value.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const Icon(Icons.arrow_drop_down_rounded, size: 18),
        ],
      ),
    ),
  );
}
