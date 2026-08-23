import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile/appearance_controller.dart';
import '../../../theme/app_spacing.dart';

class AppearanceView extends GetView<AppearanceController> {
  const AppearanceView({super.key});

  static const green = Color(0xFF00A651);
  static const darkGreen = Color(0xFF006B38);

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBFB),
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
                        Row(
                          children: [
                            GestureDetector(
                              onTap: controller.goBack,
                              behavior: HitTestBehavior.opaque,
                              child: const SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  size: 23,
                                  color: darkGreen,
                                ),
                              ),
                            ),

                            const SizedBox(width: 5),

                            const Text(
                              'Appearance',
                              style: TextStyle(
                                fontSize: 21,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          'Choose how NhamHealth looks on this device.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF687185),
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text(
                            'Theme',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF101010),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _buildThemeCard(),
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

  Widget _buildThemeCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EBE6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
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

            const Padding(
              padding: EdgeInsets.only(left: 64),
              child: Divider(
                height: 1,
                thickness: 0.7,
                color: Color(0xFFD7D9DC),
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
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeItem({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
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
          color: selected ? const Color(0xFFF0FAF3) : Colors.transparent,
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
                  color: iconBackground,
                ),
                child: Icon(icon, size: 23, color: iconColor),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF707788),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: selected ? AppearanceView.green : const Color(0xFFB9BDC4),
          width: 1.5,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? AppearanceView.green : Colors.transparent,
        ),
      ),
    );
  }
}

class _SettingsBackground extends StatelessWidget {
  const _SettingsBackground();

  @override
  Widget build(BuildContext context) {
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
