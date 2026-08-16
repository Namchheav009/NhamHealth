import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/food_source_detail_controller.dart';

class FoodAmountEditorCard extends GetView<FoodSourceDetailController> {
  const FoodAmountEditorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit amount',
              style: TextStyle(
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
                _amountChip('Small'),
                _amountChip('Medium'),
                _amountChip('Large'),
                _amountChip('Not sure'),
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
                    label: const Text(
                      'Re-analyze with AI',
                      style: TextStyle(fontSize: 11),
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
                          ? 'Hide manual edit'
                          : 'Edit manually',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),

            if (controller.showManualEditor.value) ...[
              const SizedBox(height: 14),
              _manualAmountCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _amountChip(String label) {
    final selected = controller.selectedSize.value == label;

    return InkWell(
      onTap: () => controller.selectSize(label),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF2EC) : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFFA875) : const Color(0xFFE8E8E8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    selected
                        ? const Color(0xFFFF641E)
                        : const Color(0xFF666666),
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

  Widget _manualAmountCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9E9E9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit amount manually',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _roundButton(
                icon: Icons.remove_rounded,
                onTap: controller.decreaseAmount,
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE3E3E3)),
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
              const Text(
                'ml',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
              const SizedBox(width: 8),

              _roundButton(
                icon: Icons.add_rounded,
                onTap: controller.increaseAmount,
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            children: [
              _quickAmount('+50', () => controller.addAmount(50)),
              _quickAmount('+100', () => controller.addAmount(100)),
              _quickAmount('+200', () => controller.addAmount(200)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 50,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4EF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFBE9D)),
        ),
        child: Icon(icon, color: const Color(0xFFFF641E)),
      ),
    );
  }

  Widget _quickAmount(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2EC),
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
