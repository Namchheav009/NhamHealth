import 'package:flutter/material.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../../theme/app_colors.dart';
import '../../../models/home/nutrition_progress_model.dart';

class NutritionProgressCard extends StatelessWidget {
  const NutritionProgressCard({
    super.key,
    required this.data,
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.showActionIndicator = false,
  });

  final NutritionProgressModel data;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool showActionIndicator;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appElevatedSurface.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side:
            context.appIsDark
                ? BorderSide(color: context.appBorder)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: iconColor),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      data.title.trOrSelf,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: context.appMutedText,
                      ),
                    ),
                  ),
                  if (showActionIndicator) ...[
                    const SizedBox(width: 3),
                    Icon(Icons.add_circle_rounded, size: 13, color: iconColor),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${data.value} / ${data.target}',
                maxLines: 1,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.appColorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: data.progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.appColorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
