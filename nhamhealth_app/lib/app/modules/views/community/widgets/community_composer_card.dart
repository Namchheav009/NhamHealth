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
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: context.appSoftGreen,
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
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: context.appMutedSurface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Text(
                    'Share a win, question, or healthy idea...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.2,
                      color: context.appMutedText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.appBorder),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _ComposerShortcut(
                  icon: Icons.image_outlined,
                  label: 'Photo',
                  color: Color(0xFF168B4A),
                ),
              ),
              const SizedBox(height: 22, child: VerticalDivider(width: 1)),
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
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: context.appMutedText,
            ),
          ),
        ),
      ],
    ),
  );
}
