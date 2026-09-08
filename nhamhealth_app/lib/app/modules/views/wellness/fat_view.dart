import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_back_header.dart';

class FatView extends StatelessWidget {
  const FatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppBackButton.appBarToolbarHeight,
        leadingWidth: AppBackButton.appBarLeadingWidth,
        leading: AppBackButton.appBar(onPressed: Get.back),
        title: Text('common.fat'.tr),
      ),
      body: Center(child: Text('wellness.fat_detail'.tr)),
    );
  }
}
