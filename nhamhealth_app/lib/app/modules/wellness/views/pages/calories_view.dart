import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CaloriesView extends StatelessWidget {
  const CaloriesView({
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
          'Calories',
        ),
      ),
      body: const Center(
        child: Text(
          'Calories Detail Page',
        ),
      ),
    );
  }
}