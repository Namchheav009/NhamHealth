import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';

class AuthTabSwitcher extends StatelessWidget {
  const AuthTabSwitcher({
    super.key,
    required this.selectedIndex,
    required this.onLogin,
    required this.onRegister,
  });

  final int selectedIndex;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.appSurfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder, width: 1.2),
        boxShadow: context.appTileShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'Sign In',
              selected: selectedIndex == 0,
              onTap: onLogin,
            ),
          ),
          Expanded(
            child: _Tab(
              label: 'Sign Up',
              selected: selectedIndex == 1,
              onTap: onRegister,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Text(
              label.tr,
              style: TextStyle(
                color: selected ? Colors.white : context.appText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
