import 'package:flutter/material.dart';

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
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE4D9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'Login',
              selected: selectedIndex == 0,
              onTap: onLogin,
            ),
          ),
          Expanded(
            child: _Tab(
              label: 'Register',
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
    return Material(
      color: selected ? const Color(0xFF00A846) : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(13),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF5D625D),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
