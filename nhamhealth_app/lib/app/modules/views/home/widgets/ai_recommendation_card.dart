import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../widgets/inner_shadow.dart';
import '../../../controllers/home/home_controller.dart';
import '../../../models/home/mood_model.dart';

class AiRecommendationCard extends GetView<HomeController> {
  const AiRecommendationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 188,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(15),
            boxShadow: AppShadows.surface,
          ),
          child: InnerShadow(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                Positioned(
                  right: 2,
                  top: 24,
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: RepaintBoundary(
                      child: Lottie.asset(
                        'assets/animations/Anima Bot.json',
                        fit: BoxFit.contain,
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
                              style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
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
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.08,
                                        color: AppColors.primaryText,
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
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.primaryGreen
                                    .withValues(alpha: 0.55),
                                elevation: selectedMood == null ? 3 : 6,
                                shadowColor: AppColors.primaryGreen.withValues(
                                  alpha: selectedMood == null ? 0.2 : 0.42,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isLoading
                                      ? 'Generating…'.tr
                                      : selectedMood == null
                                      ? 'Get Recommendation'.tr
                                      : 'Recommend for @mood'.trParams({
                                        'mood': selectedMood.name.tr,
                                      }),
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
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
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.2,
              color: AppColors.primaryText,
            ),
          ),
        ),
      ],
    );
  }
}
