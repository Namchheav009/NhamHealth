import 'package:flutter/material.dart';

class LoadingContentTransition extends StatelessWidget {
  const LoadingContentTransition({
    super.key,
    required this.isLoading,
    required this.loading,
    required this.content,
  });

  final bool isLoading;
  final Widget loading;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 360),
      reverseDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder:
          (currentChild, previousChildren) => Stack(
            alignment: Alignment.topCenter,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
      transitionBuilder: (child, animation) {
        final isContent = child.key == const ValueKey('loaded-content');
        if (reduceMotion) return child;

        final fade = CurvedAnimation(
          parent: animation,
          curve:
              isContent
                  ? const Interval(0, .72, curve: Curves.easeOut)
                  : Curves.easeOut,
        );
        final slide = Tween<Offset>(
          begin: Offset(0, isContent ? .065 : 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: isContent ? Curves.easeOutBack : Curves.easeOut,
          ),
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(isLoading ? 'loading' : 'loaded-content'),
        child: isLoading ? loading : content,
      ),
    );
  }
}
