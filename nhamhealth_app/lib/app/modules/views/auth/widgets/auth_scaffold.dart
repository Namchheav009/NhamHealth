import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_background.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';
import 'auth_header.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: Builder(
        builder:
            (context) => Scaffold(
              resizeToAvoidBottomInset: true,
              body: AppBackground(
                lightDecoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.backgroundMint,
                      AppColors.backgroundCream,
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isLandscape =
                          constraints.maxWidth > constraints.maxHeight;
                      final isTablet =
                          AppSpacing.isTabletFor(context) ||
                          constraints.maxWidth >= AppSpacing.tabletBreakpoint;
                      final isWide =
                          (constraints.maxWidth >=
                                  AppSpacing.twoColumnBreakpoint &&
                              isLandscape) ||
                          constraints.maxWidth >= 840;

                      if (isWide) {
                        return _AuthWideLayout(
                          key: const ValueKey<String>('auth-tablet-layout'),
                          child: child,
                        );
                      }

                      if (isTablet) {
                        return _AuthTabletPortraitLayout(
                          key: const ValueKey<String>(
                            'auth-tablet-portrait-layout',
                          ),
                          constraints: constraints,
                          child: child,
                        );
                      }

                      return _AuthPhoneLayout(
                        constraints: constraints,
                        child: child,
                      );
                    },
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

class _AuthWideLayout extends StatelessWidget {
  const _AuthWideLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSpacing.maxWideContentWidth,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.tabletPageHorizontal,
            vertical: AppSpacing.pageTop,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Branding, Title, Tagline
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 36),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _EntranceMotion(
                        offset: Offset(0, -0.06),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AuthHeader(compact: false),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'auth.welcome_to_nhamhealth'.trOrSelf,
                        style: const TextStyle(
                          color: AppColors.darkGreen,
                          fontSize: 34,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'auth.get_affordable_organic_groceries_made_for_a_healthier_everyday_life'
                            .trOrSelf,
                        style: TextStyle(
                          color: context.appMutedText,
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right Column: Floating Auth Card
              Expanded(
                flex: 5,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.appSurfaceLow,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: context.appCardShadow,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(28),
                        child: _EntranceMotion(
                          delay: 0.12,
                          child: child,
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

class _AuthTabletPortraitLayout extends StatelessWidget {
  const _AuthTabletPortraitLayout({
    super.key,
    required this.constraints,
    required this.child,
  });

  final BoxConstraints constraints;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.tabletPageHorizontal,
            vertical: 36,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _EntranceMotion(
                offset: Offset(0, -0.06),
                child: AuthHeader(compact: false),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.appSurfaceLow,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: context.appCardShadow,
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: _EntranceMotion(
                  delay: 0.12,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthPhoneLayout extends StatelessWidget {
  const _AuthPhoneLayout({
    required this.constraints,
    required this.child,
  });

  final BoxConstraints constraints;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                      compact ? Alignment.center : Alignment.bottomCenter,
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
                decoration: BoxDecoration(
                  color: context.appSurfaceLow,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: context.appCardShadow,
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
