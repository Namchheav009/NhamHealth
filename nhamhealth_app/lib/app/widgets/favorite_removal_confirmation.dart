import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<bool> confirmFavoriteRemoval() async {
  final confirmed = await Get.dialog<bool>(
    AlertDialog(
      title: Text('Remove favorite?'.tr),
      content: Text(
        'Remove this meal from your favorites? You can add it again later.'.tr,
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('Cancel'.tr),
        ),
        FilledButton(
          onPressed: () => Get.back(result: true),
          child: Text('Remove'.tr),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
