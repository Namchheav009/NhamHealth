import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../modules/bindings/assistant/assistant_binding.dart';
import '../modules/views/assistant/assistant_view.dart';
import '../theme/app_spacing.dart';

/// Shared four-destination navigation used by the main app pages.
///
/// Indexes are Home (0), Meals (1), Community (2), and Settings (4). The
/// AI assistant is a separate action positioned to the right of the bar.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox(
        height: AppSpacing.navigationBarHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 80,
              bottom: 0,
              height: 72,
              child: PhysicalShape(
                clipper: const _NavigationBarClipper(),
                clipBehavior: Clip.antiAlias,
                color: colors.surface,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                elevation: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        colors.surface,
                        colors.surfaceContainer,
                        Color.alphaBlend(
                          colors.primary.withValues(
                            alpha: isDark ? 0.12 : 0.06,
                          ),
                          colors.surface,
                        ),
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    foregroundPainter: _NavigationInnerShadowPainter(
                      isDark: isDark,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        children: [
                          _NavSlot(
                            child: _NavItem(
                              id: 'home',
                              icon: Icons.home_rounded,
                              label: 'home'.tr,
                              selected: selectedIndex == 0,
                              onTap: () => onSelect(0),
                            ),
                          ),
                          _NavSlot(
                            child: _NavItem(
                              id: 'meals',
                              icon: Icons.restaurant_menu_rounded,
                              label: 'meals'.tr,
                              selected: selectedIndex == 1,
                              onTap: () => onSelect(1),
                            ),
                          ),
                          _NavSlot(
                            child: _NavItem(
                              id: 'community',
                              icon: Icons.people_outline_rounded,
                              selectedIcon: Icons.people_rounded,
                              label: 'community'.tr,
                              selected: selectedIndex == 2,
                              onTap: () => onSelect(2),
                            ),
                          ),
                          _NavSlot(
                            child: _NavItem(
                              id: 'settings',
                              icon: Icons.settings_outlined,
                              selectedIcon: Icons.settings_rounded,
                              label: 'settings'.tr,
                              selected: selectedIndex == 4,
                              onTap: () => onSelect(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(right: 0, bottom: 0, child: const _ChatbotButton()),
          ],
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Center(child: child));
  }
}

Path _navigationBarPath(Size size) {
  const cornerRadius = 36.0;
  return Path()..addRRect(
    RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(cornerRadius),
    ),
  );
}

class _NavigationBarClipper extends CustomClipper<Path> {
  const _NavigationBarClipper();

  @override
  Path getClip(Size size) => _navigationBarPath(size);

  @override
  bool shouldReclip(covariant _NavigationBarClipper oldClipper) => false;
}

class _NavigationInnerShadowPainter extends CustomPainter {
  const _NavigationInnerShadowPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _navigationBarPath(size);
    canvas
      ..save()
      ..clipPath(path);

    _paintInsetShadow(
      canvas,
      path,
      color: isDark ? const Color(0x66000000) : const Color(0x14005C32),
      blurRadius: 9,
      offset: const Offset(-1, -1),
    );
    _paintInsetShadow(
      canvas,
      path,
      color: isDark ? const Color(0x1839D879) : const Color(0x99FFFFFF),
      blurRadius: 6,
      offset: const Offset(1, 2),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color =
            isDark
                ? const Color(0xFF35483B)
                : Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  void _paintInsetShadow(
    Canvas canvas,
    Path path, {
    required Color color,
    required double blurRadius,
    required Offset offset,
  }) {
    canvas.drawPath(
      path.shift(offset),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = blurRadius * 1.7
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius * 0.58),
    );
  }

  @override
  bool shouldRepaint(covariant _NavigationInnerShadowPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedIcon,
  });

  final String id;
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey<String>('nav-$id'),
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: SizedBox(
              width: double.infinity,
              height: 72,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? colors.primaryContainer.withValues(alpha: 0.42)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(31),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension: 27,
                      child: Center(
                        child: Icon(
                          selected ? selectedIcon ?? icon : icon,
                          color:
                              selected
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                          size: 27,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color:
                            selected ? colors.primary : colors.onSurfaceVariant,
                        fontSize: 11,
                        height: 1,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.05,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatbotButton extends StatelessWidget {
  const _ChatbotButton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Open AI Assistant'.tr,
      child: Tooltip(
        message: 'Chat with AI Assistant'.tr,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey<String>('nav-chatbot'),
            onTap:
                () => Get.to<void>(
                  () => const AssistantView(),
                  binding: AssistantBinding(),
                  transition: Transition.rightToLeft,
                ),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Transform.scale(
                        scale: 1.25,
                        child: RepaintBoundary(
                          child: Lottie.asset(
                            'assets/animations/chatbot.json',
                            fit: BoxFit.contain,
                            repeat: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF39D879),
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x4439D879), blurRadius: 5),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33075E2D),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 13,
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
