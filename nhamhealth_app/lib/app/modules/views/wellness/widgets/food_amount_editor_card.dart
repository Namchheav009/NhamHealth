import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/wellness/food_source_detail_controller.dart';

class FoodAmountEditorCard extends GetView<FoodSourceDetailController> {
  const FoodAmountEditorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit amount'.tr,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF555555),
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _amountChip(context, 'Small'),
                _amountChip(context, 'Medium'),
                _amountChip(context, 'Large'),
                _amountChip(context, 'Not sure'),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.reanalyzeWithAi,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00A651),
                      side: const BorderSide(color: Color(0xFF00A651)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    label: Text(
                      'Re-analyze with AI'.tr,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.toggleManualEditor,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00A651),
                      side: const BorderSide(color: Color(0xFF00A651)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    label: Text(
                      controller.showManualEditor.value
                          ? 'Hide manual edit'.tr
                          : 'Edit manually'.tr,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),

            if (controller.showManualEditor.value) ...[
              const SizedBox(height: 14),
              _manualAmountCard(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amountChip(BuildContext context, String label) {
    final selected = controller.selectedSize.value == label;

    return InkWell(
      onTap: () => controller.selectSize(label),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color:
              selected
                  ? Color.alphaBlend(
                    const Color(0xFFFF641E).withValues(alpha: .12),
                    context.appSurfaceLow,
                  )
                  : context.appSubtleSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFFA875) : context.appBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.tr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFFFF641E) : context.appText,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 5),
              const Icon(
                Icons.check_circle,
                size: 14,
                color: Color(0xFFFF641E),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _manualAmountCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSubtleSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit amount manually'.tr,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _roundButton(
                context: context,
                icon: Icons.remove_rounded,
                onTap: controller.decreaseAmount,
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: context.appField,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: TextField(
                    controller: controller.amountController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: controller.updateAmountFromInput,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),
              Text(
                'ml'.tr,
                style: TextStyle(fontSize: 11, color: context.appMutedText),
              ),
              const SizedBox(width: 8),

              _roundButton(
                context: context,
                icon: Icons.add_rounded,
                onTap: controller.increaseAmount,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            children: [
              _quickAmount(context, '+50', () => controller.addAmount(50)),
              _quickAmount(context, '+100', () => controller.addAmount(100)),
              _quickAmount(context, '+200', () => controller.addAmount(200)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 50,
        height: 42,
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            const Color(0xFFFF641E).withValues(alpha: .11),
            context.appSurfaceLow,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFBE9D)),
        ),
        child: Icon(icon, color: const Color(0xFFFF641E)),
      ),
    );
  }

  Widget _quickAmount(BuildContext context, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            const Color(0xFFFF641E).withValues(alpha: .10),
            context.appSurfaceLow,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFC9AE)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFFF6B35),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: context.appSurfaceLow,
      border: Border.all(color: context.appBorder),
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: context.appShadow,
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
