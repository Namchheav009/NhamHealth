import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/calories_controller.dart';

class AddFoodSourceSheet
    extends StatefulWidget {
  const AddFoodSourceSheet({super.key});

  @override
  State<AddFoodSourceSheet> createState() =>
      _AddFoodSourceSheetState();
}

class _AddFoodSourceSheetState
    extends State<AddFoodSourceSheet> {
  final controller = Get.find<CaloriesController>();

  final foodController = TextEditingController();
  final caloriesController =
      TextEditingController();

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
        MediaQuery.of(context)
                .viewInsets
                .bottom +
            20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Add Food Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<String>(
              initialValue: mealType,
              decoration: const InputDecoration(
                labelText: 'Meal type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Breakfast',
                  child: Text('Breakfast'),
                ),
                DropdownMenuItem(
                  value: 'Lunch',
                  child: Text('Lunch'),
                ),
                DropdownMenuItem(
                  value: 'Dinner',
                  child: Text('Dinner'),
                ),
                DropdownMenuItem(
                  value: 'Drink',
                  child: Text('Drink'),
                ),
                DropdownMenuItem(
                  value: 'Snack',
                  child: Text('Snack'),
                ),
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
              decoration: const InputDecoration(
                labelText: 'Food name',
                hintText: 'Example: Chicken rice',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories',
                suffixText: 'kcal',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final food =
                      foodController.text.trim();

                  final calories = int.tryParse(
                    caloriesController.text.trim(),
                  );

                  if (food.isEmpty ||
                      calories == null ||
                      calories <= 0) {
                    Get.snackbar(
                      'Invalid information',
                      'Please enter food name and calories.',
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
                  backgroundColor:
                      const Color(0xFF00A651),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Add Food',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}