import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/favorites/favorites_controller.dart';
import '../../../../theme/app_colors.dart';

class FavoritesTabSwitcher extends StatelessWidget {
  const FavoritesTabSwitcher({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final FavoritesTab selected;
  final ValueChanged<FavoritesTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Foods',
            active: selected == FavoritesTab.foods,
            onTap: () => onChanged(FavoritesTab.foods),
          ),
          _Tab(
            label: 'Posts',
            active: selected == FavoritesTab.posts,
            onTap: () => onChanged(FavoritesTab.posts),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: active ? const Color(0xFF0AA653) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: Text(
            label.tr,
            style: TextStyle(
              color: active ? Colors.white : context.appText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
}
