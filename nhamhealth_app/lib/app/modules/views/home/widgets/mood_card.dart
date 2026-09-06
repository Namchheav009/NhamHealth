import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/inner_shadow.dart';

class MoodCard extends StatefulWidget {
  final String emoji;
  final String label;
  final bool selected;
  final bool invalid;
  final int validationPulse;
  final VoidCallback onTap;

  const MoodCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    this.invalid = false,
    this.validationPulse = 0,
    required this.onTap,
  });

  @override
  State<MoodCard> createState() => _MoodCardState();
}

class _MoodCardState extends State<MoodCard>
    with SingleTickerProviderStateMixin {
  static const _errorRed = Color(0xFFE54855);
  late final AnimationController _validationController;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _validationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -7), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7, end: 7), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _validationController, curve: Curves.easeOut),
    );
    if (widget.invalid) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _playValidation());
    }
  }

  @override
  void didUpdateWidget(covariant MoodCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.invalid &&
        (!oldWidget.invalid ||
            widget.validationPulse != oldWidget.validationPulse)) {
      _playValidation();
    } else if (!widget.invalid && oldWidget.invalid) {
      _validationController.stop();
    }
  }

  void _playValidation() {
    if (!mounted) return;
    _validationController.forward(from: 0);
  }

  @override
  void dispose() {
    _validationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder:
                      (child, animation) => ScaleTransition(
                        scale: animation,
                        child: RotationTransition(
                          turns: Tween<double>(
                            begin: -0.04,
                            end: 0,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                  child: Center(
                    key: ValueKey(
                      '${widget.emoji}-${widget.selected}-${widget.invalid}',
                    ),
                    child:
                        widget.emoji.isEmpty
                            ? Icon(
                              Icons.mood_rounded,
                              color: const Color(0xFFFFB02E),
                              size: 28,
                            )
                            : Text(
                              widget.emoji,
                              textScaler: TextScaler.noScaling,
                              style: const TextStyle(fontSize: 28, height: 1),
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
                    widget.label.tr,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10.5,
                      color:
                          widget.selected
                              ? context.appColorScheme.primary
                              : context.appColorScheme.secondary,
                      fontWeight:
                          widget.selected || widget.invalid
                              ? FontWeight.w700
                              : FontWeight.w500,
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
      duration:
          widget.invalid ? Duration.zero : const Duration(milliseconds: 200),
      width: 70,
      decoration: BoxDecoration(
        gradient:
            widget.selected
                ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [context.appSoftGreen, context.appSoftPink],
                )
                : null,
        color: widget.selected ? null : context.appElevatedSurface,
        borderRadius: BorderRadius.circular(12),
        border:
            widget.invalid
                ? Border.all(color: _errorRed, width: 1.8)
                : isDark
                ? Border.all(
                  color:
                      widget.selected
                          ? context.appColorScheme.primary
                          : context.appBorder,
                  width: widget.selected ? 1.6 : 1,
                )
                : null,
        boxShadow:
            !isDark
                ? widget.selected
                    ? [
                      BoxShadow(
                        color: context.appColorScheme.primary.withValues(
                          alpha: 0.13,
                        ),
                        blurRadius: 11,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : context.appHomeTileShadow
                : widget.selected
                ? [
                  BoxShadow(
                    color: context.appColorScheme.primary.withValues(
                      alpha: 0.18,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                : context.appTileShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: InnerShadow(
            borderRadius: BorderRadius.circular(12),
            shadows: isDark ? context.appInnerShadow : const [],
            child: content,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: widget.selected,
      label:
          widget.invalid
              ? 'Choose a mood. ${widget.label.tr}'.tr
              : '@mood mood'.trParams({'mood': widget.label.tr}),
      child: AnimatedBuilder(
        animation: _shake,
        child: AnimatedScale(
          scale: widget.selected ? 1.02 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: card,
        ),
        builder:
            (context, child) => Transform.translate(
              offset: Offset(_shake.value, 0),
              child: child,
            ),
      ),
    );
  }
}
