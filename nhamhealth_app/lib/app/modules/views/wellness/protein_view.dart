import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProteinView extends StatelessWidget {
  const ProteinView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text('Protein'.tr),
      ),
      body: Center(child: Text('Protein Detail Page'.tr)),
    );
  }
}
