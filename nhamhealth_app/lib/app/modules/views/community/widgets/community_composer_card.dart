import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class CommunityComposerCard extends StatelessWidget {
  const CommunityComposerCard({
    required this.onTap,
    this.authorAvatarUrl = '',
    super.key,
  });

  final VoidCallback onTap;
  final String authorAvatarUrl;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE3EBE5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A173D25),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFFE4F6EA),
                backgroundImage:
                    authorAvatarUrl.isEmpty
                        ? null
                        : NetworkImage(authorAvatarUrl),
                child:
                    authorAvatarUrl.isEmpty
                        ? const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primaryGreen,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F8F6),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE3EAE5)),
                  ),
                  child: const Text(
                    'Share a win, question, or healthy idea...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Color(0xFF718078)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE8EEE9)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _ComposerShortcut(
                  icon: Icons.image_outlined,
                  label: 'Photo',
                  color: Color(0xFF168B4A),
                ),
              ),
              SizedBox(
                height: 22,
                child: VerticalDivider(width: 1, color: Color(0xFFE1E8E3)),
              ),
              Expanded(
                child: _ComposerShortcut(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Ask community',
                  color: Color(0xFF596C9B),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ComposerShortcut extends StatelessWidget {
  const _ComposerShortcut({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4E5B52),
            ),
          ),
        ),
      ],
    ),
  );
}
