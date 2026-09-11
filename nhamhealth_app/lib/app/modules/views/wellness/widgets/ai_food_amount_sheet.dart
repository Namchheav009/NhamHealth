import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/wellness/ai_food_controller.dart';

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
      return Container(
        constraints: BoxConstraints(
          maxWidth: 620,
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
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
                    if (isDrink) _drinkBody(context) else _foodBody(context),
                  ],
                ),
              ),
            ),
            _sheetActions(context),
          ],
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
        const SizedBox(height: 16),
        Text(
          'wellness.quick_select'.tr,
          style: TextStyle(
            color: context.appText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _quickFoodChip(context, label: '1/4', value: 0.25),
            const SizedBox(width: 7),
            _quickFoodChip(context, label: '1/2', value: 0.5),
            const SizedBox(width: 7),
            _quickFoodChip(context, label: '1', value: 1.0),
            const SizedBox(width: 7),
            _quickFoodChip(context, label: '1.5', value: 1.5),
            const SizedBox(width: 7),
            _quickFoodChip(context, label: '2', value: 2.0),
          ],
        ),
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

  Widget _quickFoodChip(
    BuildContext context, {
    required String label,
    required double value,
  }) {
    final isSelected =
        (widget.controller.foodAmount.value - value).abs() < 0.01;

    return Expanded(
      child: Material(
        color: isSelected ? mintSelected : context.appSurfaceLow,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _onQuickFoodAmountSelected(value),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? green : context.appBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? green : context.appText,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _drinkBody(BuildContext context) {
    final cupMl = widget.controller.drinkCupMl.value;
    final fraction = widget.controller.drinkConsumedFraction.value;
    final percentage = (fraction * 100).round();
    final photo = widget.controller.selectedImage.value;
    final selectedSugar = widget.controller.drinkSugarPercentage.value;

    final isCustomCup = cupMl != 250.0 && cupMl != 350.0 && cupMl != 500.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wellness.cup_size'.tr,
          style: TextStyle(
            color: context.appText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _cupSizeCard(
              context,
              sizeCode: 'S',
              volumeLabel: '250 ml',
              isSelected: !isCustomCup && cupMl == 250.0,
              icon: Icons.local_bar_outlined,
              onTap: () => widget.controller.setDrinkCupMl(250.0),
            ),
            const SizedBox(width: 8),
            _cupSizeCard(
              context,
              sizeCode: 'M',
              volumeLabel: '350 ml',
              isSelected: !isCustomCup && cupMl == 350.0,
              icon: Icons.local_drink_rounded,
              onTap: () => widget.controller.setDrinkCupMl(350.0),
            ),
            const SizedBox(width: 8),
            _cupSizeCard(
              context,
              sizeCode: 'L',
              volumeLabel: '500 ml',
              isSelected: !isCustomCup && cupMl == 500.0,
              icon: Icons.coffee_outlined,
              onTap: () => widget.controller.setDrinkCupMl(500.0),
            ),
            const SizedBox(width: 8),
            _cupSizeCard(
              context,
              sizeCode:
                  isCustomCup ? '${cupMl.round()}ml' : 'wellness.custom'.tr,
              volumeLabel: isCustomCup ? 'wellness.custom'.tr : '',
              isSelected: isCustomCup,
              icon: Icons.edit_outlined,
              onTap: () => _showCustomCupDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 18),
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
            inactiveTrackColor: const Color(0xFFE5E7EB),
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
                      color: active ? greenDark : context.appMutedText,
                    ),
                  );
                }).toList(),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'wellness.sugar_level'.tr,
          style: TextStyle(
            color: context.appText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children:
              [0, 25, 50, 75, 100].map((sugar) {
                final isSelected = selectedSugar == sugar;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: sugar == 100 ? 0 : 7),
                    child: Material(
                      color: isSelected ? mintSelected : context.appSurfaceLow,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap:
                            () => widget.controller.setDrinkSugarPercentage(
                              sugar,
                            ),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? green : context.appBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '$sugar%',
                            style: TextStyle(
                              color: isSelected ? green : context.appText,
                              fontSize: 12,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
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

  Widget _cupSizeCard(
    BuildContext context, {
    required String sizeCode,
    required String volumeLabel,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: isSelected ? mintSelected : context.appSurfaceLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? green : context.appBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected ? green : context.appMutedText,
                ),
                const SizedBox(height: 5),
                Text(
                  sizeCode,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? green : context.appText,
                  ),
                ),
                if (volumeLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    volumeLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? greenDark : context.appMutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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
        color: mintBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mintBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: mintBorder),
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
                  style: const TextStyle(
                    color: greenDark,
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
        color: infoBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: infoBlue, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF1E40AF),
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
