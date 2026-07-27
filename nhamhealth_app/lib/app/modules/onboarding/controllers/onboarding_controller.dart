import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/onboarding_item.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();

  final RxInt currentPage = 0.obs;

  final List<OnboardingItem> items = const [
    OnboardingItem(
      imagePath: 'assets/images/onboarding/onboarding1.png',
      title: 'Affordable Organic\nGoodness',
      description:
          'Get affordable organic groceries made\n'
          'for everyone, every single day.',
    ),
    OnboardingItem(
      imagePath: 'assets/images/onboarding/onboarding2.png',
      title: 'Healthy Choices\nMade Simple',
      description:
          'Discover nutritious food and build healthy\n'
          'habits for a better everyday life.',
    ),
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  Future<void> nextPage() async {
    if (currentPage.value >= items.length - 1) {
      return;
    }

    await pageController.nextPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> previousPage() async {
    if (currentPage.value <= 0) {
      return;
    }

    await pageController.previousPage(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> skipToLastPage() async {
    await pageController.animateToPage(
      items.length - 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  void finishOnboarding() {
    // Add navigation here later.
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}