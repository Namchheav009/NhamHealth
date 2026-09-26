
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../controllers/profile/profile_controller.dart';
import '../../models/profile/bmi_assessment.dart';

class BmiAnalysisView extends GetView<ProfileController> {
  const BmiAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          context.appIsDark
              ? const Color(0xFF0B1410)
              : const Color(0xFFF8FAF7),
      body: Stack(
        children: [
          // Decorative background with leaves and soft glows
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundBotanicalPainter(isDark: context.appIsDark),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      AppSpacing.isTabletFor(context)
                          ? AppSpacing.maxWidePaddedContentWidth
                          : AppSpacing.maxPaddedContentWidth,
                ),
                child: Column(
                  children: [
                    _header(context),
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value &&
                            controller.dashboard.value == null) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (controller.errorMessage.value != null &&
                            controller.dashboard.value == null) {
                          return _ErrorState(onRetry: controller.loadProfile);
                        }
                        return RefreshIndicator(
                          onRefresh: controller.refreshProfile,
                          color: AppColors.primaryGreen,
                          child: _content(context),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final pagePadding = AppSpacing.pageHorizontalFor(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        pagePadding,
        AppSpacing.pageTop,
        pagePadding,
        0,
      ),
      child: AppBackHeader(
        title: 'bmi.title'.tr,
        backButtonKey: const ValueKey('bmi-back-button'),
        onBack: Get.back,
      ),
    );
  }

  Widget _content(BuildContext context) {
    final rawAge = controller.age.value;
    final rawHeight = controller.height.value.toDouble();
    final rawWeight = controller.weight.value.toDouble();

    final age = rawAge;
    final height = rawHeight;
    final weight = rawWeight;
    final bmi = BmiAssessment.rounded(heightCm: height, weightKg: weight);
    final pagePadding = AppSpacing.pageHorizontalFor(context);

    if (age <= 0 || height <= 0 || weight <= 0 || bmi <= 0) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(pagePadding, 48, pagePadding, 24),
        children: [_MissingDataCard(onEdit: controller.editProfile)],
      );
    }

    final statusKey = BmiAssessment.statusKey(
      age: age,
      heightCm: height,
      weightKg: weight,
    );
    final guidanceKey = BmiAssessment.guidanceKey(age: age, bmi: bmi);
    final focusKeys = BmiAssessment.nutritionFocusKeys(age: age, bmi: bmi);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(pagePadding, 6, pagePadding, 24),
      children: [
        _ResultCard(bmi: bmi, statusKey: statusKey, age: age),
        const SizedBox(height: 14),
        _MeasurementsCard(
          height: height,
          weight: weight,
          age: age,
          onEdit: controller.editProfile,
        ),
        const SizedBox(height: 14),
        _HealthGuidanceCard(guidanceText: guidanceKey.tr),
        const SizedBox(height: 14),
        _NutritionFocusCard(focusKeys: focusKeys),
        const SizedBox(height: 18),
        _NutritionSummaryButton(
          onPressed: () => Get.toNamed<void>(AppRoutes.wellness),
        ),
      ],
    );
  }
}

String _measurementText(double value) {
  final text = value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

class _StatusConfig {
  const _StatusConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final IconData icon;
}

_StatusConfig _getStatusConfig(
  BuildContext context, {
  required double bmi,
  required int age,
}) {
  final isDark = context.appIsDark;
  if (age < 18) {
    return _StatusConfig(
      backgroundColor:
          isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      textColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
      iconColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      icon: Icons.info_rounded,
    );
  }
  if (bmi < 18.5) {
    return _StatusConfig(
      backgroundColor:
          isDark ? const Color(0xFF0C2A44) : const Color(0xFFE0F2FE),
      textColor: isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1),
      iconColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
      icon: Icons.info_rounded,
    );
  }
  if (bmi < 25.0) {
    return _StatusConfig(
      backgroundColor:
          isDark ? const Color(0xFF0F3924) : const Color(0xFFE8F8EE),
      textColor: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
      iconColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
      icon: Icons.check_circle_rounded,
    );
  }
  if (bmi < 30.0) {
    return _StatusConfig(
      backgroundColor:
          isDark ? const Color(0xFF3D2E0B) : const Color(0xFFFFF3D6),
      textColor: isDark ? const Color(0xFFFDE047) : const Color(0xFF9A5B00),
      iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFE08A00),
      icon: Icons.error_rounded,
    );
  }
  return _StatusConfig(
    backgroundColor:
        isDark ? const Color(0xFF3B1212) : const Color(0xFFFEE2E2),
    textColor: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
    iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
    icon: Icons.warning_rounded,
  );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.bmi,
    required this.statusKey,
    required this.age,
  });

  final double bmi;
  final String statusKey;
  final int age;

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(context, bmi: bmi, age: age);

    return Container(
      key: const ValueKey('bmi-result-card'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.appIsDark ? 0.25 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'bmi.current_bmi'.tr,
                      style: TextStyle(
                        color: context.appMutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bmi.toStringAsFixed(1),
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 50,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusConfig.backgroundColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusConfig.icon,
                            color: statusConfig.iconColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              statusKey.tr,
                              style: TextStyle(
                                color: statusConfig.textColor,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _BmiGaugeSilhouette(bmi: bmi),
            ],
          ),
          const SizedBox(height: 14),
          _BmiSegmentedBar(bmi: bmi),
        ],
      ),
    );
  }
}

