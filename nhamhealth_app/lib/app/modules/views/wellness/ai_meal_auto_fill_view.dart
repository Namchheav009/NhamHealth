import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../controllers/wellness/ai_meal_auto_fill_controller.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

class AiMealAutoFillView extends GetView<AiMealAutoFillController> {
  const AiMealAutoFillView({super.key});

  static const green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      title: Text('wellness.ai_meal_auto_fill'.tr),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Obx(
            () => ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
              children: [
                _intro(),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.inputController,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'wellness.what_did_you_eat'.tr,
                    hintText:
                        'wellness.example_150_g_chicken_breast_1_cup_rice_banana'
                            .tr,
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: context.appField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed:
                        controller.isAnalyzing.value
                            ? null
                            : controller.analyzeText,
                    icon:
                        controller.isAnalyzing.value
                            ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      controller.isAnalyzing.value
                          ? 'wellness.matching_foods'.tr
                          : 'wellness.create_meal_draft'.tr,
                    ),
                    style: FilledButton.styleFrom(backgroundColor: green),
                  ),
                ),
                if (controller.unresolved.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _notice(
                    context,
                    'Not found: ${controller.unresolved.join(', ')}. Try simpler or more specific catalog names.',
                  ),
                ],
                if (controller.foods.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    'wellness.review_before_logging'.tr,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(controller.foods.length, (index) {
                    final food = controller.foods[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 9),
                      color: context.appSurfaceLow,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: context.appSoftGreen,
                          child: const Icon(Icons.restaurant, color: green),
                        ),
                        title: Text(
                          food.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'wellness.meal_nutrition_summary'.trParams({
                            'amount': _amount(food.servingSize),
                            'unit': food.servingUnit,
                            'calories': '${food.calories.round()}',
                            'protein': food.protein.toStringAsFixed(1),
                          }),
                        ),
                        trailing: IconButton(
                          tooltip: 'common.remove'.tr,
                          onPressed: () => controller.removeAt(index),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  _totals(context),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed:
                          controller.isSaving.value
                              ? null
                              : controller.addAllToToday,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(
                        controller.isSaving.value
                            ? 'wellness.adding_meal'.tr
                            : 'wellness.add_all_to_today'.tr,
                      ),
                      style: FilledButton.styleFrom(backgroundColor: green),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _notice(
                  context,
                  'wellness.food_names_are_matched_to_nhamhealths_nutrition_catalog_review_quantities_before_saving_results_are_for_general_wellness_only'
                      .tr,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _intro() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF087A48), green]),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.edit_note_rounded, color: Colors.white, size: 30),
        const SizedBox(height: 10),
        Text(
          'wellness.log_a_whole_meal_in_one_step'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'wellness.separate_foods_with_commas_or_write_one_per_line_include_amounts_when_you_know_them'
              .tr,
          style: const TextStyle(color: Color(0xDDFFFFFF), height: 1.4),
        ),
      ],
    ),
  );

  Widget _totals(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.appSoftGreen,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _total(context, '${controller.totalCalories.round()}', 'kcal'),
        _total(
          context,
          controller.totalProtein.toStringAsFixed(1),
          'wellness.grams_protein'.tr,
        ),
        _total(context, '${controller.foods.length}', 'wellness.foods'.tr),
      ],
    ),
  );

  Widget _total(BuildContext context, String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      Text(
        label.trOrSelf,
        style: TextStyle(fontSize: 12, color: context.appMutedText),
      ),
    ],
  );

  Widget _notice(BuildContext context, String text) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: context.appWarningSurface,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: context.appOnWarningSurface.withValues(alpha: .35),
      ),
    ),
    child: Text(
      text.trOrSelf,
      style: TextStyle(
        color: context.appOnWarningSurface,
        fontSize: 12.5,
        height: 1.4,
      ),
    ),
  );

  static String _amount(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}
