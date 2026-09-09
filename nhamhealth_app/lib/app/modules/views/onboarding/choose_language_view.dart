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
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxHeight < 720;
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: AppSpacing.pagePadding,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight:
                                    constraints.maxHeight -
                                    AppSpacing.pageTop -
                                    AppSpacing.pageBottom,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: compact ? 22 : 34),
                                    Text(
                                      'language.title'.tr,
                                      style: const TextStyle(
                                        color: AppColors.darkGreen,
                                        fontSize: 38,
                                        height: 1.02,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'language.description'.tr,
                                      style: TextStyle(
                                        color: context.appMutedText,
                                        fontSize: 14,
                                        height: 1.4,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: compact ? 10 : 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: compact ? 170 : 220,
                                      child: Image.asset(
                                        'assets/images/onboarding/vagetables.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    SizedBox(height: compact ? 12 : 18),
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
                                    const Spacer(),
                                    SizedBox(height: compact ? 20 : 28),
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
                          );
                        },
                      ),
                    ),
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
