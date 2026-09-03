import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';

class CommunityEmptyState extends StatelessWidget {
  const CommunityEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    decoration: BoxDecoration(
      color: context.appElevatedSurface.withValues(alpha: .97),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.appBorder),
      boxShadow: context.appTileShadow,
    ),
    child: Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: context.appSoftGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          title.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.appText,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          message.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: context.appMutedText,
          ),
        ),
      ],
    ),
  );
}