class _BmiGaugeSilhouette extends StatelessWidget {
  const _BmiGaugeSilhouette({required this.bmi});

  final double bmi;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: CustomPaint(
        painter: _BmiGaugeSilhouettePainter(
          bmi: bmi,
          isDark: context.appIsDark,
        ),
      ),
    );
  }
}

class _BmiGaugeSilhouettePainter extends CustomPainter {
  const _BmiGaugeSilhouettePainter({required this.bmi, required this.isDark});

  final double bmi;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track arc around figure
    final trackPaint =
        Paint()
          ..color =
              isDark ? const Color(0xFF1E3A2B) : const Color(0xFFE9F5EE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.5
          ..strokeCap = StrokeCap.round;

    // 270 degree track arc
    const startAngle = 2.45;
    const sweepAngle = 4.4;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active progress arc on top right
    final activePaint =
        Paint()
          ..color = const Color(0xFF22C55E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7.5
          ..strokeCap = StrokeCap.round;

    const activeStart = 4.35;
    const activeSweep = 1.35;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      activeStart,
      activeSweep,
      false,
      activePaint,
    );

    // Human silhouette figure in mint green. Scale it independently from the
    // gauge so it remains the visual focus instead of looking lost in the arc.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.3);
    canvas.translate(-center.dx, -center.dy);

    final figurePaint =
        Paint()
          ..color =
              isDark ? const Color(0xFF5EAA7E) : const Color(0xFF78C697)
          ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(Offset(center.dx, center.dy - 20), 7.5, figurePaint);

    // Stylized body with arms and legs
    final bodyPath = Path();
    bodyPath.moveTo(center.dx - 3.5, center.dy - 10.5);
    // Left shoulder & arm
    bodyPath.quadraticBezierTo(
      center.dx - 12.5,
      center.dy - 9,
      center.dx - 14,
      center.dy - 2,
    );
    bodyPath.lineTo(center.dx - 15, center.dy + 8);
    bodyPath.arcToPoint(
      Offset(center.dx - 10, center.dy + 8),
      radius: const Radius.circular(2.5),
    );
    bodyPath.lineTo(center.dx - 9, center.dy + 1);
    // Torso left & leg
    bodyPath.lineTo(center.dx - 9, center.dy + 12);
    bodyPath.lineTo(center.dx - 9, center.dy + 27);
    bodyPath.arcToPoint(
      Offset(center.dx - 3, center.dy + 27),
      radius: const Radius.circular(3),
    );
    bodyPath.lineTo(center.dx - 2.5, center.dy + 13.5);
    // Crotch
    bodyPath.lineTo(center.dx + 2.5, center.dy + 13.5);
    // Right leg
    bodyPath.lineTo(center.dx + 3, center.dy + 27);
    bodyPath.arcToPoint(
      Offset(center.dx + 9, center.dy + 27),
      radius: const Radius.circular(3),
    );
    bodyPath.lineTo(center.dx + 9, center.dy + 12);
    // Right arm & shoulder
    bodyPath.lineTo(center.dx + 9, center.dy + 1);
    bodyPath.lineTo(center.dx + 10, center.dy + 8);
    bodyPath.arcToPoint(
      Offset(center.dx + 15, center.dy + 8),
      radius: const Radius.circular(2.5),
    );
    bodyPath.lineTo(center.dx + 14, center.dy - 2);
    bodyPath.quadraticBezierTo(
      center.dx + 12.5,
      center.dy - 9,
      center.dx + 3.5,
      center.dy - 10.5,
    );
    bodyPath.close();

    canvas.drawPath(bodyPath, figurePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BmiGaugeSilhouettePainter oldDelegate) =>
      oldDelegate.bmi != bmi || oldDelegate.isDark != isDark;
}

class _BmiSegmentedBar extends StatelessWidget {
  const _BmiSegmentedBar({required this.bmi});

