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

  double _contentMaxWidth(BuildContext context) {
    final isTablet = AppSpacing.isTabletFor(context);
    if (isTablet) return AppSpacing.maxWideContentWidth;
    return AppSpacing.maxContentWidth;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = AppSpacing.isTabletFor(context);
    final hPad = AppSpacing.pageHorizontalFor(context);
    final maxWidth = _contentMaxWidth(context);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: Stack(
          children: [
            const _SettingsBackground(),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Pinned header (matches setting_view pattern)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      hPad,
                      AppSpacing.pageTop,
                      hPad,
                      0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: AppBackHeader(
                          title: 'settings.language'.tr,
                          onBack: controller.goBack,
                          backButtonKey: const ValueKey<String>(
                            'language-back-button',
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: _buildBody(context, isTablet: isTablet),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool isTablet}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;

        final selectionSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                'settings.language_choose'.tr,
                style: TextStyle(
                  fontSize: isTablet ? 17 : 13,
                  fontWeight: isTablet ? FontWeight.w700 : FontWeight.w600,
                  color: context.appText,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 14 : 12),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                'settings.language_description'.tr,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w400,
                  color: context.appMutedText,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 22 : 18),
            _buildLanguageCard(context, isTablet: isTablet),
          ],
        );

        if (isWide) {
          return Row(
            key: const ValueKey<String>('language-tablet-two-column'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: selectionSection),
              const SizedBox(width: 24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildInfo(context, isTablet: isTablet),
                ),
              ),
            ],
          );
        }

        return Column(
          key: const ValueKey<String>('language-single-column'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            selectionSection,
            SizedBox(height: isTablet ? 28 : 24),
            _buildInfo(context, isTablet: isTablet),
          ],
        );
      },
    );
  }

  Widget _buildLanguageCard(BuildContext context, {required bool isTablet}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(isTablet ? 22 : 18),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 21 : 17),
        child: Obx(
          () => Column(
            children: [
              _LanguageItem(
                languageCode: 'km',
                title: 'settings.language_khmer'.tr,
                selected: controller.selectedLanguage.value == 'km',
                onTap: controller.selectKhmer,
                isTablet: isTablet,
              ),
              Padding(
                padding: EdgeInsets.only(left: isTablet ? 76 : 64),
                child: Divider(
                  height: 1,
                  thickness: 0.7,
                  color: context.appBorder,
                ),
              ),
              _LanguageItem(
                languageCode: 'en',
                title: 'settings.language_english'.tr,
                selected: controller.selectedLanguage.value == 'en',
                onTap: controller.selectEnglish,
                isTablet: isTablet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context, {required bool isTablet}) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 18 : 14),
      decoration: BoxDecoration(
        color: context.appSoftGreen,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline_rounded,
              color: green,
              size: isTablet ? 21 : 17,
            ),
          ),
          SizedBox(width: isTablet ? 12 : 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'settings.language_applied'.tr,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w700,
                    color: context.appColorScheme.primary,
                  ),
                ),
                SizedBox(height: isTablet ? 8 : 6),
                Text(
                  'settings.language_applied_description'.tr,
                  style: TextStyle(
                    fontSize: isTablet ? 12.5 : 11,
                    height: 1.35,
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
  final bool isTablet;

  const _LanguageItem({
    required this.languageCode,
    required this.title,
    required this.selected,
    required this.onTap,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final rowHeight = isTablet ? 88.0 : 76.0;
    final flagSize = isTablet ? 48.0 : 40.0;
    final titleSize = isTablet ? 16.0 : 14.0;
    final borderRadius = BorderRadius.circular(isTablet ? 21 : 17);

    return InkWell(
      key: ValueKey<String>('language-option-$languageCode'),
      onTap: onTap,
      borderRadius: borderRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: rowHeight,
        decoration: BoxDecoration(
          color: selected ? context.appSoftGreen : Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 13),
          child: Row(
            children: [
              LanguageFlag(languageCode: languageCode, size: flagSize),
              SizedBox(width: isTablet ? 16 : 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: context.appText,
                  ),
                ),
              ),
              _RadioCircle(selected: selected, isTablet: isTablet),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioCircle extends StatelessWidget {
  const _RadioCircle({required this.selected, this.isTablet = false});

  final bool selected;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final size = isTablet ? 25.0 : 22.0;
    final pad = isTablet ? 5.0 : 4.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      padding: EdgeInsets.all(pad),
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
        child: ForestGlowBackground(force: true, child: SizedBox.expand()),
      );
    }
    return const Positioned.fill(
      child: DecoratedBox(
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
