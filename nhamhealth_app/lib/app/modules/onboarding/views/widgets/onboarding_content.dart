import 'package:flutter/material.dart';

import '../../models/onboarding_item.dart';
import 'onboarding_indicator.dart';
import 'onboarding_next_button.dart';
import 'onboarding_skip_button.dart';

class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    super.key,
    required this.item,
    required this.activePage,
    required this.buttonText,
    required this.showSkipButton,
    required this.showBackButton,
    required this.onNext,
    required this.onSkip,
    required this.onBack,
  });

  final OnboardingItem item;
  final int activePage;
  final String buttonText;
  final bool showSkipButton;
  final bool showBackButton;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  double imageHeight(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    if (screenHeight < 700) {
      return screenHeight * 0.25;
    }

    if (screenHeight < 850) {
      return screenHeight * 0.29;
    }

    return screenHeight * 0.33;
  }

  double titleSize(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return 29;
    }

    return 36;
  }

  Widget buildHeader() {
  return Row(
    children: [
      Image.asset(
        'assets/icons/logo.png',
        width: 50,
        height: 50,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            width: 50,
            height: 50,
            child: Icon(
              Icons.eco_rounded,
              size: 38,
              color: Color(0xFF009B3E),
            ),
          );
        },
      ),

      const SizedBox(width: 8),

      RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'NHAM ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF5A73),
              ),
            ),
            TextSpan(
              text: 'HEALTH',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF009B3E),
              ),
            ),
          ],
        ),
      ),

      const Spacer(),

      if (showBackButton)
        IconButton(
          onPressed: onBack,
          tooltip: 'Back',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 30,
            color: Color(0xFF005B27),
          ),
        ),
    ],
  );
}

  Widget buildOnboardingImage({
    required String image,
    required double height,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Center(
        child: Image.asset(
          image,
          width: double.infinity,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.image_not_supported_outlined,
              size: 70,
              color: Colors.grey,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double onboardingImageHeight = imageHeight(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF4FFFA),
            Color(0xFFF7FFF5),
            Color(0xFFFFFEED),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.025),

              buildHeader(),

              Expanded(
                child: Column(
                  children: [
                    const Spacer(),

                    buildOnboardingImage(
                      image: item.imagePath,
                      height: onboardingImageHeight,
                    ),

                    SizedBox(height: screenHeight * 0.01),

                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleSize(context),
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF005B27),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      item.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A9A9A),
                      ),
                    ),

                    const Spacer(),
                  ],
                ),
              ),

              OnboardingIndicator(
                activePage: activePage,
                pageCount: 2,
              ),

              const SizedBox(height: 28),

              OnboardingNextButton(
                text: buttonText,
                onPressed: onNext,
              ),

              const SizedBox(height: 14),

              Visibility(
                visible: showSkipButton,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: OnboardingSkipButton(
                  onPressed: onSkip,
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}