import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/wellness_controller.dart';

class AiMealCard extends GetView<WellnessController> {
  const AiMealCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(-10, 0),
            child: SizedBox(
              width: 120,
              height: 120,
              child: Image.asset(
                'assets/images/wellness/ai_robot.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Log food with AI',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF555555),
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Tell AI what you ate and choose the amount '
                  'for a better estimate.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    // CLICK -> AI PAGE
                    onPressed: controller.openAiMealAutoFill,

                    icon: const Icon(Icons.auto_awesome_rounded, size: 17),

                    label: const Text(
                      'Open AI Meal Auto-Fill',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF00A651),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
