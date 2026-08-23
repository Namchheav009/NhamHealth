import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_shadows.dart';
import '../../../controllers/home/home_controller.dart';

class AiRecommendationCard extends GetView<HomeController> {
  const AiRecommendationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        return Container(
          height: 176,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF3FBF5), Colors.white],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCEEE1)),
            boxShadow: AppShadows.surface,
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 17, 10, 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: Color(0xFFFFA928),
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'AI Recommendation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.darkGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      const Expanded(
                        child: Text(
                          'Personalized meals for your mood, nutrition goals, and cooking time.',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 40,
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
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                controller.isRecommendedMealsLoading.value
                                    ? 'Generating…'
                                    : 'Get recommendations',
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 12,
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
              ),
              Container(
                width: compact ? 92 : 118,
                height: double.infinity,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.image,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/meals/healthy_salad.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
