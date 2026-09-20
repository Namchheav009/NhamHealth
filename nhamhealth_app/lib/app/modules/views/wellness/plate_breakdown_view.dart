import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../controllers/wellness/ai_food_controller.dart';
import '../../services/wellness/ingredient_visual_service.dart';
import 'widgets/multi_item_plate_card.dart';
import 'widgets/plate_ai_insights_card.dart';

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
                  // App Bar / Top Navigation
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 8),
                    child: AppBackHeader(
                      title: 'wellness.plate_items',
                      subtitle: 'wellness.ai_detected_ingredients_subtitle',
                      backButtonKey: const ValueKey(
                        'plate-breakdown-back-button',
                      ),
                      onBack: Get.back,
                    ),
                  ),

                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        8,
                        horizontal,
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Item Summary Card
                          Obx(() => _buildItemSummaryCard(context)),

                          const SizedBox(height: 14),

                          // Detected ingredients Card
                          MultiItemPlateCard(controller: _ctrl),

                          const SizedBox(height: 14),

                          // Plate AI Insights Card
                          PlateAiInsightsCard(controller: _ctrl),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Sticky Done Button
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      12,
                      horizontal,
                      16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? context.appSurface : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: context.appBorder.withValues(alpha: 0.5),
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.03,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      key: const ValueKey('plate-breakdown-done-button'),
                      onPressed: Get.back,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'common.done'.trOrSelf,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
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

  Widget _buildItemSummaryCard(BuildContext context) {
    final nut = _ctrl.nutrition.value;
    if (nut == null) return const SizedBox.shrink();

    final isDark = context.appIsDark;
    final displayName = nut.mealName.isNotEmpty ? nut.mealName : nut.name;
    final selectedFile = _ctrl.selectedImage.value;

    // Determine current general portion from plate items
    final portionLabel = _resolveCurrentPortionLabel();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132A1C) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1F4D33) : const Color(0xFFDCFCE7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Food Thumbnail
          _buildItemThumbnail(context, selectedFile, displayName),

          const SizedBox(width: 12),

          // Meal Name, Macros & AI Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${nut.protein.round()}g P  •  ${nut.carbs.round()}g C  •  ${nut.fat.round()}g F',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.appMutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),

                // Analyzed by AI Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? green.withValues(alpha: 0.22)
                            : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco_rounded, size: 13, color: green),
                      const SizedBox(width: 4),
                      Text(
                        'wellness.analyzed_by_ai'.tr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF4ADE80) : greenDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Portion Dropdown Pill Button
          InkWell(
            onTap: () => _showGlobalPortionSheet(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? context.appSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark
                          ? const Color(0xFF2E6B47)
                          : const Color(0xFF86EFAC),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'wellness.portion_prefix'.trParams({
                      'portion': portionLabel,
                    }),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF4ADE80) : greenDark,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF4ADE80) : greenDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemThumbnail(
    BuildContext context,
    File? selectedFile,
    String mealName,
  ) {
    const double size = 62;
    final isDark = context.appIsDark;

    if (selectedFile != null && selectedFile.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          selectedFile,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    final visual = IngredientVisualService.resolve(mealName);
    final url = visual.imageUrl;

    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder:
              (_, _) => Container(
                width: size,
                height: size,
                color: isDark ? context.appSurfaceLow : visual.backgroundColor,
                child: Center(
                  child: Icon(
                    visual.fallbackIcon,
                    color: visual.iconColor,
                    size: 26,
                  ),
                ),
              ),
          errorWidget:
              (_, _, _) => Container(
                width: size,
                height: size,
                color: isDark ? context.appSurfaceLow : visual.backgroundColor,
                child: Center(
                  child: Icon(
                    visual.fallbackIcon,
                    color: visual.iconColor,
                    size: 26,
                  ),
                ),
              ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? context.appSurfaceLow : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.restaurant_rounded, color: green, size: 28),
      ),
    );
  }

  String _resolveCurrentPortionLabel() {
    if (_ctrl.plateItems.isEmpty) return 'Regular';
    final avg =
        _ctrl.plateItems.fold<double>(
          0.0,
          (sum, item) => sum + item.portionMultiplier,
        ) /
        _ctrl.plateItems.length;

    if (avg <= 0.6) return 'Small';
    if (avg <= 1.2) return 'Regular';
    if (avg <= 1.7) return 'Large';
    return 'XL';
  }

  void _showGlobalPortionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'wellness.choose_plate_size'.tr,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 14),
                _portionOptionTile(
                  context: sheetContext,
                  label: 'wellness.portion_small_short'.tr,
                  multiplier: 0.5,
                  desc: 'wellness.portion_small_desc'.tr,
                ),
                _portionOptionTile(
                  context: sheetContext,
                  label: 'wellness.portion_regular_short'.tr,
                  multiplier: 1.0,
                  desc: 'wellness.portion_regular_desc'.tr,
                ),
                _portionOptionTile(
                  context: sheetContext,
                  label: 'wellness.portion_large_short'.tr,
                  multiplier: 1.5,
                  desc: 'wellness.portion_large_desc'.tr,
                ),
                _portionOptionTile(
                  context: sheetContext,
                  label: 'wellness.portion_xlarge_short'.tr,
                  multiplier: 2.0,
                  desc: 'wellness.portion_xlarge_desc'.tr,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _portionOptionTile({
    required BuildContext context,
    required String label,
    required double multiplier,
    required String desc,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '$label (${multiplier}x)',
        style: TextStyle(fontWeight: FontWeight.w700, color: context.appText),
      ),
      subtitle: Text(
        desc,
        style: TextStyle(fontSize: 12, color: context.appMutedText),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: green),
      onTap: () {
        for (var i = 0; i < _ctrl.plateItems.length; i++) {
          _ctrl.updatePlateItemPortion(i, multiplier);
        }
        Navigator.pop(context);
      },
    );
  }
}
