import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<bool> confirmFavoriteRemoval() async {
  final confirmed = await Get.dialog<bool>(
    AlertDialog(
      title: Text('profile.remove_favorite'.tr),
      content: Text(
        'profile.remove_this_meal_from_your_favorites_you_can_add_it_again_later'
            .tr,
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: Text('common.cancel'.tr),
        ),
        FilledButton(
          onPressed: () => Get.back(result: true),
          child: Text('common.remove'.tr),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
