import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../widgets/inner_shadow.dart';

class MoodCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const MoodCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child:
                      emoji.isEmpty
                          ? const Icon(
                            Icons.mood_rounded,
                            color: Color(0xFFFFB02E),
                            size: 28,
                          )
                          : Text(
                            emoji,
                            textScaler: TextScaler.noScaling,
                            style: const TextStyle(fontSize: 28, height: 1),
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
                      fontSize: 10.5,
                      color:
                          selected
                              ? AppColors.primaryGreen
                              : AppColors.primaryPink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 70,
      decoration: BoxDecoration(
        gradient:
            selected
                ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE9FAEF), Color(0xFFFFF1F5)],
                )
                : null,
        color: selected ? null : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primaryGreen : AppColors.border,
          width: selected ? 1.6 : 1,
        ),
        boxShadow:
            selected
                ? const [
                  BoxShadow(
                    color: Color(0x1F00A651),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
                : AppShadows.tile,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: InnerShadow(
            borderRadius: BorderRadius.circular(12),
            shadows: AppShadows.innerSurface,
            child: content,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: '$label mood',
      child: AnimatedScale(
        scale: selected ? 1.02 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: card,
      ),
    );
  }
}
