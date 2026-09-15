import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

Future<bool> confirmPostDeletion({required String messageKey}) async {
  final context = Get.overlayContext ?? Get.context;
  if (context == null || !context.mounted) return false;

  final confirmed = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'common.cancel'.tr,
    barrierColor: Colors.black.withValues(alpha: .48),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder:
        (dialogContext, _, _) => Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: const SizedBox.expand(),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(22),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 25, 24, 22),
                      decoration: BoxDecoration(
                        color: dialogContext.appElevatedSurface,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .2),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE8E8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.errorCoral,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 17),
                          Text(
                            'community.delete_post_question'.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dialogContext.appText,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            messageKey.tr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: dialogContext.appMutedText,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 23),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed:
                                      () => Navigator.pop(dialogContext, false),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    side: BorderSide(
                                      color: dialogContext.appBorder,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text('common.cancel'.tr),
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed:
                                      () => Navigator.pop(dialogContext, true),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    backgroundColor: AppColors.errorCoral,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 19,
                                  ),
                                  label: Text('common.delete'.tr),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
    transitionBuilder:
        (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: .94, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
  );

  return confirmed ?? false;
}
