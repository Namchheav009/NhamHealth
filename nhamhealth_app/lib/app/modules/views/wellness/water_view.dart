import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_back_header.dart';

class WaterView extends StatelessWidget {
  const WaterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppBackButton.appBarToolbarHeight,
        leadingWidth: AppBackButton.appBarLeadingWidth,
        leading: AppBackButton.appBar(onPressed: Get.back),
        title: Text('Water'.tr),
      ),
      body: Center(child: Text('Water Detail Page'.tr)),
    );
  }
}
