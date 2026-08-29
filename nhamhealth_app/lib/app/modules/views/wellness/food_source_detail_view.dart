import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/wellness/food_source_detail_controller.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_back_header.dart';
import 'widgets/food_amount_editor_card.dart';
import 'widgets/food_contribution_card.dart';
import 'widgets/food_detail_ai_insight_card.dart';
import 'widgets/food_detail_summary_card.dart';
import 'widgets/food_nutrition_estimate_card.dart';

class FoodSourceDetailView extends GetView<FoodSourceDetailController> {
  const FoodSourceDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        lightDecoration: const BoxDecoration(
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
                  _header(context),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: AppSpacing.pagePadding,
                      child: const Column(
                        children: [
                          FoodDetailSummaryCard(),
                          SizedBox(height: 10),
                          FoodAmountEditorCard(),
                          SizedBox(height: 10),
                          FoodNutritionEstimateCard(),
                          SizedBox(height: 10),
                          FoodContributionCard(),
                          SizedBox(height: 10),
                          FoodDetailAiInsightCard(),
                        ],
                      ),
                    ),
                  ),

                  _bottomActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          AppBackButton(onPressed: Get.back),
          Expanded(
            child: Center(
              child: Text(
                'Food Detail'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: context.appText,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppBackButton.layoutSize),
        ],
      ),
    );
  }

  Widget _bottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: controller.cancelChanges,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
                foregroundColor: context.appColorScheme.primary,
                side: BorderSide(color: context.appColorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text('Cancel'.tr),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: controller.saveChanges,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
                backgroundColor: context.appColorScheme.primary,
                foregroundColor: context.appColorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              label: Text('Save Changes'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import 'food_source_model.dart';

// class FoodSourceDetailView
//     extends StatelessWidget {
//   const FoodSourceDetailView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final FoodSourceModel source =
//         Get.arguments as FoodSourceModel;

//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           onPressed: Get.back,
//           icon: const Icon(
//             Icons.arrow_back_rounded,
//           ),
//         ),
//         title: Text(source.foodName),
//       ),
//       body: Center(
//         child: Text(
//           '${source.mealType}\n'
//           '${source.foodName}\n'
//           '${source.calories} kcal',
//           textAlign: TextAlign.center,
//         ),
//       ),
//     );
//   }
// }
