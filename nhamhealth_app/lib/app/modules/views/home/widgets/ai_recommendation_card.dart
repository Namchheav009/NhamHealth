import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import '../../../../widgets/inner_shadow.dart';
import '../../../controllers/home/home_controller.dart';

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
                  right: -40,
                  top: 27,
                  child: Container(
                    width: 148,
                    height: 148,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.image,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/meals/healthy_salad.jpg',
                        fit: BoxFit.cover,
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
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 19,
                            color: Color(0xFFFFB800),
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'AI Recommendation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Expanded(
                        child: Text(
                          'Get personalized meal &\n'
                          'activity suggestions based\n'
                          'on your mood, and\n'
                          'ingredients.',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.08,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth * 0.55,
                        height: 36,
                        child: Obx(
                          () => FilledButton(
                            onPressed:
                                controller.isRecommendedMealsLoading.value
                                    ? null
                                    : controller.getRecommendation,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primaryGreen
                                  .withValues(alpha: 0.55),
                              elevation: 3,
                              shadowColor: AppColors.primaryGreen.withValues(
                                alpha: 0.2,
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
                                controller.isRecommendedMealsLoading.value
                                    ? 'Generating…'
                                    : 'Get Recommendation',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
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
}
