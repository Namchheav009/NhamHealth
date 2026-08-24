import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../widgets/app_alert.dart';

import '../../../controllers/wellness/calories_controller.dart';

class AddFoodSourceSheet extends StatefulWidget {
  const AddFoodSourceSheet({super.key});

  @override
  State<AddFoodSourceSheet> createState() => _AddFoodSourceSheetState();
}

class _AddFoodSourceSheetState extends State<AddFoodSourceSheet> {
  final controller = Get.find<CaloriesController>();

  final foodController = TextEditingController();
  final caloriesController = TextEditingController();

  String mealType = 'Breakfast';

  @override
  void dispose() {
    foodController.dispose();
    caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'Add Food Source'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              initialValue: mealType,
              decoration: InputDecoration(
                labelText: 'Meal type'.tr,
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Breakfast',
                  child: Text('Breakfast'.tr),
                ),
                DropdownMenuItem(value: 'Lunch', child: Text('Lunch'.tr)),
                DropdownMenuItem(value: 'Dinner', child: Text('Dinner'.tr)),
                DropdownMenuItem(value: 'Drink', child: Text('Drink'.tr)),
                DropdownMenuItem(value: 'Snack', child: Text('Snack'.tr)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    mealType = value;
                  });
                }
              },
            ),

            const SizedBox(height: 14),

            TextField(
              controller: foodController,
              decoration: InputDecoration(
                labelText: 'Food name'.tr,
                hintText: 'Example: Chicken rice'.tr,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Calories'.tr,
                suffixText: 'kcal'.tr,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final food = foodController.text.trim();

                  final calories = int.tryParse(caloriesController.text.trim());

                  if (food.isEmpty || calories == null || calories <= 0) {
                    AppAlert.error(
                      title: 'Invalid information',
                      message: 'Please enter food name and calories.',
                    );

                    return;
                  }

                  controller.addFoodSource(
                    mealType: mealType,
                    foodName: food,
                    calories: calories,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A651),
                  foregroundColor: Colors.white,
                ),
                child: Text('Add Food'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
