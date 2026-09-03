import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appElevatedSurface.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appBorder),
          boxShadow: context.appTileShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.16),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child:
                    authorAvatarUrl.isEmpty
                        ? Container(
                          color: context.appSoftGreen,
                          child: const Icon(
                            Icons.person_outline_rounded,
                            size: 22,
                            color: AppColors.primaryGreen,
                          ),
                        )
                        : Image.network(
                          authorAvatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, _, _) => Container(
                                color: context.appSoftGreen,
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  size: 22,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                        ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share a healthy meal'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.appText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Post a new meal to the community'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: context.appMutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.appSoftGreen,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: .25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 21,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
