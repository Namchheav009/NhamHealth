import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CarbohydratesView extends StatelessWidget {
  const CarbohydratesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Carbohydrates'.tr)),
      body: Center(child: Text('Carbohydrates Detail Page'.tr)),
    );
  }
}
