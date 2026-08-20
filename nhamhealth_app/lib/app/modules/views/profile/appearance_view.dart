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
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBFB),
        body: Stack(
          children: [
            const _SettingsBackground(),

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageHorizontal,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 37),

                        // HEADER
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

                        const SizedBox(height: 43),

                        const Text(
                          'Customize the look and feel of the',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF687185),
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'app to suit your preference.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFF687185),
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 30),

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

                        const SizedBox(height: 14),

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
        borderRadius: BorderRadius.circular(13),
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
              subtitle: 'Dart theme for a comfortable viewing',
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
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(
        height: 70,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 9,
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
