import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile/appearance_controller.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../theme/app_colors.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

class AppearanceView extends GetView<AppearanceController> {
  const AppearanceView({super.key});

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
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Pinned header (same pattern as setting_view) ──
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
                        title: 'profile.appearance',
                        onBack: controller.goBack,
                        backButtonKey: const ValueKey<String>(
                          'appearance-back-button',
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Scrollable content ──
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
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool isTablet}) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'profile.choose_how_nhamhealth_looks_on_this_device'.tr,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            height: 1.4,
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: isTablet ? 28 : 24),
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            'profile.theme'.tr,
            style: TextStyle(
              fontSize: isTablet ? 17 : 16,
              fontWeight: isTablet ? FontWeight.w700 : FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
        ),
        SizedBox(height: isTablet ? 12 : 10),
        _buildThemeCard(context, isTablet: isTablet),
      ],
    );
  }

  Widget _buildThemeCard(BuildContext context, {required bool isTablet}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(isTablet ? 22 : 18),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: context.appCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 21 : 17),
        child: Obx(
          () => Column(
            children: [
              _ThemeItem(
                icon: Icons.brightness_auto_rounded,
                title: 'profile.theme_system',
                subtitle: 'profile.theme_system_description',
                selected: controller.selectedTheme.value == 'system',
                onTap: controller.selectSystemMode,
                isTablet: isTablet,
              ),
              Padding(
                padding: EdgeInsets.only(left: isTablet ? 74 : 64),
                child: Divider(
                  height: 1,
                  thickness: 0.7,
                  color: colors.outlineVariant,
                ),
              ),
              _ThemeItem(
                icon: Icons.light_mode_outlined,
                title: 'profile.light_mode',
                subtitle: 'profile.light_theme_for_a_bright_experience',
                selected: controller.selectedTheme.value == 'light',
                onTap: controller.selectLightMode,
                isTablet: isTablet,
              ),
              Padding(
                padding: EdgeInsets.only(left: isTablet ? 74 : 64),
                child: Divider(
                  height: 1,
                  thickness: 0.7,
                  color: colors.outlineVariant,
                ),
              ),
              _ThemeItem(
                icon: Icons.dark_mode_outlined,
                title: 'profile.dark_mode',
                subtitle: 'profile.dark_theme_for_comfortable_viewing',
                selected: controller.selectedTheme.value == 'dark',
                onTap: controller.selectDarkMode,
                isTablet: isTablet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeItem extends StatelessWidget {
  const _ThemeItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.isTablet = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowHeight = isTablet ? 88.0 : 76.0;
    final iconBoxSize = isTablet ? 46.0 : 40.0;
    final iconSize = isTablet ? 26.0 : 23.0;
    final iconRadius = isTablet ? 15.0 : 13.0;
    final titleSize = isTablet ? 16.0 : 14.0;
    final subtitleSize = isTablet ? 12.5 : 11.0;
    return Semantics(
      button: true,
      selected: selected,
      label: title.trOrSelf,
      child: Material(
        color:
            selected
                ? colors.primaryContainer.withValues(alpha: isDark ? 0.4 : 0.5)
                : Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('theme-option-$title'),
          onTap: onTap,
          child: SizedBox(
            height: rowHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 13),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(iconRadius),
                      color:
                          selected
                              ? colors.primaryContainer
                              : context.appMutedSurface,
                    ),
                    child: Icon(
                      icon,
                      size: iconSize,
                      color:
                          selected
                              ? colors.primary
                              : colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.trOrSelf,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        SizedBox(height: isTablet ? 7 : 6),
                        Text(
                          subtitle.trOrSelf,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RadioCircle(selected: selected, isTablet: isTablet),
                ],
              ),
            ),
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
    final colors = Theme.of(context).colorScheme;
    final size = isTablet ? 25.0 : 22.0;
    final pad = isTablet ? 5.0 : 4.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surface,
        border: Border.all(
          color: selected ? colors.primary : colors.outline,
          width: 1.5,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? colors.primary : Colors.transparent,
        ),
      ),
    );
  }
}
