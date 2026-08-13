import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SugarView extends StatelessWidget {
  const SugarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Sugar'),
      ),
      body: const Center(
        child: Text('Sugar Detail Page'),
      ),
    );
  }
}