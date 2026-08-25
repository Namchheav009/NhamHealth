import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum CommunityShareAction { shareNow, writePost, sendToFriends }

Future<CommunityShareAction?> showCommunityShareActions({
  required bool canShareToFeed,
}) => Get.bottomSheet<CommunityShareAction>(
  SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                color: const Color(0xFF9AA19C),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Share post',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          _ShareActionTile(
            icon: Icons.public_rounded,
            title: 'Share now',
            subtitle:
                canShareToFeed
                    ? 'Post it to your Community feed'
                    : 'Only public posts can be shared to your feed',
            enabled: canShareToFeed,
            onTap: () => Get.back(result: CommunityShareAction.shareNow),
          ),
          _ShareActionTile(
            icon: Icons.edit_note_rounded,
            title: 'Write a post',
            subtitle: 'Add your thoughts and choose an audience',
            enabled: canShareToFeed,
            onTap: () => Get.back(result: CommunityShareAction.writePost),
          ),
          _ShareActionTile(
            icon: Icons.send_rounded,
            title: 'Send to friends',
            subtitle: 'Share privately with selected friends',
            onTap: () => Get.back(result: CommunityShareAction.sendToFriends),
          ),
        ],
      ),
    ),
  ),
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
);

class _ShareActionTile extends StatelessWidget {
  const _ShareActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => ListTile(
    enabled: enabled,
    onTap: enabled ? onTap : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    leading: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFEAF7EE) : const Color(0xFFF0F1F0),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: enabled ? const Color(0xFF087B3A) : const Color(0xFF9AA19C),
      ),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
