import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WaterView extends StatelessWidget {
  const WaterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Water'),
      ),
      body: const Center(
        child: Text('Water Detail Page'),
      ),
    );
  }
}