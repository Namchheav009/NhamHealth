import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import 'inner_shadow.dart';

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
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF66706A).withValues(alpha: 0.09),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: InnerShadow(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              children: [
                Positioned(
                  right: -29,
                  top: 27,
                  child: Container(
                    width: 148,
                    height: 148,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
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
                            Icons.auto_awesome,
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
                                color: Color(0xFF009B49),
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
                            color: Color(0xFF414141),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth * 0.55,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: controller.getRecommendation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009B49),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(
                              0xFF009B49,
                            ).withValues(alpha: 0.32),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Get Recommendation',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
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
