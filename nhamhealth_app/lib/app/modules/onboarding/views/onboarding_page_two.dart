import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/onboarding_controller.dart';
import 'widgets/onboarding_content.dart';

class OnboardingPageTwo extends GetView<OnboardingController> {
  const OnboardingPageTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingContent(
      item: controller.items[1],
      activePage: 1,
      buttonText: 'Get Started',
      showSkipButton: false,
      showBackButton: true,
      onNext: controller.finishOnboarding,
      onSkip: controller.finishOnboarding,
      onBack: controller.previousPage,
    );
  }
}
