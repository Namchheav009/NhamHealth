import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile/appearance_controller.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../theme/app_colors.dart';

class AppearanceView extends GetView<AppearanceController> {
  const AppearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: AppBackground(
          child: SafeArea(
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
                      AppBackHeader(
                        title: 'Appearance',
                        onBack: controller.goBack,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Choose how NhamHealth looks on this device.'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          'Theme'.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildThemeCard(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: context.appCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Obx(
          () => Column(
            children: [
              _ThemeItem(
                icon: Icons.brightness_auto_rounded,
                title: 'theme_system',
                subtitle: 'theme_system_description',
                selected: controller.selectedTheme.value == 'system',
                onTap: controller.selectSystemMode,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 64),
                child: Divider(
                  height: 1,
                  thickness: 0.7,
                  color: colors.outlineVariant,
                ),
              ),
              _ThemeItem(
                icon: Icons.light_mode_outlined,
                title: 'Light Mode',
                subtitle: 'Light theme for a bright experience',
                selected: controller.selectedTheme.value == 'light',
                onTap: controller.selectLightMode,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 64),
                child: Divider(
                  height: 1,
                  thickness: 0.7,
                  color: colors.outlineVariant,
                ),
              ),
              _ThemeItem(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Dark theme for comfortable viewing',
                selected: controller.selectedTheme.value == 'dark',
                onTap: controller.selectDarkMode,
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      selected: selected,
      label: title.tr,
      child: Material(
        color:
            selected
                ? colors.primaryContainer.withValues(alpha: isDark ? 0.4 : 0.5)
                : Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('theme-option-$title'),
          onTap: onTap,
          child: SizedBox(
            height: 76,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color:
                          selected
                              ? colors.primaryContainer
                              : context.appMutedSurface,
                    ),
                    child: Icon(
                      icon,
                      size: 23,
                      color:
                          selected ? colors.primary : colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.tr,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RadioCircle(selected: selected),
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
  const _RadioCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      padding: const EdgeInsets.all(4),
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
