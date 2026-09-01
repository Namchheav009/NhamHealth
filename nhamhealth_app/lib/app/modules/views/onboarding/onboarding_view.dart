import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/onboarding/onboarding_controller.dart';
import 'widgets/onboarding_content.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final items = controller.items;
    return Scaffold(
      body:
          items.isEmpty
              ? const SizedBox.shrink()
              : PageView.builder(
                controller: controller.pageController,
                itemCount: items.length,
                onPageChanged: controller.onPageChanged,
                physics: const BouncingScrollPhysics(),
                itemBuilder:
                    (context, index) => OnboardingContent(
                      item: items[index],
                      activePage: index,
                      pageCount: items.length,
                      buttonText:
                          index == items.length - 1 ? 'Get Started' : 'Next',
                      showSkipButton: index < items.length - 1,
                      showBackButton: index > 0,
                      onNext:
                          index == items.length - 1
                              ? controller.finishOnboarding
                              : controller.nextPage,
                      onSkip:
                          index == items.length - 1
                              ? controller.finishOnboarding
                              : controller.skipToLastPage,
                      onBack: controller.previousPage,
                    ),
              ),
    );
  }
}
