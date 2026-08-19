import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<bool> confirmFavoriteRemoval() async {
  final confirmed = await Get.dialog<bool>(
    AlertDialog(
      title: const Text('Remove favorite?'),
      content: const Text(
        'Remove this meal from your favorites? You can add it again later.',
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
