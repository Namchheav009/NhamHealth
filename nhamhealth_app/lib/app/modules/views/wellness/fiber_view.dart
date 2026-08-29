import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_back_header.dart';

class FiberView extends StatelessWidget {
  const FiberView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppBackButton.appBarToolbarHeight,
        leadingWidth: AppBackButton.appBarLeadingWidth,
        leading: AppBackButton.appBar(onPressed: Get.back),
        title: Text('Fiber'.tr),
      ),
      body: Center(child: Text('Fiber Detail Page'.tr)),
    );
  }
}
