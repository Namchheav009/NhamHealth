import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 720;
              final illustrationHeight = (constraints.maxHeight *
                      (compact ? 0.22 : 0.27))
                  .clamp(130.0, 220.0);

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(30, 8, 30, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 48,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child:
                                showBackButton
                                    ? IconButton(
                                      tooltip: 'Back',
                                      onPressed: Get.back,
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: AppColors.darkGreen,
                                      ),
                                    )
                                    : null,
                          ),
                        ),
                        SizedBox(height: compact ? 4 : 10),
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.darkGreen,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: compact ? 10 : 16),
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
                        SizedBox(height: compact ? 16 : 22),
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
    );
  }
}
