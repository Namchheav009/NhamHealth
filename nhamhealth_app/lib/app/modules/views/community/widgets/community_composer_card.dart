import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';

class CommunityComposerCard extends StatelessWidget {
  const CommunityComposerCard({
    required this.onTap,
    this.onPhotoTap,
    this.onAvatarTap,
    this.authorAvatarUrl = '',
    super.key,
  });

  final VoidCallback onTap;
  final VoidCallback? onPhotoTap;
  final VoidCallback? onAvatarTap;
  final String authorAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    final cardBg = isDark ? context.appElevatedSurface : Colors.white;
    final borderColor = isDark ? context.appBorder : const Color(0xFFE5ECE7);
    final innerBorderColor =
        isDark ? context.appBorder : const Color(0xFFE2E8E3);
    final mutedTextColor =
        isDark ? context.appMutedText : const Color(0xFF757E8A);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap ?? onTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.appSoftGreen,
              ),
              child: ClipOval(
                child:
                    authorAvatarUrl.isEmpty
                        ? const Icon(
                          Icons.person_outline_rounded,
                          size: 22,
                          color: AppColors.primaryGreen,
                        )
                        : Image.network(
                          authorAvatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, _, _) => const Icon(
                                Icons.person_outline_rounded,
                                size: 22,
                                color: AppColors.primaryGreen,
                              ),
                        ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: Colors.transparent,
              shape: StadiumBorder(
                side: BorderSide(color: innerBorderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: Text(
                            'community.composer_prompt'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: mutedTextColor,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Semantics(
                          button: true,
                          label: 'community.photo'.tr,
                          child: Material(
                            color: context.appSoftGreen,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: onPhotoTap ?? onTap,
                              child: const SizedBox(
                                width: 34,
                                height: 34,
                                child: Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 20,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
