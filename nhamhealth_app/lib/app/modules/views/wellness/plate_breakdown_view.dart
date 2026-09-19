import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../controllers/wellness/ai_food_controller.dart';
import 'widgets/multi_item_plate_card.dart';

class PlateBreakdownView extends StatelessWidget {
  const PlateBreakdownView({super.key, this.controller});

  final AiFoodController? controller;

  static const Color green = Color(0xFF00A651);
  static const Color greenDark = Color(0xFF087A48);

  AiFoodController get _ctrl => controller ?? Get.find<AiFoodController>();

  @override
  Widget build(BuildContext context) {
    final horizontal = AppSpacing.pageHorizontalFor(context);
    final isDark = context.appIsDark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        lightDecoration: BoxDecoration(color: context.appBackground),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxWideContentWidth,
              ),
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      14,
                      horizontal,
                      10,
                    ),
                    child: Row(
                      children: [
                        AppBackButton(
                          buttonKey: const ValueKey(
                            'plate-breakdown-back-button',
                          ),
                          onPressed: Get.back,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'wellness.plate_items'.tr,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  color: context.appText,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Obx(() {
                                final count = _ctrl.plateItems.length;
                                final selected =
                                    _ctrl.plateItems
                                        .where((i) => i.isSelected)
                                        .length;
                                return Text(
                                  '$selected of $count items selected',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.appMutedText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        6,
                        horizontal,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Summary Card
                          Obx(() {
                            final nut = _ctrl.nutrition.value;
                            if (nut == null) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.appElevatedSurface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: context.appBorder),
                                boxShadow: context.appCardShadow,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? const Color(0xFF143021)
                                              : const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.pie_chart_rounded,
                                      color: green,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          nut.mealName.isNotEmpty
                                              ? nut.mealName
                                              : nut.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: context.appText,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${nut.calories.round()} kcal • ${nut.protein.round()}g P • ${nut.carbs.round()}g C • ${nut.fat.round()}g F',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.appMutedText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          // The multi-item plate breakdown editor
                          MultiItemPlateCard(controller: _ctrl),
                        ],
                      ),
                    ),
                  ),

                  // Bottom bar with Done button
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      10,
                      horizontal,
                      14,
                    ),
                    decoration: BoxDecoration(
                      color: context.appElevatedSurface,
                      border: Border(top: BorderSide(color: context.appBorder)),
                    ),
                    child: ElevatedButton(
                      onPressed: Get.back,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'common.done'.trOrSelf,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
