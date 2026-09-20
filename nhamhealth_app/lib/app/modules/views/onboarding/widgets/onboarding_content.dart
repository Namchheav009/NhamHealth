import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_background.dart';
import '../../../models/onboarding/onboarding_item.dart';
import 'onboarding_indicator.dart';
import 'onboarding_next_button.dart';
import 'onboarding_skip_button.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

class OnboardingContent extends StatelessWidget {
  const OnboardingContent({
    super.key,
    required this.item,
    required this.activePage,
    this.pageCount = 2,
    required this.buttonText,
    required this.showSkipButton,
    required this.onNext,
    required this.onSkip,
    required this.onBack,
  });

  final OnboardingItem item;
  final int activePage;
  final int pageCount;
  final String buttonText;
  final bool showSkipButton;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Builder(
        builder:
            (context) => AppBackground(
              lightDecoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.backgroundMint, AppColors.backgroundCream],
                ),
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                      final isLandscape =
                          constraints.maxWidth > constraints.maxHeight;
                      final isTablet =
                          AppSpacing.isTabletFor(context) ||
                          constraints.maxWidth >= AppSpacing.tabletBreakpoint;
                      final isWide =
                          (constraints.maxWidth >=
                                  AppSpacing.twoColumnBreakpoint &&
                              isLandscape) ||
                          constraints.maxWidth >= 840;

                      if (isWide) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSpacing.maxWideContentWidth,
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.tabletPageHorizontal,
                                vertical: AppSpacing.pageTop,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Left Column: Illustration
                                  Expanded(
                                    flex: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 28),
                                      child: Center(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxHeight: 340,
                                          ),
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
                                  ),
                                  // Right Column: Title, Indicator, Actions
                                  Expanded(
                                    flex: 5,
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 440,
                                        ),
                                        child: SingleChildScrollView(
                                          physics: const BouncingScrollPhysics(),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              _TitleBlock(
                                                item: item,
                                                centered: false,
                                              ),
                                              const SizedBox(height: 28),
                                              OnboardingIndicator(
                                                activePage: activePage,
                                                pageCount: pageCount,
                                                onBack: onBack,
                                              ),
                                              const SizedBox(height: 24),
                                              OnboardingNextButton(
                                                text: buttonText,
                                                onPressed: onNext,
                                              ),
                                              const SizedBox(height: 4),
                                              Visibility(
                                                visible: showSkipButton,
                                                maintainSize: true,
                                                maintainAnimation: true,
                                                maintainState: true,
                                                child: OnboardingSkipButton(
                                                  onPressed: onSkip,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final compact = constraints.maxHeight < 720;
                      final maxContentWidth = isTablet ? 560.0 : 480.0;
                      final contentPadding = isTablet
                          ? const EdgeInsets.symmetric(
                              horizontal: AppSpacing.tabletPageHorizontal,
                              vertical: AppSpacing.pageTop,
                            )
                          : AppSpacing.pagePadding;
                      final imageHeight = (constraints.maxHeight *
                              (item.titleAboveImage ? 0.45 : 0.34))
                          .clamp(
                            compact ? 170.0 : 220.0,
                            item.titleAboveImage
                                ? (compact
                                    ? 310.0
                                    : (isTablet ? 420.0 : 380.0))
                                : (compact
                                    ? 250.0
                                    : (isTablet ? 340.0 : 290.0)),
                          );

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxContentWidth),
                          child: Padding(
                            padding: contentPadding,
                            child: Column(
                              children: [
                                if (item.titleAboveImage) ...[
                                  SizedBox(height: isTablet ? 16 : 8),
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
                                              Icons
                                                  .image_not_supported_outlined,
                                              size: 70,
                                              color: AppColors.mutedText,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (!item.titleAboveImage) ...[
                                  _TitleBlock(item: item, centered: true),
                                  SizedBox(
                                    height: compact
                                        ? 16
                                        : (isTablet ? 28 : 24),
                                  ),
                                ],
                                OnboardingIndicator(
                                  activePage: activePage,
                                  pageCount: pageCount,
                                  onBack: onBack,
                                ),
                                SizedBox(height: isTablet ? 24 : 18),
                                OnboardingNextButton(
                                  text: buttonText,
                                  onPressed: onNext,
                                ),
                                const SizedBox(height: 4),
                                Visibility(
                                  visible: showSkipButton,
                                  maintainSize: true,
                                  maintainAnimation: true,
                                  maintainState: true,
                                  child: OnboardingSkipButton(
                                    onPressed: onSkip,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
            item.title.trOrSelf,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              color: context.appText,
              fontSize: centered ? 32 : 36,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (item.accentTitle != null)
            Text(
              item.accentTitle!.trOrSelf,
              style: const TextStyle(
                color: AppColors.accentOrange,
                fontSize: 34,
                height: 1.12,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            item.description.trOrSelf,
            textAlign: centered ? TextAlign.center : TextAlign.left,
            style: TextStyle(
              color: context.appMutedText,
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
