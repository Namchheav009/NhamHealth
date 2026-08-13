import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AiMealAutoFillView extends StatelessWidget {
  const AiMealAutoFillView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
        ),
        title: const Text(
          'AI Meal Auto-Fill',
        ),
      ),
      body: const Center(
        child: Text(
          'AI Meal Auto-Fill Page',
        ),
      ),
    );
  }
}