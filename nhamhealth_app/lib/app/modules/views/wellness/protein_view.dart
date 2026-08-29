import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_back_header.dart';

class ProteinView extends StatelessWidget {
  const ProteinView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppBackButton.appBarToolbarHeight,
        leadingWidth: AppBackButton.appBarLeadingWidth,
        leading: AppBackButton.appBar(onPressed: Get.back),
        title: Text('Protein'.tr),
      ),
      body: Center(child: Text('Protein Detail Page'.tr)),
    );
  }
}
