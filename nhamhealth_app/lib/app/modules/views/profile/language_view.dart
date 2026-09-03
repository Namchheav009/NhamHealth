import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile/language_controller.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/language_flag.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/forest_glow_background.dart';
import '../../../theme/app_colors.dart';

class LanguageView extends GetView<LanguageController> {
  const LanguageView({super.key});

  static const green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: Stack(
          children: [
            const _SettingsBackground(),

            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppBackHeader(
                              title: 'language'.tr,
                              onBack: controller.goBack,
                            ),

                            const SizedBox(height: 26),

                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                'language_choose'.tr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.appText,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                'language_description'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: context.appMutedText,
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            _buildLanguageCard(context),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildInfo(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Obx(
        () => Column(
          children: [
            _LanguageItem(
              languageCode: 'km',
              title: 'language_khmer'.tr,
              selected: controller.selectedLanguage.value == 'km',
              onTap: controller.selectKhmer,
            ),

            Padding(
              padding: const EdgeInsets.only(left: 64),
              child: Divider(
                height: 1,
                thickness: 0.7,
                color: context.appBorder,
              ),
            ),

            _LanguageItem(
              languageCode: 'en',
              title: 'language_english'.tr,
              selected: controller.selectedLanguage.value == 'en',
              onTap: controller.selectEnglish,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSoftGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded, color: green, size: 17),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'language_applied'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.appColorScheme.primary,
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  'language_applied_description'.tr,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    color: context.appMutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageItem extends StatelessWidget {
  final String languageCode;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageItem({
    required this.languageCode,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 76,
        decoration: BoxDecoration(
          color: selected ? context.appSoftGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              LanguageFlag(languageCode: languageCode, size: 40),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.appText,
                  ),
                ),
              ),

              _RadioCircle(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioCircle extends StatelessWidget {
  const _RadioCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.appSurface,
        border: Border.all(
          color: selected ? LanguageView.green : context.appBorder,
          width: 1.5,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? LanguageView.green : Colors.transparent,
        ),
      ),
    );
  }
}

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

  @override
  Widget build(BuildContext context) {
    if (context.appIsDark) {
      return const Positioned.fill(
        child: ForestGlowBackground(
          force: true,
          child: SizedBox.expand(),
        ),
      );
    }
    return Positioned.fill(
      child: const DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
