import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../../theme/app_colors.dart';

class MoodCard extends StatefulWidget {
  const MoodCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
    this.invalid = false,
    this.validationPulse = 0,
  });

  final String emoji;
  final String label;
  final bool selected;
  final bool invalid;
  final int validationPulse;
  final VoidCallback onTap;

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
    }
  }

  void _playValidation() {
    if (mounted) _validationController.forward(from: 0);
  }

  @override
  void dispose() {
    _validationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.invalid
        ? _errorRed
        : context.appColorScheme.primary;
    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              AnimatedScale(
                scale: widget.selected ? 1.08 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: widget.emoji.isEmpty
                        ? const Icon(
                            Icons.mood_rounded,
                            color: Color(0xFFFFB02E),
                            size: 32,
                          )
                        : Text(
                            widget.emoji,
                            textScaler: TextScaler.noScaling,
                            style: const TextStyle(fontSize: 32, height: 1),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.label.trOrSelf,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.selected ? accent : context.appText,
                  fontSize: 10.5,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: widget.selected || widget.invalid ? 30 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.invalid
          ? 'home.choose_mood_label'.trParams({
              'mood': widget.label.trOrSelf,
            })
          : 'home.mood_mood'.trParams({'mood': widget.label.trOrSelf}),
      child: AnimatedBuilder(
        animation: _shake,
        child: item,
        builder: (context, child) => Transform.translate(
          offset: Offset(_shake.value, 0),
          child: child,
        ),
      ),
    );
  }
}
