import 'package:flutter/material.dart';

class OnboardingIndicator extends StatelessWidget {
  const OnboardingIndicator({
    super.key,
    required this.activePage,
    required this.pageCount,
  });

  final int activePage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) {
          final bool isActive = index == activePage;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(
              right: index == pageCount - 1 ? 0 : 10,
            ),
            width: isActive ? 36 : 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF009B3E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF009B3E)
                    : const Color(0xFFE0E0E0),
              ),
            ),
          );
        },
      ),
    );
  }
}