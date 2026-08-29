import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_back_header.dart';

class SugarView extends StatelessWidget {
  const SugarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppBackButton.appBarToolbarHeight,
        leadingWidth: AppBackButton.appBarLeadingWidth,
        leading: AppBackButton.appBar(onPressed: Get.back),
        title: Text('Sugar'.tr),
      ),
      body: Center(child: Text('Sugar Detail Page'.tr)),
    );
  }
}
