import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/meals/meal_controller.dart';

class MealSlideShow extends GetView<MealController> {
  const MealSlideShow({super.key});

  static const Color green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;
            return Container(
              width: double.infinity,
              height: compact ? 190 : 208,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: context.appElevatedSurface.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.appBorder, width: 1),
                boxShadow: context.appCardShadow,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            context.appElevatedSurface,
                            context.appElevatedSurface.withValues(alpha: 0.82),
                            context.appSoftGreen.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PageView.builder(
                    controller: controller.slideController,
                    itemCount: controller.slides.length,
                    onPageChanged: controller.onSlideChanged,
                    itemBuilder: (context, index) {
                      final slide = controller.slides[index];

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 20 : 24,
                          16,
                          12,
                          16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slide.title.tr,
                                    style: TextStyle(
                                      fontSize: compact ? 18 : 20,
                                      height: 1.08,
                                      fontWeight: FontWeight.w700,
                                      color: context.appText,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    slide.highlight.tr,
                                    style: TextStyle(
                                      fontSize: compact ? 18 : 20,
                                      height: 1.08,
                                      fontWeight: FontWeight.w700,
                                      color: green,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    slide.description.tr,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.35,
                                      color: context.appMutedText,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 34,
                                    child: FilledButton.icon(
                                      key: const ValueKey(
                                        'meal-explore-button',
                                      ),
                                      onPressed: controller.showAllMeals,
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        shape: const StadiumBorder(),
                                      ),
                                      iconAlignment: IconAlignment.end,
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        'Explore now'.tr,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: Transform.scale(
                                scale: 1.13,
                                alignment: Alignment.centerRight,
                                child: Image.asset(
                                  slide.image,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(controller.slides.length, (index) {
              final selected = controller.currentSlide.value == index;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color:
                      selected
                          ? context.appColorScheme.primary
                          : context.appColorScheme.outlineVariant,
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
