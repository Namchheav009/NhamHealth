import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import 'auth_header.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundMint, AppColors.backgroundCream],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 720;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      SizedBox(
                        height: compact ? 142 : 280,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: compact ? 0 : 24),
                          child: Align(
                            alignment:
                                compact
                                    ? Alignment.center
                                    : Alignment.bottomCenter,
                            child: _EntranceMotion(
                              offset: const Offset(0, -0.08),
                              child: AuthHeader(compact: compact),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 28,
                                offset: Offset(0, -6),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            top: false,
                            minimum: const EdgeInsets.only(bottom: 12),
                            child: SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                AppSpacing.pageHorizontal,
                                compact ? 18 : 46,
                                AppSpacing.pageHorizontal,
                                AppSpacing.pageBottom,
                              ),
                              child: _EntranceMotion(
                                delay: 0.12,
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EntranceMotion extends StatelessWidget {
  const _EntranceMotion({
    required this.child,
    this.delay = 0,
    this.offset = const Offset(0, 0.06),
  });

  final Widget child;
  final double delay;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      child: child,
      builder: (context, value, child) {
        final progress =
            ((value - delay) / (1 - delay)).clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(
              offset.dx * (1 - progress) * 100,
              offset.dy * (1 - progress) * 100,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
