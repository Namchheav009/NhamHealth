import 'package:flutter/material.dart';

/// Reveals text once, without changing its final layout height while typing.
/// The complete value remains available to accessibility services throughout.
class AnimatedRevealText extends StatefulWidget {
  const AnimatedRevealText({
    required this.text,
    this.style,
    this.textAlign,
    this.duration = const Duration(milliseconds: 900),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.maxLines,
    this.overflow,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  State<AnimatedRevealText> createState() => _AnimatedRevealTextState();
}

class _AnimatedRevealTextState extends State<AnimatedRevealText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration)
      ..forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedRevealText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.duration != widget.duration ||
        oldWidget.delay != widget.delay) {
      _controller.duration = _totalDuration;
      _controller.forward(from: 0);
    }
  }

  Duration get _totalDuration => widget.delay + widget.duration;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations || widget.text.isEmpty) return _fullText();

    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final delayFraction =
              widget.delay.inMicroseconds /
              _totalDuration.inMicroseconds.clamp(1, double.maxFinite);
          final rawProgress =
              ((_controller.value - delayFraction) / (1 - delayFraction))
                  .clamp(0.0, 1.0);
          final progress = widget.curve.transform(rawProgress);
          final chunks = RegExp(
            r'\S+\s*',
          ).allMatches(widget.text).map((match) => match.group(0)!).toList();
          final visibleChunks = (chunks.length * progress).round();
          final visibleText = chunks.take(visibleChunks).join();
          return Stack(
            children: [
              Opacity(opacity: 0, child: _fullText()),
              Text(
                visibleText,
                style: widget.style,
                textAlign: widget.textAlign,
                maxLines: widget.maxLines,
                overflow: widget.overflow,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _fullText() => Text(
    widget.text,
    style: widget.style,
    textAlign: widget.textAlign,
    maxLines: widget.maxLines,
    overflow: widget.overflow,
  );
}
