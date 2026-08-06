import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';

class AiRecommendationCard
    extends GetView<HomeController> {
  const AiRecommendationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x3327D968),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 20,
                            color:
                                Color(0xFFFFB800),
                          ),
                          SizedBox(width: 7),
                          Text(
                            'AI Recommendation',
                            style: TextStyle(
                              color:
                                  Color(0xFF00A651),
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Get personalized meal &\nactivity suggestions based\non your mood, and\ningredients.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          color: Color(0xFF444444),
                        ),
                      ),

                      const Spacer(),

                      SizedBox(
                        height: 35,
                        child: ElevatedButton(
                          onPressed: controller
                              .getRecommendation,
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(
                                  0xFF00A651,
                                ),
                            foregroundColor:
                                Colors.white,
                            elevation: 3,
                            padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 22,
                                ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(30),
                            ),
                          ),
                          child: const Text(
                            'Get Recommendation',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                flex: 4,
                child: Align(
                  alignment:
                      Alignment.bottomRight,
                  child: Image.asset(
                    'assets/images/hom/healthy_salad.png',
                    height: 135,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}