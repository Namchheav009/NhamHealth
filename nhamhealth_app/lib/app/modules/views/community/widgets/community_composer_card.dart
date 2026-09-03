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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: context.appBorder),
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
              child: Material(
                color:
                    context.appIsDark
                        ? context.appColorScheme.surfaceContainerHigh
                        : const Color(0xFFF3F6F3),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 46,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Text(
                      "What's on your healthy mind?".tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appMutedText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ComposerAction(
              icon: Icons.image_outlined,
              label: 'Photo'.tr,
              onTap: onTap,
            ),
            const SizedBox(width: 8),
            _ComposerAction(
              icon: Icons.forum_outlined,
              label: 'Ask community'.tr,
              onTap: onTap,
            ),
          ],
        ),
      ],
    ),
  );
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color:
        context.appIsDark
            ? context.appColorScheme.surfaceContainer
            : Colors.white,
    shape: StadiumBorder(side: BorderSide(color: context.appBorder)),
    child: InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: SizedBox(
        height: 38,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: 7),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
