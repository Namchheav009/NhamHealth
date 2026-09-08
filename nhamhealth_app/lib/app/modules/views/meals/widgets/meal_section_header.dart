import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

class MealSectionHeader extends StatelessWidget {
  const MealSectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.actionLabel = 'meals.see_all',
    this.actionEnabled = true,
  });

  final String title;
  final VoidCallback? onSeeAll;
  final String actionLabel;
  final bool actionEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.trOrSelf,
            style: TextStyle(
              color: context.appText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: actionEnabled ? onSeeAll : null,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel.trOrSelf,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
