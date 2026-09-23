import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_background.dart';
import '../../../../widgets/app_back_header.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

class AuthFlowScaffold extends StatelessWidget {
  const AuthFlowScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.illustrationAsset,
    required this.child,
    this.showBackButton = true,
  });

  final String title;
  final String subtitle;
  final String illustrationAsset;
  final Widget child;
  final bool showBackButton;

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
                                  // Left Column: Navigation, Title & Illustration
                                  Expanded(
                                    flex: 5,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 36),
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (showBackButton)
                                              AppBackButton(onPressed: Get.back),
                                            const SizedBox(height: 16),
                                            Text(
                                              title.trOrSelf,
                                              style: TextStyle(
                                                color: context.appText,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              subtitle.trOrSelf,
                                              style: TextStyle(
                                                color: context.appMutedText,
                                                fontSize: 14,
                                                height: 1.4,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxHeight: 240,
                                              ),
                                              child: Image.asset(
                                                illustrationAsset,
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (_, _, _) => const Icon(
                                                      Icons
                                                          .health_and_safety_outlined,
                                                      size: 96,
                                                      color:
                                                          AppColors
                                                              .primaryGreen,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Right Column: Form Container Card
                                  Expanded(
                                    flex: 5,
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 460,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: context.appSurfaceLow,
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                            boxShadow: context.appCardShadow,
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: SingleChildScrollView(
                                            keyboardDismissBehavior:
                                                ScrollViewKeyboardDismissBehavior
                                                    .onDrag,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            padding: const EdgeInsets.all(28),
                                            child: child,
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

                      final compact = constraints.maxHeight < 720;
                      final maxContentWidth = isTablet ? 540.0 : 480.0;
                      final contentPadding = isTablet
                          ? const EdgeInsets.symmetric(
                              horizontal: AppSpacing.tabletPageHorizontal,
                              vertical: AppSpacing.pageTop,
                            )
                          : AppSpacing.pagePadding;
                      final illustrationHeight = (constraints.maxHeight *
                              (compact ? 0.22 : (isTablet ? 0.25 : 0.27)))
                          .clamp(130.0, isTablet ? 240.0 : 220.0);

                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxContentWidth),
                          child: SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            physics: const BouncingScrollPhysics(),
                            padding: contentPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: AppBackButton.layoutSize,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: showBackButton
                                        ? AppBackButton(onPressed: Get.back)
                                        : null,
                                  ),
                                ),
                                SizedBox(height: isTablet ? 14 : (compact ? 4 : 10)),
                                Text(
                                  title.trOrSelf,
                                  style: TextStyle(
                                    color: context.appText,
                                    fontSize: isTablet ? 28 : 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subtitle.trOrSelf,
                                  style: TextStyle(
                                    color: context.appMutedText,
                                    fontSize: isTablet ? 15 : 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: isTablet ? 20 : (compact ? 10 : 16)),
                                SizedBox(
                                  height: illustrationHeight,
                                  child: Image.asset(
                                    illustrationAsset,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (_, _, _) => const Icon(
                                          Icons.health_and_safety_outlined,
                                          size: 96,
                                          color: AppColors.primaryGreen,
                                        ),
                                  ),
                                ),
                                SizedBox(height: isTablet ? 24 : (compact ? 16 : 22)),
                                child,
                              ],
                            ),
                          ),
                        ),
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
