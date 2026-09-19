import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class AiFoodTipsSheet extends StatelessWidget {
  const AiFoodTipsSheet({super.key});

  static const Color green = Color(0xFF00A651);
  static const Color amber = Color(0xFFD97706);
  static const Color amberLightBg = Color(0xFFFEF3C7);

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;

    return Container(
      constraints: BoxConstraints(
        maxWidth: 620,
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
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
          // Drag handle
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 20),
                  _buildTipItem(
                    context,
                    icon: Icons.wb_sunny_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg:
                        isDark
                            ? const Color(0xFF382910)
                            : const Color(0xFFFEF3C7),
                    title: 'Good, Bright Lighting',
                    description:
                        'Capture photos under natural daylight or strong indoor lighting. Avoid heavy shadows or dim light so the AI can distinguish ingredients and ingredients clearly.',
                  ),
                  const SizedBox(height: 14),
                  _buildTipItem(
                    context,
                    icon: Icons.camera_alt_rounded,
                    iconColor: green,
                    iconBg:
                        isDark
                            ? const Color(0xFF143021)
                            : const Color(0xFFEAF7EE),
                    title: '45° Angle or Overhead View',
                    description:
                        'Hold the camera at a 45-degree angle or directly overhead. This provides depth and perspective, giving the AI the best estimate of meal volume and portions.',
                  ),
                  const SizedBox(height: 14),
                  _buildTipItem(
                    context,
                    icon: Icons.center_focus_strong_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBg:
                        isDark
                            ? const Color(0xFF132742)
                            : const Color(0xFFEFF6FF),
                    title: 'Center the Main Food or Drink',
                    description:
                        'Place your meal or beverage right in the center of the frame, filling most of the viewfinder without blur.',
                  ),
                  const SizedBox(height: 14),
                  _buildTipItem(
                    context,
                    icon: Icons.layers_clear_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBg:
                        isDark
                            ? const Color(0xFF281C3F)
                            : const Color(0xFFF5F3FF),
                    title: 'Remove Packaging and Lids',
                    description:
                        'Take off cup lids, wrapper foil, takeout covers, or napkins that hide the food. AI recognition works best with directly visible foods.',
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border(top: BorderSide(color: context.appBorder)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Got it, thanks!',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = context.appIsDark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3B2E15) : amberLightBg,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.lightbulb_rounded, color: amber, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Photography Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.appText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Help AI recognize your food and calculate accurate nutrition.',
                style: TextStyle(fontSize: 12, color: context.appMutedText),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          color: context.appMutedText,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildTipItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String description,
  }) {
    final isDark = context.appIsDark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? context.appSurfaceLow : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.appText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: context.appMutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
