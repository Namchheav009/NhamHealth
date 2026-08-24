import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class CommunityComposerCard extends StatelessWidget {
  const CommunityComposerCard({required this.onTap, super.key});

  final VoidCallback onTap;

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
      child: const Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: Color(0xFFE4F6EA),
            child: Icon(
              Icons.person_outline_rounded,
              color: AppColors.primaryGreen,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Share a win, question, or healthy idea...',
              style: TextStyle(fontSize: 13, color: Color(0xFF718078)),
            ),
          ),
          _EditIcon(),
        ],
      ),
    ),
  );
}

class _EditIcon extends StatelessWidget {
  const _EditIcon();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Color(0xFFE9F8EE),
      shape: BoxShape.circle,
    ),
    child: SizedBox.square(
      dimension: 36,
      child: Icon(Icons.edit_outlined, size: 19, color: AppColors.primaryGreen),
    ),
  );
}
