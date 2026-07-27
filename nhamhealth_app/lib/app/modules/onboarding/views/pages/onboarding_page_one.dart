import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/onboarding_controller.dart';
import '../widgets/onboarding_content.dart';

class OnboardingPageOne extends GetView<OnboardingController> {
  const OnboardingPageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingContent(
      item: controller.items[0],
      activePage: 0,
      buttonText: 'Next',
      showSkipButton: true,
      showBackButton: false,
      onNext: controller.nextPage,
      onSkip: controller.skipToLastPage,
      onBack: controller.previousPage,
    );
  }
}