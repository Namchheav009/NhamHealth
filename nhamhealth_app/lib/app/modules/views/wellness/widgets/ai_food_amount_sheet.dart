import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/wellness/ai_food_controller.dart';
import 'visual_portion_selector.dart';

class AiFoodAmountSheet extends StatefulWidget {
  const AiFoodAmountSheet({super.key, required this.controller});

  final AiFoodController controller;

  @override
  State<AiFoodAmountSheet> createState() => _AiFoodAmountSheetState();
}

class _AiFoodAmountSheetState extends State<AiFoodAmountSheet> {
  static const green = Color(0xFF00A651);
  static const greenDark = Color(0xFF087A48);
  static const mintBackground = Color(0xFFF0FDF4);
  static const mintBorder = Color(0xFFDCFCE7);
  static const mintSelected = Color(0xFFE8F8F0);
  static const infoBackground = Color(0xFFEFF8FF);
  static const infoBorder = Color(0xFFDBEAFE);
  static const infoBlue = Color(0xFF2563EB);

  Color _selectedSurface(BuildContext context) =>
      context.appIsDark
          ? Color.alphaBlend(
            green.withValues(alpha: .18),
            context.appSurfaceLow,
          )
          : mintSelected;

  Color _previewSurface(BuildContext context) =>
      context.appIsDark ? context.appSoftGreen : mintBackground;

  Color _previewBorder(BuildContext context) =>
      context.appIsDark ? green.withValues(alpha: .45) : mintBorder;

  Color _accentText(BuildContext context) =>
      context.appIsDark ? const Color(0xFF5EE09A) : greenDark;

  late final TextEditingController _foodAmountTextController;

  @override
  void initState() {
    super.initState();
    final initial = widget.controller.foodAmount.value;
    _foodAmountTextController = TextEditingController(
      text: _formatAmount(initial),
    );
  }

