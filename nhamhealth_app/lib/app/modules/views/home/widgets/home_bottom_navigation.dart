import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/home/home_controller.dart';

class HomeBottomNavigation extends GetView<HomeController> {
  const HomeBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) => Obx(
    () => AppBottomNavigation(
      selectedIndex: controller.selectedBottomIndex.value,
      onSelect: controller.selectBottomMenu,
    ),
  );
}
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const Color _inactiveGray = AppColors.inactiveText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 68,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2EBE5)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A203D2C),
                    blurRadius: 20,
                    offset: Offset(0, 7),
                  ),
                  BoxShadow(
                    color: Color(0x80FFFFFF),
                    blurRadius: 3,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          selected: selectedIndex == 0,
                          onTap: () => onSelect(0),
                        ),
                    _NavItem(
                          icon: Icons.restaurant_menu_rounded,
                          label: 'Meals',
                          selected: selectedIndex == 1,
                          onTap: () => onSelect(1),
                        ),
                    const SizedBox(width: 52),
                    _NavItem(
                          icon: Icons.people_outline_rounded,
                          selectedIcon: Icons.people_rounded,
                          label: 'Community',
                          selected: selectedIndex == 3,
                          onTap: () => onSelect(3),
                        ),
                    _NavItem(
                          icon: Icons.person_outline_rounded,
                          selectedIcon: Icons.person_rounded,
                          label: 'Profile',
                          selected: selectedIndex == 4,
                          onTap: () => onSelect(4),
                        ),
                  ],
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
                onTap: () => onSelect(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEAF7EE) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? selectedIcon ?? icon : icon,
                  color: selected
                      ? AppColors.primaryGreen
                      : AppBottomNavigation._inactiveGray,
                  size: 22,
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 12,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected
                            ? AppColors.darkGreen
                            : AppBottomNavigation._inactiveGray,
                        fontSize: 9,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    color:
                        selected
                            ? AppColors.primaryGreen
                            : AppColors.secondaryText,
                    fontSize: 10,
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
