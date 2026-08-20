import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FiberView extends StatelessWidget {
  const FiberView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Fiber'),
      ),
      body: const Center(child: Text('Fiber Detail Page')),
    );
  }
}
