import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/wellness/calories_controller.dart';
import '../../../theme/app_spacing.dart';
import 'widgets/calories_intake_editor.dart';
import 'widgets/calories_progress_card.dart';
import 'widgets/calories_ai_insight_card.dart';
import 'widgets/food_sources_card.dart';

class CaloriesView extends GetView<CaloriesController> {
  const CaloriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFFF4F6), Colors.white, Color(0xFFF6FFF1)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  _header(),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: AppSpacing.pagePadding,
                      child: const Column(
                        children: [
                          CalorieProgressCard(),

                          SizedBox(height: 10),

                          CalorieIntakeEditor(),

                          SizedBox(height: 10),

                          FoodSourcesCard(),

                          SizedBox(height: 10),

                          CaloriesAiInsightCard(),
                        ],
                      ),
                    ),
                  ),

                  _bottomActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF00A651),
            ),
          ),

          const Expanded(
            child: Center(
              child: Text(
                'Calories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),

          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _bottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: controller.cancelChanges,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
                foregroundColor: const Color(0xFF00A651),
                side: const BorderSide(color: Color(0xFF00A651)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: ElevatedButton.icon(
              onPressed: controller.saveChanges,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
                backgroundColor: const Color(0xFF00A651),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              label: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
