import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';

class EditInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showDivider;

  const EditInfoRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconBackground,
                    ),
                    child: Icon(icon, size: 19, color: iconColor),
                  ),

                  const SizedBox(width: 10),

                  SizedBox(
                    width: 90,
                    child: Text(
                      label.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appMutedText,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      value.tr,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: 5),

                  Icon(
                    Icons.chevron_right_rounded,
                    size: 23,
                    color: context.appMutedText,
                  ),
                ],
              ),
            ),

            if (showDivider)
              Padding(
                padding: const EdgeInsets.only(left: 57),
                child: Divider(
                  height: 1,
                  thickness: 0.7,
                  color: context.appBorder,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
