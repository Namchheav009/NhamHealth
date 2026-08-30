import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile/appearance_controller.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';

class AppearanceView extends GetView<AppearanceController> {
  const AppearanceView({super.key});

  static const green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha:
                  Theme.of(context).brightness == Brightness.dark
                      ? 0.24
                      : 0.045,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          children: [
            _ThemeItem(
              icon: Icons.light_mode_outlined,
              iconBackground: const Color(0xFFE5F5E8),
              iconColor: green,
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
              iconBackground: const Color(0xFFF1F1F1),
              iconColor: const Color(0xFF555555),
              title: 'Dark Mode',
              subtitle: 'Dark theme for comfortable viewing',
              selected: controller.selectedTheme.value == 'dark',
              onTap: controller.selectDarkMode,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeItem extends StatelessWidget {
  const _ThemeItem({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 76,
        decoration: BoxDecoration(
          color:
              selected
                  ? colors.primaryContainer.withValues(
                    alpha: isDark ? 0.4 : 0.5,
                  )
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color:
                      isDark ? colors.surfaceContainerHighest : iconBackground,
                ),
                child: Icon(
                  icon,
                  size: 23,
                  color: isDark ? colors.primary : iconColor,
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

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: isDark ? 0.12 : 1,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background/bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          if (isDark) ColoredBox(color: Colors.black.withValues(alpha: 0.16)),
        ],
      ),
    );
  }
}
