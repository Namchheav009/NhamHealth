import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/wellness/ai_food_controller.dart';
import '../../../models/wellness/plate_item_model.dart';
import '../../../services/wellness/ingredient_visual_service.dart';
import 'ingredient_avatar.dart';
import 'visual_portion_selector.dart';

class MultiItemPlateCard extends StatelessWidget {
  const MultiItemPlateCard({super.key, required this.controller});

  final AiFoodController controller;

  static const green = Color(0xFF00A651);
  static const greenDark = Color(0xFF087A48);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.plateItems;
      if (items.isEmpty) return const SizedBox.shrink();

      final isDark = context.appIsDark;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? context.appSurface : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color:
                isDark
                    ? context.appBorder.withValues(alpha: 0.6)
                    : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Sparkle Icon + Title & Subtitle + Count Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF143021)
                            : const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, color: green, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'wellness.detected_ingredients'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.appText,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'wellness.ingredients_likely_inside'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appMutedText,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? green.withValues(alpha: 0.18)
                            : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'wellness.ingredients_found'.trParams({
                      'count': '${items.length}',
                    }),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF4ADE80) : greenDark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(
              height: 1,
              thickness: 1,
              color: context.appBorder.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),

            // Ingredients List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder:
                  (_, _) => Divider(
                    height: 20,
                    thickness: 0.8,
                    color: context.appBorder.withValues(alpha: 0.35),
                  ),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildIngredientRow(context, item, index);
              },
            ),

            const SizedBox(height: 16),

            // Info note row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? context.appSurfaceLow : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.appBorder.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? green.withValues(alpha: 0.2)
                              : const Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: greenDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'wellness.review_and_adjust_ingredients'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appMutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddItemDialog(context),
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 19,
                    ),
                    label: Text('wellness.add_ingredient'.tr),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? const Color(0xFF4ADE80) : greenDark,
                      side: BorderSide(
                        color: green.withValues(alpha: isDark ? 0.6 : 0.4),
                      ),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        controller.isReanalyzingIngredients.value
                            ? null
                            : controller.reanalyzePlateIngredients,
                    icon:
                        controller.isReanalyzingIngredients.value
                            ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.refresh_rounded, size: 19),
                    label: Text(
                      controller.isReanalyzingIngredients.value
                          ? 'wellness.analyzing_ingredients'.tr
                          : 'wellness.analyze_ingredients_again'.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: context.appOnBrand,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildIngredientRow(
    BuildContext context,
    PlateItemState item,
    int index,
  ) {
    final visual = IngredientVisualService.resolve(
      item.name,
      componentType: item.componentType,
      customRole: item.role,
      customImageUrl: item.imageUrl,
    );

    final displayRole = item.role.isNotEmpty ? item.role : visual.defaultRole;

    return InkWell(
      onTap: () => _showPortionSheet(context, item, index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Avatar / Thumbnail
            IngredientAvatar(
              name: item.name,
              imageUrl: visual.imageUrl,
              componentType: item.componentType,
              size: 58,
              borderRadius: 17,
            ),
            const SizedBox(width: 12),

            // Name, Role & Confidence Pill
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color:
                          item.isSelected
                              ? context.appText
                              : context.appMutedText,
                      decoration:
                          item.isSelected ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayRole,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appMutedText,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Confidence & Macro Badges. Wrap on compact screens so
                  // translated labels never compete with the amount column.
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      _buildConfidenceBadge(context, item),
                      if (item.calories > 0)
                        _buildMacroContributionPill(context, item),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Subtle Vertical Divider
            Container(
              width: 1,
              height: 42,
              color: context.appBorder.withValues(alpha: 0.5),
            ),

            const SizedBox(width: 12),

            // Amount is styled as an action to make row editability obvious.
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 62, maxWidth: 86),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'wellness.amount_label'.tr,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: context.appMutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '${item.servingSize.round()} ${item.unit}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: context.appText,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 17,
                        color: _actionColor(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(BuildContext context, PlateItemState item) {
    final isDark = context.appIsDark;
    final isHigh = item.isHighConfidence;
    final isMed = item.isMediumConfidence;

    final Color bgColor =
        isHigh
            ? (isDark ? const Color(0xFF143021) : const Color(0xFFECFDF5))
            : isMed
            ? (isDark ? const Color(0xFF332005) : const Color(0xFFFFFBEB))
            : (isDark ? context.appSurfaceLow : const Color(0xFFF1F5F9));

    final Color textColor =
        isHigh
            ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF059669))
            : isMed
            ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
            : context.appMutedText;

    final IconData icon =
        isHigh
            ? Icons.signal_cellular_alt_rounded
            : isMed
            ? Icons.signal_cellular_alt_2_bar_rounded
            : Icons.signal_cellular_alt_1_bar_rounded;

    final String label =
        isHigh
            ? 'wellness.high_confidence'.tr
            : isMed
            ? 'wellness.medium_confidence'.tr
            : 'wellness.low_confidence'.tr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.5, color: textColor),
          const SizedBox(width: 3.5),
          Text(
            '$label · ${(item.confidence.clamp(0, 1) * 100).round()}%',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _actionColor(BuildContext context) =>
      context.appIsDark ? const Color(0xFF4ADE80) : greenDark;

  Widget _buildMacroContributionPill(
    BuildContext context,
    PlateItemState item,
  ) {
    final isDark = context.appIsDark;
    final cals = item.calories.round();
    String macroText = '';
    if (item.carbs >= item.protein &&
        item.carbs >= item.fat &&
        item.carbs >= 3) {
      macroText = ' • ${item.carbs.round()}g C';
    } else if (item.protein >= item.carbs &&
        item.protein >= item.fat &&
        item.protein >= 2) {
      macroText = ' • ${item.protein.round()}g P';
    } else if (item.fat >= 2) {
      macroText = ' • ${item.fat.round()}g F';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$cals kcal$macroText',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildAnalysisSourceBadge(
    BuildContext context,
    PlateItemState item,
  ) {
    final isDatabase = item.databaseMatched;
    final label =
        isDatabase
            ? 'wellness.database_verified'.tr
            : 'wellness.ai_nutrition_estimate'.tr;
    final color =
        isDatabase
            ? _actionColor(context)
            : (context.appIsDark
                ? const Color(0xFFFBBF24)
                : const Color(0xFFB45309));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDatabase ? Icons.verified_rounded : Icons.auto_awesome_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewBadge(BuildContext context) {
    final color =
        context.appIsDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review_outlined, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            'wellness.needs_review'.tr,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisDetail(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: context.appMutedText),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.appText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPortionSheet(BuildContext context, PlateItemState item, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${'wellness.select_portion'.tr}: ${item.name}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.appText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.removePlateItem(index);
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    tooltip: 'Remove',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sheetContext.appSurfaceLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sheetContext.appBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'wellness.ai_ingredient_analysis'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: sheetContext.appText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildAnalysisSourceBadge(sheetContext, item),
                          if (item.requiresUserConfirmation)
                            _buildReviewBadge(sheetContext),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildAnalysisDetail(
                        sheetContext,
                        'wellness.identity_confidence'.tr,
                        '${(item.confidence.clamp(0, 1) * 100).round()}%',
                      ),
                      _buildAnalysisDetail(
                        sheetContext,
                        'wellness.portion_confidence'.tr,
                        item.portionConfidence > 0
                            ? '${(item.portionConfidence.clamp(0, 1) * 100).round()}%'
                            : '—',
                      ),
                      if (item.preparationMethod.trim().isNotEmpty &&
                          item.preparationMethod.trim().toLowerCase() !=
                              'unknown')
                        _buildAnalysisDetail(
                          sheetContext,
                          'wellness.preparation'.tr,
                          item.preparationMethod.trim(),
                        ),
                      if (item.visibleEvidence.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'wellness.visible_evidence'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: sheetContext.appMutedText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.visibleEvidence.trim(),
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: sheetContext.appMutedText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'wellness.included_in_totals'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: sheetContext.appText,
                  ),
                ),
                value: item.isSelected,
                activeTrackColor: green,
                activeThumbColor: Colors.white,
                onChanged: (_) {
                  controller.togglePlateItem(index);
                  Navigator.pop(sheetContext);
                },
              ),
              const SizedBox(height: 16),
              VisualPortionSelector(
                isDrink: item.componentType == 'drink',
                selectedAmount: item.portionMultiplier,
                baseCalories: item.baseCalories,
                onFoodAmountChanged: (multiplier) {
                  controller.updatePlateItemPortion(index, multiplier);
                  Navigator.pop(sheetContext);
                },
                onDrinkCupChanged: (ml) {
                  final multiplier = ml / 350.0;
                  controller.updatePlateItemPortion(index, multiplier);
                  Navigator.pop(sheetContext);
                },
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController(text: '150');
    final amountController = TextEditingController(text: '50');

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'wellness.add_ingredient'.tr,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: const SizedBox.expand(),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(22),
                child: Center(
                  child: SingleChildScrollView(
                    primary: false,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(28, 29, 28, 28),
                        decoration: BoxDecoration(
                          color: dialogContext.appElevatedSurface,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: dialogContext.appElevatedSurface,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.16),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.restaurant_menu_rounded,
                                  color: green,
                                  size: 34,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'wellness.add_ingredient'.tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: dialogContext.appText,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: nameController,
                              autofocus: true,
                              decoration: InputDecoration(
                                labelText: 'wellness.plate_item_name'.tr,
                                hintText: 'e.g. Matcha powder, Sweetener',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: amountController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'wellness.amount_label'.tr,
                                      hintText: '50',
                                      suffixText: 'g',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: caloriesController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'wellness.plate_item_calories'.tr,
                                      hintText: '150',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(dialogContext),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 50),
                                      side: BorderSide(color: dialogContext.appBorder),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(21),
                                      ),
                                    ),
                                    child: Text(
                                      'common.cancel'.tr,
                                      style: TextStyle(
                                        color: dialogContext.appText,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      final name = nameController.text.trim();
                                      final cals = double.tryParse(caloriesController.text.trim()) ?? 150.0;
                                      final amount = double.tryParse(amountController.text.trim()) ?? 50.0;
                                      if (name.isNotEmpty) {
                                        controller.addPlateItem(
                                          name: name,
                                          calories: cals,
                                          protein: cals * 0.05,
                                          carbs: cals * 0.15,
                                          fat: cals * 0.03,
                                          amount: amount,
                                          unit: 'g',
                                        );
                                      }
                                      Navigator.pop(dialogContext);
                                    },
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 50),
                                      backgroundColor: green,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shadowColor: green.withValues(alpha: 0.35),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(21),
                                      ),
                                    ),
                                    child: Text(
                                      'wellness.add_ingredient'.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