  final double bmi;

  static const Color _blue = Color(0xFF93C5FD);
  static const Color _green = Color(0xFF86EFAC);
  static const Color _amber = Color(0xFFFCD34D);
  static const Color _coral = Color(0xFFFCA5A5);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        // Pin position ratio (0.0 to 1.0)
        double ratio;
        Color indicatorColor;
        if (bmi < 18.5) {
          final t = (bmi - 14.0).clamp(0.0, 4.5) / 4.5;
          ratio = 0.25 * t;
          indicatorColor = const Color(0xFF0284C7);
        } else if (bmi < 25.0) {
          final t = (bmi - 18.5).clamp(0.0, 6.4) / 6.4;
          ratio = 0.25 + 0.25 * t;
          indicatorColor = const Color(0xFF16A34A);
        } else if (bmi < 30.0) {
          final t = (bmi - 25.0).clamp(0.0, 4.9) / 4.9;
          ratio = 0.50 + 0.25 * t;
          indicatorColor = const Color(0xFFD97706);
        } else {
          final t = (bmi - 30.0).clamp(0.0, 10.0) / 10.0;
          ratio = 0.75 + 0.25 * t;
          indicatorColor = const Color(0xFFDC2626);
        }

        final pinX = (ratio * totalWidth).clamp(6.0, totalWidth - 6.0);

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(child: SizedBox.shrink()),
                _BmiRangeLabel(
                  range: '18.5 – 24.9',
                  label: 'bmi.range_normal'.tr,
                ),
                const Expanded(child: SizedBox.shrink()),
                _BmiRangeLabel(
                  range: '≥ 30.0',
                  label: 'bmi.range_obesity'.tr,
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 20,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 6,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _blue,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(99),
                                bottomLeft: Radius.circular(99),
                                topRight: Radius.circular(2),
                                bottomRight: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: _amber,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _coral,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(99),
                                bottomRight: Radius.circular(99),
                                topLeft: Radius.circular(2),
                                bottomLeft: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: pinX - 5.5,
                    top: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: indicatorColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: indicatorColor.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 3.5,
                              height: 3.5,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 9,
                          color: indicatorColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BmiRangeLabel(
                  range: '< 18.5',
                  label: 'bmi.range_underweight'.tr,
                ),
                const Expanded(child: SizedBox.shrink()),
                _BmiRangeLabel(
                  range: '25.0 – 29.9',
                  label: 'bmi.range_overweight'.tr,
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _BmiRangeLabel extends StatelessWidget {
  const _BmiRangeLabel({required this.range, required this.label});

  final String range;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 15,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  range,
                  maxLines: 1,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 1),
            SizedBox(
              height: 15,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementsCard extends StatelessWidget {
  const _MeasurementsCard({
    required this.height,
    required this.weight,
    required this.age,
    required this.onEdit,
  });

  final double height;
  final double weight;
  final int age;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    final iconBg =
        isDark ? const Color(0xFF132A1C) : const Color(0xFFE8F8EE);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.appIsDark ? 0.25 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.straighten_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'bmi.your_measurements'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          color: AppColors.primaryGreen,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'bmi.edit'.tr,
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MeasurementColumn(
                  icon: Icons.accessibility_new_rounded,
                  label: 'bmi.height'.tr,
                  value: '${_measurementText(height)} cm',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: context.appBorder.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _MeasurementColumn(
                  icon: Icons.shopping_bag_outlined,
                  label: 'bmi.weight'.tr,
                  value: '${_measurementText(weight)} kg',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: context.appBorder.withValues(alpha: 0.5),
              ),
              Expanded(
                child: _MeasurementColumn(
                  icon: Icons.calendar_today_rounded,
                  label: 'bmi.age'.tr,
                  value: '$age ${'bmi.years'.tr}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeasurementColumn extends StatelessWidget {
  const _MeasurementColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    final iconBg =
        isDark ? const Color(0xFF132A1C) : const Color(0xFFE8F8EE);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  height: 20,
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _HealthGuidanceCard extends StatelessWidget {
  const _HealthGuidanceCard({required this.guidanceText});

  final String guidanceText;

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    final iconBg =
        isDark ? const Color(0xFF132A1C) : const Color(0xFFE8F8EE);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.appIsDark ? 0.25 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'bmi.health_guidance'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  guidanceText,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: 13.5,
                    height: 1.48,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 112,
                height: 112,
                child: Image.asset(
                  'assets/images/profile/Health Guidance.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthGuidanceIllustrationPainter extends CustomPainter {
  const _HealthGuidanceIllustrationPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background rolling hill 1 (lightest)
    final hill1 =
        Path()
          ..moveTo(0, h)
          ..quadraticBezierTo(w * 0.45, h * 0.40, w, h * 0.58)
          ..lineTo(w, h)
          ..close();
    canvas.drawPath(
      hill1,
      Paint()
        ..color =
            isDark ? const Color(0xFF132A1C) : const Color(0xFFF0FAF4),
    );

    // Background rolling hill 2
    final hill2 =
        Path()
          ..moveTo(w * 0.15, h)
          ..quadraticBezierTo(w * 0.65, h * 0.62, w, h * 0.76)
          ..lineTo(w, h)
          ..close();
    canvas.drawPath(
      hill2,
      Paint()
        ..color =
            isDark ? const Color(0xFF1B3D28) : const Color(0xFFE2F5EA),
    );

    // Plant stem
    final stem =
        Path()
          ..moveTo(w * 0.52, h * 0.72)
          ..quadraticBezierTo(w * 0.50, h * 0.46, w * 0.52, h * 0.38);
    canvas.drawPath(
      stem,
      Paint()
        ..color = const Color(0xFF52B788)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Left curved leaf
    final leftLeaf =
        Path()
          ..moveTo(w * 0.52, h * 0.64)
          ..cubicTo(
            w * 0.28,
            h * 0.58,
            w * 0.30,
            h * 0.44,
            w * 0.34,
            h * 0.40,
          )
          ..cubicTo(
            w * 0.42,
            h * 0.44,
            w * 0.48,
            h * 0.54,
            w * 0.52,
            h * 0.64,
          )
          ..close();
    canvas.drawPath(
      leftLeaf,
      Paint()..color = const Color(0xFF74C69D),
    );

    // Right curved leaf
    final rightLeaf =
        Path()
          ..moveTo(w * 0.52, h * 0.64)
          ..cubicTo(
            w * 0.72,
            h * 0.56,
            w * 0.82,
            h * 0.40,
            w * 0.78,
            h * 0.35,
          )
          ..cubicTo(
            w * 0.68,
            h * 0.40,
            w * 0.58,
            h * 0.52,
            w * 0.52,
            h * 0.64,
          )
          ..close();
    canvas.drawPath(
      rightLeaf,
      Paint()..color = const Color(0xFF52B788),
    );

    // Top heart
    final heartCenter = Offset(w * 0.52, h * 0.22);
    final heartWidth = w * 0.22;
    final heartHeight = h * 0.20;

    final heart =
        Path()
          ..moveTo(heartCenter.dx, heartCenter.dy + heartHeight * 0.45)
          ..cubicTo(
            heartCenter.dx - heartWidth * 0.55,
            heartCenter.dy + heartHeight * 0.05,
            heartCenter.dx - heartWidth * 0.55,
            heartCenter.dy - heartHeight * 0.45,
            heartCenter.dx,
            heartCenter.dy - heartHeight * 0.25,
          )
          ..cubicTo(
            heartCenter.dx + heartWidth * 0.55,
            heartCenter.dy - heartHeight * 0.45,
            heartCenter.dx + heartWidth * 0.55,
            heartCenter.dy + heartHeight * 0.05,
            heartCenter.dx,
            heartCenter.dy + heartHeight * 0.45,
          )
          ..close();

    canvas.drawPath(
      heart,
      Paint()..color = const Color(0xFF74C69D),
    );
  }

  @override
  bool shouldRepaint(
    covariant _HealthGuidanceIllustrationPainter oldDelegate,
  ) => oldDelegate.isDark != isDark;
}

class _NutritionFocusCard extends StatelessWidget {
  const _NutritionFocusCard({required this.focusKeys});

  final List<String> focusKeys;

  @override
  Widget build(BuildContext context) {
    final isDark = context.appIsDark;
    final iconBg =
        isDark ? const Color(0xFF132A1C) : const Color(0xFFE8F8EE);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.appIsDark ? 0.25 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'bmi.nutrition_focus'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children:
                      focusKeys.map((key) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF10B981),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  key.tr,
                                  style: TextStyle(
                                    color: context.appText,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 112,
                height: 112,
                child: Image.asset(
                  'assets/images/profile/Nutritions.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaladBowlIllustrationPainter extends CustomPainter {
  const _SaladBowlIllustrationPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soft aura glow
    final glowCenter = Offset(w * 0.55, h * 0.55);
    canvas.drawCircle(
      glowCenter,
      w * 0.44,
      Paint()
        ..color =
            isDark ? const Color(0xFF132A1C) : const Color(0xFFEDFAF1),
    );

    // Sparkles above bowl
    final sparklePaint =
        Paint()
          ..color = const Color(0xFF52B788)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.42, h * 0.22),
      Offset(w * 0.38, h * 0.15),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(w * 0.55, h * 0.19),
      Offset(w * 0.55, h * 0.11),
      sparklePaint,
    );
    canvas.drawLine(
      Offset(w * 0.68, h * 0.22),
      Offset(w * 0.72, h * 0.15),
      sparklePaint,
    );

    // Leaves
    final leafPaint1 = Paint()..color = const Color(0xFF74C69D);
    final leafPaint2 = Paint()..color = const Color(0xFF52B788);
    final leafPaint3 = Paint()..color = const Color(0xFF40916C);

    // Left leaf
    final backLeaf1 =
        Path()
          ..moveTo(w * 0.32, h * 0.55)
          ..cubicTo(
            w * 0.18,
            h * 0.45,
            w * 0.26,
            h * 0.28,
            w * 0.38,
            h * 0.32,
          )
          ..cubicTo(
            w * 0.44,
            h * 0.35,
            w * 0.44,
            h * 0.48,
            w * 0.40,
            h * 0.55,
          )
          ..close();
    canvas.drawPath(backLeaf1, leafPaint2);

    // Center tall leaf
    final centerLeaf =
        Path()
          ..moveTo(w * 0.42, h * 0.55)
          ..cubicTo(
            w * 0.40,
            h * 0.35,
            w * 0.48,
            h * 0.22,
            w * 0.54,
            h * 0.24,
          )
          ..cubicTo(
            w * 0.60,
            h * 0.26,
            w * 0.60,
            h * 0.40,
            w * 0.58,
            h * 0.55,
          )
          ..close();
    canvas.drawPath(centerLeaf, leafPaint1);

    // Right leaf
    final rightLeaf =
        Path()
          ..moveTo(w * 0.55, h * 0.55)
          ..cubicTo(
            w * 0.62,
            h * 0.38,
            w * 0.82,
            h * 0.32,
            w * 0.88,
            h * 0.42,
          )
          ..cubicTo(
            w * 0.90,
            h * 0.50,
            w * 0.76,
            h * 0.55,
            w * 0.65,
            h * 0.58,
          )
          ..close();
    canvas.drawPath(rightLeaf, leafPaint3);

    // Tomato
    final tomatoCenter = Offset(w * 0.38, h * 0.52);
    canvas.drawCircle(
      tomatoCenter,
      w * 0.12,
      Paint()..color = const Color(0xFFFA7268),
    );
    canvas.drawCircle(
      Offset(tomatoCenter.dx - 2, tomatoCenter.dy - 3),
      w * 0.035,
      Paint()..color = const Color(0xFFFFB3AC),
    );

    // Front leaf
    final frontLeaf =
        Path()
          ..moveTo(w * 0.48, h * 0.58)
          ..cubicTo(
            w * 0.58,
            h * 0.44,
            w * 0.76,
            h * 0.46,
            w * 0.78,
            h * 0.56,
          )
          ..cubicTo(
            w * 0.75,
            h * 0.62,
            w * 0.60,
            h * 0.62,
            w * 0.48,
            h * 0.58,
          )
          ..close();
    canvas.drawPath(frontLeaf, leafPaint2);

    // Bowl
    final bowlPath =
        Path()
          ..moveTo(w * 0.20, h * 0.54)
          ..cubicTo(
            w * 0.22,
            h * 0.82,
            w * 0.80,
            h * 0.82,
            w * 0.82,
            h * 0.54,
          )
          ..close();
    canvas.drawPath(
      bowlPath,
      Paint()
        ..color =
            isDark ? const Color(0xFF1E3A2B) : const Color(0xFFC8EFDA),
    );

    // Bowl rim
    final rimPath =
        Path()
          ..moveTo(w * 0.20, h * 0.54)
          ..quadraticBezierTo(w * 0.51, h * 0.57, w * 0.82, h * 0.54);
    canvas.drawPath(
      rimPath,
      Paint()
        ..color =
            isDark ? const Color(0xFF28543E) : const Color(0xFFB2E6C7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(
    covariant _SaladBowlIllustrationPainter oldDelegate,
  ) => oldDelegate.isDark != isDark;
}

class _NutritionSummaryButton extends StatelessWidget {
  const _NutritionSummaryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('bmi-nutrition-summary-button'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00B874), Color(0xFF009C63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00A86B).withValues(alpha: 0.32),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'bmi.view_nutrition_summary'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingDataCard extends StatelessWidget {
  const _MissingDataCard({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.5)),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F8EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_ind_outlined,
              color: AppColors.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'bmi.missing_title'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'bmi.missing_message'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded),
            label: Text('bmi.edit_profile'.tr),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundBotanicalPainter extends CustomPainter {
  const _BackgroundBotanicalPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) return;

    final w = size.width;
    final h = size.height;

    // Top-left soft peach warm glow
    final peachGlow1 =
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFECE0).withValues(alpha: 0.6),
              const Color(0xFFFFECE0).withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(w * 0.05, h * 0.12), radius: 130),
          );
    canvas.drawCircle(Offset(w * 0.05, h * 0.12), 130, peachGlow1);

    // Top-right soft pale green glow
    final greenGlow =
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFD8F3DC).withValues(alpha: 0.7),
              const Color(0xFFD8F3DC).withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(w * 0.90, h * 0.06), radius: 150),
          );
    canvas.drawCircle(Offset(w * 0.90, h * 0.06), 150, greenGlow);

    // Top-right decorative botanical leaves
    final leafPaint =
        Paint()
          ..color = const Color(0xFF95D5B2).withValues(alpha: 0.45)
          ..style = PaintingStyle.fill;

    // Leaf 1
    final l1 =
        Path()
          ..moveTo(w * 0.88, h * 0.04)
          ..quadraticBezierTo(w * 0.85, h * 0.06, w * 0.86, h * 0.08)
          ..quadraticBezierTo(w * 0.90, h * 0.065, w * 0.88, h * 0.04)
          ..close();
    canvas.drawPath(l1, leafPaint);

    // Leaf 2
    final l2 =
        Path()
          ..moveTo(w * 0.94, h * 0.02)
          ..quadraticBezierTo(w * 0.92, h * 0.045, w * 0.93, h * 0.065)
          ..quadraticBezierTo(w * 0.965, h * 0.045, w * 0.94, h * 0.02)
          ..close();
    canvas.drawPath(l2, leafPaint);

    // Leaf 3
    final l3 =
        Path()
          ..moveTo(w * 0.94, h * 0.075)
          ..quadraticBezierTo(w * 0.92, h * 0.09, w * 0.94, h * 0.105)
          ..quadraticBezierTo(w * 0.965, h * 0.09, w * 0.94, h * 0.075)
          ..close();
    canvas.drawPath(l3, leafPaint);

    // Bottom-right soft peach warm glow
    final peachGlow2 =
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFF2E6).withValues(alpha: 0.5),
              const Color(0xFFFFF2E6).withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(w * 0.95, h * 0.82), radius: 140),
          );
    canvas.drawCircle(Offset(w * 0.95, h * 0.82), 140, peachGlow2);
  }

  @override
  bool shouldRepaint(covariant _BackgroundBotanicalPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.errorCoral,
            ),
            const SizedBox(height: 12),
            Text(
              'profile.load_error'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('profile.retry'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
