import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 78.0 : 94.0;
    final titleSize = compact ? 21.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icons/logo.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
        SizedBox(height: compact ? 7 : 10),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.1,
            ),
            children: const [
              TextSpan(
                text: 'NHAM ',
                style: TextStyle(color: AppColors.primaryPink),
              ),
              TextSpan(
                text: 'HEALTH',
                style: TextStyle(color: AppColors.primaryGreen),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
