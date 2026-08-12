import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import 'inner_shadow.dart';

class MoodCard extends StatelessWidget {
  final String imageAsset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const MoodCard({
    super.key,
    required this.imageAsset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label mood',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 68,
        decoration: BoxDecoration(
          color: selected ? AppColors.softPink : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.softPinkBorder : AppColors.border,
          ),
          boxShadow: AppShadows.tile,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: InnerShadow(
              borderRadius: BorderRadius.circular(12),
              shadows: AppShadows.innerSurface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: Image.asset(
                          imageAsset,
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          excludeFromSemantics: true,
                          errorBuilder:
                              (_, _, _) => const Icon(
                                Icons.mood_rounded,
                                color: Color(0xFFFFB02E),
                                size: 28,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 16,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primaryPink,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
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
