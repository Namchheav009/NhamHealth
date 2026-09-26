import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import 'app_alert.dart';

Future<bool> confirmPostDeletion({
  required String messageKey,
  BuildContext? context,
  bool barrierDismissible = true,
}) async {
  final targetContext = context ?? Get.overlayContext ?? Get.context;
  return await AppAlert.confirmAction(
    context: targetContext,
    title: 'community.delete_post_question',
    message: messageKey,
    confirmText: 'common.delete',
    cancelText: 'common.cancel',
    icon: Icons.delete_outline_rounded,
    iconColor: AppColors.errorCoral,
    confirmButtonColor: AppColors.errorCoral,
    barrierDismissible: barrierDismissible,
  );
}
