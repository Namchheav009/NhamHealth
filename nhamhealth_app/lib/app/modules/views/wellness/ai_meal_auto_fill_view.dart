import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/wellness/ai_meal_auto_fill_controller.dart';

class AiMealAutoFillView extends GetView<AiMealAutoFillController> {
  const AiMealAutoFillView({super.key});

  static const green = Color(0xFF00A651);
  static const background = Color(0xFFF7FAF6);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: background,
    appBar: AppBar(
      backgroundColor: background,
      surfaceTintColor: background,
      title: const Text('AI Meal Auto-Fill'),
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
                    labelText: 'What did you eat?',
                    hintText:
                        'Example: 150 g chicken breast, 1 cup rice, banana',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.white,
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
                          ? 'Matching foods...'
                          : 'Create meal draft',
                    ),
                    style: FilledButton.styleFrom(backgroundColor: green),
                  ),
                ),
                if (controller.unresolved.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _notice(
                    'Not found: ${controller.unresolved.join(', ')}. Try simpler or more specific catalog names.',
                  ),
                ],
                if (controller.foods.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const Text(
                    'Review before logging',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(controller.foods.length, (index) {
                    final food = controller.foods[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 9),
                      color: Colors.white,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE8F7EA),
                          child: Icon(Icons.restaurant, color: green),
                        ),
                        title: Text(
                          food.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${_amount(food.servingSize)} ${food.servingUnit} • ${food.calories.round()} kcal • ${food.protein.toStringAsFixed(1)} g protein',
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove',
                          onPressed: () => controller.removeAt(index),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  _totals(),
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
                            ? 'Adding meal...'
                            : 'Add all to today',
                      ),
                      style: FilledButton.styleFrom(backgroundColor: green),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _notice(
                  'Food names are matched to NhamHealth’s nutrition catalog. Review quantities before saving; results are for general wellness only.',
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
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.edit_note_rounded, color: Colors.white, size: 30),
        SizedBox(height: 10),
        Text(
          'Log a whole meal in one step',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Separate foods with commas or write one per line. Include amounts when you know them.',
          style: TextStyle(color: Color(0xDDFFFFFF), height: 1.4),
        ),
      ],
    ),
  );

  Widget _totals() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F7EA),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _total('${controller.totalCalories.round()}', 'kcal'),
        _total(controller.totalProtein.toStringAsFixed(1), 'g protein'),
        _total('${controller.foods.length}', 'foods'),
      ],
    ),
  );

  Widget _total(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF587064)),
      ),
    ],
  );

  Widget _notice(String text) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFF3E4A7)),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.4)),
  );

  static String _amount(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}