  @override
  void dispose() {
    _foodAmountTextController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  void _onQuickFoodAmountSelected(double amount) {
    widget.controller.setFoodAmount(amount);
    _foodAmountTextController.text = _formatAmount(amount);
  }

  Future<void> _showCustomCupDialog(BuildContext context) async {
    final textController = TextEditingController(
      text: widget.controller.drinkCupMl.value.round().toString(),
    );

    final result = await showDialog<double>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: dialogContext.appSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              'wellness.enter_custom_cup_size'.tr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: dialogContext.appText,
              ),
            ),
            content: TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                suffixText: 'common.ml'.tr,
                filled: true,
                fillColor: dialogContext.appSurfaceLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: dialogContext.appBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: dialogContext.appBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: green, width: 1.5),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('common.cancel'.tr),
              ),
              FilledButton(
                onPressed: () {
                  final parsed = double.tryParse(textController.text.trim());
                  if (parsed != null && parsed > 0) {
                    Navigator.of(dialogContext).pop(parsed);
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: green),
                child: Text('common.ok'.tr),
              ),
            ],
          ),
    );

    if (result != null && result > 0) {
      widget.controller.setDrinkCupMl(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDrink =
          widget.controller.inputKind.value == AiFoodInputKind.drink;
      final mediaQuery = MediaQuery.of(context);
      final availableHeight =
          mediaQuery.size.height - mediaQuery.viewInsets.bottom;
      return Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 620,
            maxHeight: availableHeight * .88,
          ),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header(context, isDrink),
                        const SizedBox(height: 18),
                        if (isDrink)
                          _drinkBody(context)
                        else
                          _foodBody(context),
                      ],
                    ),
                  ),
                ),
                // Keep the action row above Android's gesture/navigation bar.
                // The Flexible body yields space first when the sheet is short.
                Padding(
                  padding: EdgeInsets.only(bottom: mediaQuery.viewPadding.bottom),
                  child: _sheetActions(context),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _header(BuildContext context, bool isDrink) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isDrink ? Icons.local_drink_rounded : Icons.restaurant_rounded,
          color: green,
          size: 30,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDrink
                    ? 'wellness.edit_drink_amount'.tr
                    : 'wellness.edit_food_amount'.tr,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isDrink
                    ? 'wellness.select_cup_size_and_drink_amount'.tr
                    : 'wellness.adjust_amount_actually_ate'.tr,
                style: TextStyle(color: context.appMutedText, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _foodBody(BuildContext context) {
    final selectedAmount = widget.controller.foodAmount.value;
    final photo = widget.controller.selectedImage.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wellness.amount'.tr,
          style: TextStyle(
            color: context.appText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: context.appSurfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appBorder),
                ),
                child: TextField(
                  controller: _foodAmountTextController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.appText,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 11),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.trim());
                    if (parsed != null && parsed > 0) {
                      widget.controller.setFoodAmount(parsed);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: context.appSurfaceLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.controller.foodUnit.value,
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.appMutedText,
                    ),
                    items:
                        const ['plate', 'bowl', 'serving']
                            .map(
                              (unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(
                                  'wellness.$unit'.trOrSelf,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.appText,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) widget.controller.setFoodUnit(value);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.restaurant_menu_rounded, size: 16, color: green),
            const SizedBox(width: 7),
            Text(
              'wellness.choose_plate_size'.tr,
              style: TextStyle(
                color: context.appText,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _portionSizeChip(
              context,
              label: '1/4',
              shortName: 'wellness.portion_quarter_short'.tr,
              icon: Icons.eco_outlined,
              value: 0.25,
            ),
            const SizedBox(width: 6),
            _portionSizeChip(
              context,
              label: '1/2',
              shortName: 'wellness.portion_small_short'.tr,
              icon: Icons.rice_bowl_outlined,
              value: 0.5,
            ),
            const SizedBox(width: 6),
            _portionSizeChip(
              context,
              label: '1',
              shortName: 'wellness.portion_regular_short'.tr,
              icon: Icons.dinner_dining_outlined,
              value: 1.0,
            ),
            const SizedBox(width: 6),
            _portionSizeChip(
              context,
              label: '1.5',
              shortName: 'wellness.portion_large_short'.tr,
              icon: Icons.ramen_dining_outlined,
              value: 1.5,
            ),
            const SizedBox(width: 6),
            _portionSizeChip(
              context,
              label: '2',
              shortName: 'wellness.portion_xlarge_short'.tr,
              icon: Icons.set_meal_outlined,
              value: 2.0,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _portionDetailBanner(context, selectedAmount),
        const SizedBox(height: 18),
        _previewBox(
          context,
          photo: photo,
          title: 'wellness.preview_estimated'.tr,
          mainText:
              '${_formatAmount(selectedAmount)} ${widget.controller.foodUnit.value.trOrSelf} (≈ ${widget.controller.estimatedGrams} g)',
          extraBadge:
              '🔥 ~ ${widget.controller.estimatedCalories.round()} kcal',
        ),
        const SizedBox(height: 12),
        _infoBox(context, text: 'wellness.nutrition_recalculated_notice'.tr),
      ],
    );
  }

  Widget _portionSizeChip(
    BuildContext context, {
    required String label,
    required String shortName,
    required IconData icon,
    required double value,
  }) {
    final isSelected =
        (widget.controller.foodAmount.value - value).abs() < 0.01;

    return Expanded(
      child: Material(
        color: isSelected ? _selectedSurface(context) : context.appSurfaceLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _onQuickFoodAmountSelected(value),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? green : context.appBorder,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected ? green : context.appMutedText,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? green : context.appText,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  shortName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isSelected
                            ? (context.appIsDark
                                ? const Color(0xFF5EE09A)
                                : greenDark)
                            : context.appMutedText,
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _portionDetailBanner(BuildContext context, double currentAmount) {
    final detail = _portionDetailFor(currentAmount);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:
            context.appIsDark
                ? green.withValues(alpha: .12)
                : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: green.withValues(alpha: context.appIsDark ? .3 : .25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: green.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(detail.$1, size: 20, color: greenDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  detail.$2,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: greenDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail.$3,
                  style: TextStyle(fontSize: 11.5, color: context.appMutedText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String, String) _portionDetailFor(double amount) {
    if ((amount - 0.25).abs() < 0.05) {
      return (
        Icons.eco_outlined,
        'wellness.portion_quarter'.tr,
        'wellness.portion_quarter_desc'.tr,
      );
    }
    if ((amount - 0.5).abs() < 0.1) {
      return (
        Icons.rice_bowl_outlined,
        'wellness.portion_small'.tr,
        'wellness.portion_small_desc'.tr,
      );
    }
    if ((amount - 1.0).abs() < 0.15) {
      return (
        Icons.dinner_dining_outlined,
        'wellness.portion_regular'.tr,
        'wellness.portion_regular_desc'.tr,
      );
    }
    if ((amount - 1.5).abs() < 0.2) {
      return (
        Icons.ramen_dining_outlined,
        'wellness.portion_large'.tr,
        'wellness.portion_large_desc'.tr,
      );
    }
    if ((amount - 2.0).abs() < 0.25) {
      return (
        Icons.set_meal_outlined,
        'wellness.portion_xlarge'.tr,
        'wellness.portion_xlarge_desc'.tr,
      );
    }
    return (
      Icons.straighten_rounded,
      'wellness.custom'.tr,
      '${_formatAmount(amount)} ${widget.controller.foodUnit.value.trOrSelf}',
    );
  }

  Widget _drinkBody(BuildContext context) {
    final cupMl = widget.controller.drinkCupMl.value;
    final fraction = widget.controller.drinkConsumedFraction.value;
    final percentage = (fraction * 100).round();
    final photo = widget.controller.selectedImage.value;
    final selectedSugar = widget.controller.drinkSugarPercentage.value;

    final isCustomCup = cupMl != 250.0 && cupMl != 500.0 && cupMl != 700.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VisualPortionSelector(
          isDrink: true,
          selectedAmount: cupMl,
          drinkSugarPercentage: selectedSugar,
          baseCalories: widget.controller.estimatedCalories,
          onFoodAmountChanged: (_) {},
          onDrinkCupChanged: (ml) {
            widget.controller.setDrinkCupMl(ml);
          },
          onDrinkSugarChanged: (sugar) {
            widget.controller.setDrinkSugarPercentage(sugar);
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _showCustomCupDialog(context),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: Text(
              isCustomCup
                  ? '${cupMl.round()} ml (${'wellness.custom'.tr})'
                  : 'wellness.enter_custom_cup_size'.tr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCustomCup ? greenDark : context.appMutedText,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'wellness.how_much_did_you_drink'.tr,
          style: TextStyle(
            color: context.appText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: green,
            inactiveTrackColor:
                context.appIsDark
                    ? context.appColorScheme.surfaceContainerHighest
                    : const Color(0xFFE5E7EB),
            thumbColor: green,
            overlayColor: green.withValues(alpha: .14),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: fraction,
            min: .25,
            max: 1.0,
            divisions: 3,
            onChanged: widget.controller.setDrinkConsumedFraction,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:
                [25, 50, 75, 100].map((step) {
                  final active = percentage == step;
                  return Text(
                    '$step%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color:
                          active ? _accentText(context) : context.appMutedText,
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        _previewBox(
          context,
          photo: photo,
          title: 'wellness.volume_to_analyse'.tr,
          subtitle: 'wellness.portion_of_cup'.trParams({
            'percent': '$percentage',
            'cup': '${cupMl.round()}',
          }),
          mainText: '${widget.controller.selectedAmount.round()} ml',
          extraBadge:
              '🔥 ~ ${widget.controller.estimatedCalories.round()} kcal • ${'wellness.sugar_percentage'.trParams({'percent': '$selectedSugar'})}',
        ),
        const SizedBox(height: 12),
        _infoBox(
          context,
          text: 'wellness.nutrition_recalculated_drink_notice'.trParams({
            'volume': '${widget.controller.selectedAmount.round()} ml',
          }),
        ),
      ],
    );
  }

  Widget _previewBox(
    BuildContext context, {
    required File? photo,
    required String title,
    String? subtitle,
    required String mainText,
    String? extraBadge,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _previewSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _previewBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: context.appElevatedSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _previewBorder(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child:
                photo != null && photo.existsSync()
                    ? Image.file(photo, fit: BoxFit.cover)
                    : const Icon(
                      Icons.fastfood_rounded,
                      color: green,
                      size: 28,
                    ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _accentText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  mainText,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (extraBadge != null && extraBadge.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    extraBadge,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(BuildContext context, {required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: context.appIsDark ? const Color(0xFF102A43) : infoBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.appIsDark ? const Color(0xFF315A7D) : infoBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: context.appIsDark ? const Color(0xFF93C5FD) : infoBlue,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color:
                    context.appIsDark
                        ? const Color(0xFFBFDBFE)
                        : const Color(0xFF1E40AF),
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(top: BorderSide(color: context.appBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: context.appText,
                  backgroundColor: context.appSurfaceLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'common.cancel'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: context.appOnBrand,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.controller.hasCompleteResult
                      ? 'wellness.update_amount'.tr
                      : 'wellness.continue_analysis'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
