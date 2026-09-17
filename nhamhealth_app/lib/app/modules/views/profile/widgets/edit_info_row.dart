import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_colors.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

class EditInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool showDivider;
  final Widget? trailing;

  const EditInfoRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    this.onTap,
    this.showDivider = true,
    this.trailing,
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
                      label.trOrSelf,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appMutedText,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Text(
                      value.trOrSelf,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],

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

class InlineEditInfoRow extends StatelessWidget {
  const InlineEditInfoRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hintText,
    this.suffixText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLength,
    this.trailing,
    this.onFieldSubmitted,
    this.showDivider = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final String? suffixText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final Widget? trailing;
  final ValueChanged<String>? onFieldSubmitted;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Color.alphaBlend(
                            iconBackground.withValues(alpha: 0.18),
                            context.appElevatedSurface,
                          )
                          : iconBackground,
                ),
                child: Icon(icon, size: 19, color: iconColor),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 90,
                child: Text(
                  label.trOrSelf,
                  style: TextStyle(fontSize: 12, color: context.appMutedText),
                ),
              ),
              Expanded(
                child: TextFormField(
                  initialValue: initialValue,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  maxLength: maxLength,
                  onFieldSubmitted: onFieldSubmitted,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appText,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hintText,
                    suffixText: suffixText,
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 57),
            child: Divider(height: 1, thickness: 0.7, color: context.appBorder),
          ),
      ],
    );
  }
}
