import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/inner_shadow.dart';
import '../../../controllers/home/home_controller.dart';
import '../../../models/home/mood_model.dart';

class AiRecommendationCard extends GetView<HomeController> {
  const AiRecommendationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final animationSize = (constraints.maxWidth * 0.41).clamp(132.0, 154.0);
        return Container(
          height: 188,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color:
                context.appIsDark
                    ? null
                    : context.appElevatedSurface.withValues(alpha: 0.96),
            gradient:
                context.appIsDark
                    ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF071712),
                        Color(0xFF0B2118),
                        Color(0xFF102B1D),
                      ],
                      stops: [0, 0.56, 1],
                    )
                    : null,
            borderRadius: BorderRadius.circular(15),
            border:
                context.appIsDark
                    ? Border.all(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.34),
                    )
                    : null,
            boxShadow:
                context.appIsDark
                    ? [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                        blurRadius: 24,
                        spreadRadius: -3,
                        offset: const Offset(0, 8),
                      ),
                      const BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 16,
                        offset: Offset(0, 7),
                      ),
                    ]
                    : context.appHomeCardShadow,
          ),
          child: InnerShadow(
            borderRadius: BorderRadius.circular(15),
            shadows: context.appIsDark ? context.appInnerShadow : const [],
            child: Stack(
              children: [
                if (context.appIsDark) const _DarkRecommendationBackdrop(),
                Positioned(
                  right: -4,
                  top: (188 - animationSize) / 2,
                  child: SizedBox(
                    width: animationSize,
                    height: animationSize,
                    child: RepaintBoundary(
                      child: Lottie.asset(
                        'assets/animations/Healthy or Junk food.json',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        repeat: true,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 18,
                  bottom: 19,
                  width: constraints.maxWidth * 0.61,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 19,
                            color: Color(0xFFFFB800),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'AI Recommendation'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color:
                                    context.appIsDark
                                        ? const Color(0xFF4ADE80)
                                        : AppColors.primaryGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Obx(() {
                          final selectedMood = _selectedMood();
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 360),
                            switchInCurve: Curves.easeOutBack,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder:
                                (child, animation) => FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.18),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child:
                                selectedMood == null
                                    ? Text(
                                      'Get personalized meal &\nactivity suggestions based\non your mood and ingredients.'
                                          .tr,
                                      key: const ValueKey('no-mood'),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.08,
                                        color: context.appText,
                                      ),
                                    )
                                    : _SelectedMoodDetail(mood: selectedMood),
                          );
                        }),
                      ),
                      SizedBox(
                        width: constraints.maxWidth * 0.55,
                        height: 36,
                        child: Obx(() {
                          final selectedMood = _selectedMood();
                          final isLoading =
                              controller.isRecommendedMealsLoading.value;
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 380),
                            switchInCurve: Curves.elasticOut,
                            switchOutCurve: Curves.easeIn,
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.centerLeft,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            transitionBuilder:
                                (child, animation) => FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: Tween<double>(
                                      begin: 0.72,
                                      end: 1,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: FilledButton(
                              key: ValueKey(selectedMood?.id),
                              onPressed:
                                  isLoading
                                      ? null
                                      : controller.getRecommendation,
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    context.appIsDark
                                        ? const Color(0xFF22C55E)
                                        : AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: (context.appIsDark
                                        ? const Color(0xFF22C55E)
                                        : AppColors.primaryGreen)
                                    .withValues(alpha: 0.55),
                                elevation: selectedMood == null ? 3 : 6,
                                shadowColor: AppColors.primaryGreen.withValues(
                                  alpha: selectedMood == null ? 0.2 : 0.42,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Row(
                                  key: ValueKey(isLoading),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLoading)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 18,
                                      ),

                                    const SizedBox(width: 8),

                                    Flexible(
                                      child: Text(
                                        isLoading
                                            ? 'Generating…'.tr
                                            : selectedMood == null
                                            ? 'Suggest Meals'.tr
                                            : 'Suggest Meals for @mood'
                                                .trParams({
                                                  'mood': selectedMood.name.tr,
                                                }),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  MoodModel? _selectedMood() {
    final selectedId = controller.selectedMoodId.value;
    for (final mood in controller.moods) {
      if (mood.id == selectedId) return mood;
    }
    return null;
  }
}

class _DarkRecommendationBackdrop extends StatelessWidget {
  const _DarkRecommendationBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -46,
            top: -66,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x3322C55E), Color(0x0016A34A)],
                ),
              ),
            ),
          ),
          Positioned(
            left: -58,
            bottom: -100,
            child: Container(
              width: 230,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x2416A34A), Color(0x000B2118)],
                ),
              ),
            ),
          ),
          const Positioned(
            right: 118,
            top: 17,
            child: Icon(Icons.eco_rounded, size: 18, color: Color(0x334ADE80)),
          ),
        ],
      ),
    );
  }
}

class _SelectedMoodDetail extends StatelessWidget {
  const _SelectedMoodDetail({required this.mood});

  final MoodModel mood;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey(mood.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mood.emoji.isEmpty ? '✨' : mood.emoji,
          textScaler: TextScaler.noScaling,
          style: const TextStyle(fontSize: 28, height: 1),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'You feel @mood\n'.trParams({'mood': mood.name.tr}),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: 'AI will personalize meals for this mood.'.tr),
              ],
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.2,
              color: context.appText,
            ),
          ),
        ),
      ],
    );
  }
}
