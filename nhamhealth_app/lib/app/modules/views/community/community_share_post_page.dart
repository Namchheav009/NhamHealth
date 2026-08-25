import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_alert.dart';
import '../../models/community/community_post.dart';
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFBFC),
    appBar: AppBar(
      backgroundColor: const Color(0xFFFFFBFC),
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Share post',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton(
            onPressed: _sharing ? null : _share,
            style: FilledButton.styleFrom(backgroundColor: _green),
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
                    : const Text('Share'),
          ),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFEAF7EE),
                backgroundImage:
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
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.authorName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    _AudiencePicker(
                      value: _visibility,
                      onChanged: (value) => setState(() => _visibility = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            key: const ValueKey<String>('community-share-message'),
            controller: _message,
            autofocus: true,
            minLines: 3,
            maxLines: 7,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Say something about this...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(fontSize: 17, height: 1.4),
          ),
          const SizedBox(height: 16),
          CommunitySharedPostCard(
            post: CommunitySharedPost.fromPost(widget.post),
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
  Widget build(BuildContext context) =>
      PopupMenuButton<CommunityPostVisibility>(
        initialValue: value,
        onSelected: onChanged,
        itemBuilder:
            (context) => CommunityPostVisibility.values
                .map(
                  (item) => PopupMenuItem(
                    value: item,
                    child: Row(
                      children: [
                        Icon(item.icon, size: 19),
                        const SizedBox(width: 9),
                        Text(item.label),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(value.icon, size: 15, color: const Color(0xFF4D5A51)),
              const SizedBox(width: 5),
              Text(
                value.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded, size: 18),
            ],
          ),
        ),
      );
}
