import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/onboarding/onboarding_controller.dart';
import 'onboarding_page_one.dart';
import 'onboarding_page_two.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: controller.pageController,
        onPageChanged: controller.onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: const [
          OnboardingPageOne(),
          OnboardingPageTwo(),
        ],
      ),
    );
  }
}
