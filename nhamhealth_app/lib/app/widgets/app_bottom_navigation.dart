import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Shared four-destination navigation used by the main app pages.
///
/// Indexes are Home (0), Meals (1), Community (2), and Settings (4).
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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox(
        height: AppSpacing.navigationBarHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 72,
              child: PhysicalShape(
                clipper: const _NavigationBarClipper(),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                shadowColor: const Color(0x1A31543F),
                elevation: 4,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.homeBackground,
                        AppColors.cardSurface,
                        AppColors.softGreen,
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    foregroundPainter: const _NavigationInnerShadowPainter(),
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
  const _NavigationInnerShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _navigationBarPath(size);
    canvas
      ..save()
      ..clipPath(path);

    _paintInsetShadow(
      canvas,
      path,
      color: const Color(0x14005C32),
      blurRadius: 9,
      offset: const Offset(-1, -1),
    );
    _paintInsetShadow(
      canvas,
      path,
      color: const Color(0x99FFFFFF),
      blurRadius: 6,
      offset: const Offset(1, 2),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
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
      false;
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
                  color: selected ? AppColors.softGreen : Colors.transparent,
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
                                  ? AppColors.navigationGreen
                                  : AppColors.inactiveText,
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
                        color: AppColors.inactiveText,
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
