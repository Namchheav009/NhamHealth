import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.backgroundMint, AppColors.backgroundCream],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 720;
                final imageHeight = (constraints.maxHeight *
                        (item.titleAboveImage ? 0.45 : 0.34))
                    .clamp(
                      compact ? 170.0 : 220.0,
                      item.titleAboveImage
                          ? (compact ? 310.0 : 380.0)
                          : (compact ? 250.0 : 290.0),
                    );

                return Padding(
                  padding: const EdgeInsets.fromLTRB(32, 26, 32, 40),
                  child: Column(
                    children: [
                      if (item.showBrandHeader)
                        _BrandHeader(
                          showBackButton: showBackButton,
                          onBack: onBack,
                        )
                      else
                        const SizedBox(height: 28),
                      if (item.titleAboveImage) ...[
                        const SizedBox(height: 8),
                        _TitleBlock(item: item, centered: false),
                      ],
                      Expanded(
                        child: Align(
                          alignment:
                              item.titleAboveImage
                                  ? Alignment.center
                                  : const Alignment(0, -0.35),
                          child: SizedBox(
                            width: double.infinity,
                            height: imageHeight,
                            child: Image.asset(
                              item.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (_, _, _) => const Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 70,
                                    color: AppColors.mutedText,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      if (!item.titleAboveImage) ...[
                        _TitleBlock(item: item, centered: true),
                        SizedBox(height: compact ? 16 : 24),
                      ],
                      OnboardingIndicator(activePage: activePage, pageCount: 2),
                      const SizedBox(height: 18),
                      OnboardingNextButton(text: buttonText, onPressed: onNext),
                      const SizedBox(height: 4),
                      Visibility(
                        visible: showSkipButton,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: OnboardingSkipButton(onPressed: onSkip),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.showBackButton, required this.onBack});

  final bool showBackButton;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Image.asset('assets/icons/logo.png', width: 26, height: 26),
          const SizedBox(width: 6),
          const Text(
            'NHAM ',
            style: TextStyle(
              color: AppColors.primaryPink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'HEALTH',
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          if (showBackButton)
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.darkGreen,
              ),
            ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.item, required this.centered});

  final OnboardingItem item;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              color: AppColors.darkGreen,
              fontSize: centered ? 32 : 36,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (item.accentTitle != null)
            Text(
              item.accentTitle!,
              style: const TextStyle(
                color: AppColors.accentOrange,
                fontSize: 34,
                height: 1.12,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            item.description,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
