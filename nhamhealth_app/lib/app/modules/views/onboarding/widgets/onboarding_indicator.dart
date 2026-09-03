import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class OnboardingIndicator extends StatelessWidget {
  const OnboardingIndicator({
    super.key,
    required this.activePage,
    required this.pageCount,
    required this.onBack,
  });

  final int activePage;
  final int pageCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final bool isActive = index == activePage;

        return GestureDetector(
          onTap: index < activePage ? onBack : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(right: index == pageCount - 1 ? 0 : 6),
            width: isActive ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primaryGreen : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isActive ? AppColors.primaryGreen : AppColors.border,
              ),
            ),
          ),
        );
      }),
    );
  }
}
