import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/meals/meal_controller.dart';

class MealSlideShow extends GetView<MealController> {
  const MealSlideShow({super.key});

  static const Color green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 205,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.055),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: PageView.builder(
            controller: controller.slideController,
            itemCount: controller.slides.length,
            onPageChanged: controller.onSlideChanged,
            itemBuilder: (context, index) {
              final slide = controller.slides[index];

              return Padding(
                padding: const EdgeInsets.fromLTRB(29, 20, 13, 20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.title.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            slide.highlight.tr,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFF9B00),
                            ),
                          ),

                          const SizedBox(height: 11),

                          Text(
                            slide.description.tr,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFAEB3BA),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      flex: 6,
                      child: Image.asset(slide.image, fit: BoxFit.contain),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 9),

        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(controller.slides.length, (index) {
              final selected = controller.currentSlide.value == index;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: selected ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: selected ? green : const Color(0xFFD2D2D2),
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
