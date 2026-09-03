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
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
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
                  child: Container(
                    height: 46,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color:
                          context.appIsDark
                              ? context.appColorScheme.surfaceContainerHigh
                              : const Color(0xFFF3F6F3),
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
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _ComposerAction(icon: Icons.image_outlined, label: 'Photo'.tr),
                const SizedBox(width: 8),
                _ComposerAction(
                  icon: Icons.forum_outlined,
                  label: 'Ask community'.tr,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color:
          context.appIsDark
              ? context.appColorScheme.surfaceContainer
              : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.appBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 1),
        Icon(icon, size: 18, color: AppColors.primaryGreen),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: context.appText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
