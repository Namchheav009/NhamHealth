import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/language_flag.dart';
import '../../controllers/onboarding/choose_language_controller.dart';
import 'widgets/onboarding_next_button.dart';

class ChooseLanguageView extends GetView<ChooseLanguageController> {
  const ChooseLanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Builder(
        builder:
            (context) => Scaffold(
              body: AppBackground(
                lightDecoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.backgroundMint,
                      AppColors.backgroundCream,
                    ],
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
                        return _ChooseLanguageWideLayout(
                          key: const ValueKey<String>(
                            'choose-language-tablet-layout',
                          ),
                          controller: controller,
                        );
                      }

                      return _ChooseLanguageStandardLayout(
                        controller: controller,
                        isTablet: isTablet,
                        constraints: constraints,
                      );
                    },
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class _ChooseLanguageWideLayout extends StatelessWidget {
  const _ChooseLanguageWideLayout({
    super.key,
    required this.controller,
  });

  final ChooseLanguageController controller;

  @override
  Widget build(BuildContext context) {
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
              // Left Column: Header & Illustration
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'language.title'.tr,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 38,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'language.description'.tr,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child: Image.asset(
                            'assets/images/onboarding/vagetables.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right Column: Language Choice Cards & Actions
              Expanded(
                flex: 5,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Obx(
                            () => Column(
                              children: [
                                _LanguageChoiceCard(
                                  key: const Key(
                                    'choose-language-english',
                                  ),
                                  languageCode: 'en',
                                  title: 'language.english'.tr,
                                  caption:
                                      'language.english_caption'.tr,
                                  selected:
                                      controller
                                          .selectedLanguage
                                          .value ==
                                      'en',
                                  onTap: controller.selectEnglish,
                                ),
                                const SizedBox(height: 14),
                                _LanguageChoiceCard(
                                  key: const Key(
                                    'choose-language-khmer',
                                  ),
                                  languageCode: 'km',
                                  title: 'language.khmer'.tr,
                                  caption:
                                      'language.khmer_caption'.tr,
                                  selected:
                                      controller
                                          .selectedLanguage
                                          .value ==
                                      'km',
                                  onTap: controller.selectKhmer,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Obx(
                            () => OnboardingNextButton(
                              text:
                                  controller.isContinuing.value
                                      ? 'language.loading'.tr
                                      : 'language.next'.tr,
                              onPressed:
                                  controller.isContinuing.value
                                      ? () {}
                                      : controller
                                          .continueToOnboarding,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              key: const Key('choose-language-skip'),
                              onPressed: controller.skipForNow,
                              child: Text(
                                'language.skip'.tr,
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
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
}

class _ChooseLanguageStandardLayout extends StatelessWidget {
  const _ChooseLanguageStandardLayout({
    required this.controller,
    required this.isTablet,
    required this.constraints,
  });

  final ChooseLanguageController controller;
  final bool isTablet;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final compact = constraints.maxHeight < 720;
    final maxContentWidth = isTablet ? 560.0 : 480.0;
    final contentPadding = isTablet
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.tabletPageHorizontal,
            vertical: AppSpacing.pageTop,
          )
        : AppSpacing.pagePadding;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: contentPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  constraints.maxHeight -
                  contentPadding.top -
                  contentPadding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment:
                    isTablet ? MainAxisAlignment.center : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isTablet ? 12 : (compact ? 22 : 34)),
                  Text(
                    'language.title'.tr,
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: isTablet ? 42 : 38,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'language.description'.tr,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: isTablet ? 15 : 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : (compact ? 10 : 16)),
                  SizedBox(
                    width: double.infinity,
                    height: isTablet ? 260 : (compact ? 170 : 220),
                    child: Image.asset(
                      'assets/images/onboarding/vagetables.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : (compact ? 12 : 18)),
                  Obx(
                    () => Column(
                      children: [
                        _LanguageChoiceCard(
                          key: const Key(
                            'choose-language-english',
                          ),
                          languageCode: 'en',
                          title: 'language.english'.tr,
                          caption:
                              'language.english_caption'.tr,
                          selected:
                              controller
                                  .selectedLanguage
                                  .value ==
                              'en',
                          onTap: controller.selectEnglish,
                        ),
                        const SizedBox(height: 12),
                        _LanguageChoiceCard(
                          key: const Key(
                            'choose-language-khmer',
                          ),
                          languageCode: 'km',
                          title: 'language.khmer'.tr,
                          caption:
                              'language.khmer_caption'.tr,
                          selected:
                              controller
                                  .selectedLanguage
                                  .value ==
                              'km',
                          onTap: controller.selectKhmer,
                        ),
                      ],
                    ),
                  ),
                  if (isTablet)
                    const SizedBox(height: 32)
                  else ...[
                    const Spacer(),
                    SizedBox(height: compact ? 20 : 28),
                  ],
                  Obx(
                    () => OnboardingNextButton(
                      text:
                          controller.isContinuing.value
                              ? 'language.loading'.tr
                              : 'language.next'.tr,
                      onPressed:
                          controller.isContinuing.value
                              ? () {}
                              : controller
                                  .continueToOnboarding,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      key: const Key('choose-language-skip'),
                      onPressed: controller.skipForNow,
                      child: Text(
                        'language.skip'.tr,
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageChoiceCard extends StatelessWidget {
  const _LanguageChoiceCard({
    super.key,
    required this.languageCode,
    required this.title,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final String languageCode;
  final String title;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: selected ? 0.84 : 0.72),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.primaryGreen : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkGreen.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                LanguageFlag(languageCode: languageCode, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        caption,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color:
                        selected ? AppColors.primaryGreen : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          selected
                              ? AppColors.primaryGreen
                              : AppColors.placeholder,
                      width: 1.5,
                    ),
                  ),
                  child:
                      selected
                          ? const Icon(
                            Icons.check_rounded,
                            size: 19,
                            color: Colors.white,
                          )
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
