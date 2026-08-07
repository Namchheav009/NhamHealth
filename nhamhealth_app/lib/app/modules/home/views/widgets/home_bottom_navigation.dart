import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import 'inner_shadow.dart';

class HomeBottomNavigation extends GetView<HomeController> {
  const HomeBottomNavigation({super.key});

  static const Color _activeGreen = Color(0xFF35AD67);
  static const Color _inactiveGray = Color(0xFF929292);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedIndex = controller.selectedBottomIndex.value;

      return SizedBox(
        height: 84,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 64,
              child: PhysicalShape(
                clipper: const _NavigationBarClipper(),
                clipBehavior: Clip.antiAlias,
                color: Colors.white,
                shadowColor: Colors.black.withValues(alpha: 0.22),
                elevation: 10,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFFFFBFC),
                        Color(0xFFFFFFFF),
                        Color(0xFFFBFFF2),
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    foregroundPainter: const _NavigationBorderPainter(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _NavItem(
                            icon: Icons.home_rounded,
                            label: 'Home',
                            selected: selectedIndex == 0,
                            onTap: () => controller.selectBottomMenu(0),
                          ),
                          _NavItem(
                            icon: Icons.restaurant_menu_rounded,
                            label: 'Meals',
                            selected: selectedIndex == 1,
                            onTap: () => controller.selectBottomMenu(1),
                          ),
                          const SizedBox(width: 48),
                          _NavItem(
                            icon: Icons.people_outline_rounded,
                            selectedIcon: Icons.people_rounded,
                            label: 'Community',
                            selected: selectedIndex == 3,
                            onTap: () => controller.selectBottomMenu(3),
                          ),
                          _NavItem(
                            icon: Icons.person_outline_rounded,
                            selectedIcon: Icons.person_rounded,
                            label: 'Profile',
                            selected: selectedIndex == 4,
                            onTap: () => controller.selectBottomMenu(4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Center(
                child: _PostButton(
                  selected: selectedIndex == 2,
                  onTap: () => controller.selectBottomMenu(2),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

Path _navigationBarPath(Size size) {
  const cornerRadius = 28.0;
  const notchHalfWidth = 35.0;
  const notchDepth = 29.0;
  final center = size.width / 2;

  return Path()
    ..moveTo(cornerRadius, 0)
    ..lineTo(center - notchHalfWidth, 0)
    ..cubicTo(center - 27, 0, center - 29, notchDepth, center, notchDepth)
    ..cubicTo(
      center + 29,
      notchDepth,
      center + 27,
      0,
      center + notchHalfWidth,
      0,
    )
    ..lineTo(size.width - cornerRadius, 0)
    ..quadraticBezierTo(size.width, 0, size.width, cornerRadius)
    ..lineTo(size.width, size.height - cornerRadius)
    ..quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    )
    ..lineTo(cornerRadius, size.height)
    ..quadraticBezierTo(0, size.height, 0, size.height - cornerRadius)
    ..lineTo(0, cornerRadius)
    ..quadraticBezierTo(0, 0, cornerRadius, 0)
    ..close();
}

class _NavigationBarClipper extends CustomClipper<Path> {
  const _NavigationBarClipper();

  @override
  Path getClip(Size size) => _navigationBarPath(size);

  @override
  bool shouldReclip(covariant _NavigationBarClipper oldClipper) => false;
}

class _NavigationBorderPainter extends CustomPainter {
  const _NavigationBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _navigationBarPath(size),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _NavigationBorderPainter oldDelegate) => false;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedIcon,
  });

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
        child: InkWell(
          key: ValueKey<String>('nav-${label.toLowerCase()}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: selected ? 66 : 43,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  selected
                      ? HomeBottomNavigation._activeGreen
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(25),
              boxShadow:
                  selected
                      ? [
                        BoxShadow(
                          color: HomeBottomNavigation._activeGreen.withValues(
                            alpha: 0.22,
                          ),
                          blurRadius: 9,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: InnerShadow(
              borderRadius: BorderRadius.circular(25),
              shadows:
                  selected
                      ? const [
                        BoxShadow(
                          color: Color(0x26006231),
                          blurRadius: 7,
                          offset: Offset(-1, -1),
                        ),
                        BoxShadow(
                          color: Color(0x4D6AF09F),
                          blurRadius: 4,
                          offset: Offset(1, 1),
                        ),
                      ]
                      : const [],
              child: Center(
                child: Icon(
                  selected ? selectedIcon ?? icon : icon,
                  color:
                      selected
                          ? Colors.white
                          : HomeBottomNavigation._inactiveGray,
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  const _PostButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Post',
      child: Tooltip(
        message: 'Post',
        child: InkWell(
          key: const ValueKey<String>('nav-post'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            width: 52,
            height: 68,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF009B49),
                      width: 1.4,
                    ),
                    boxShadow: [
                      const BoxShadow(
                        color: Colors.white,
                        blurRadius: 0,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: const Color(0xFF009B49).withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const _PostPlusIcon(color: Color(0xFF009B49)),
                ),
                const SizedBox(height: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    color:
                        selected
                            ? const Color(0xFF009B49)
                            : HomeBottomNavigation._inactiveGray,
                    fontSize: 11,
                    height: 1,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: const Text('Post'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostPlusIcon extends StatelessWidget {
  const _PostPlusIcon({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 28,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            width: 5,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    );
  }
}
