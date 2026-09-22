import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/inner_shadow.dart';
import '../../../controllers/home/home_controller.dart';

class HomeQuickActions extends GetView<HomeController> {
  const HomeQuickActions({super.key});

  static const green = Color(0xFF00AE5B);

  @override
  Widget build(BuildContext context) {
    const radius = 18.0;
    return Container(
      height: 164,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.appIsDark
            ? null
            : context.appElevatedSurface.withValues(alpha: 0.96),
        gradient: context.appIsDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF071712),
                  Color(0xFF0B2118),
                  Color(0xFF102B1D),
                ],
                stops: [0, 0.56, 1],
              )
            : null,
        borderRadius: BorderRadius.circular(radius),
        border: context.appIsDark
            ? Border.all(color: const Color(0xFF4ADE80).withValues(alpha: 0.34))
            : null,
        boxShadow: context.appIsDark
            ? [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                  blurRadius: 24,
                  spreadRadius: -3,
                  offset: const Offset(0, 8),
                ),
                const BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ]
            : context.appHomeCardShadow,
      ),
      child: InnerShadow(
        borderRadius: BorderRadius.circular(radius),
        shadows: context.appIsDark ? context.appInnerShadow : const [],
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('home-action-scan-food'),
            onTap: () {
              try {
                HapticFeedback.lightImpact();
              } catch (_) {}
              controller.openFoodAnalyzer();
            },
            borderRadius: BorderRadius.circular(radius),
            splashColor: green.withValues(alpha: 0.10),
            highlightColor: green.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 14, 13, 14),
              child: Row(
                children: [
                  const _FoodScannerPreview(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'home.action_scan_food'.tr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.appText,
                                  fontSize: 21,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: green,
                              size: 27,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(
                              child: _ScanBenefit(
                                icon: Icons.bolt_rounded,
                                labelKey: 'home.scan_quick',
                                englishLabel: 'Quick',
                                khmerLabel: 'រហ័ស',
                              ),
                            ),
                            _BenefitDivider(),
                            Expanded(
                              child: _ScanBenefit(
                                icon: Icons.my_location_rounded,
                                labelKey: 'home.scan_accurate',
                                englishLabel: 'Accurate',
                                khmerLabel: 'ត្រឹមត្រូវ',
                              ),
                            ),
                            _BenefitDivider(),
                            Expanded(
                              child: _ScanBenefit(
                                icon: Icons.eco_rounded,
                                labelKey: 'home.scan_nutritious',
                                englishLabel: 'Nutritious',
                                khmerLabel: 'សម្បូរជីវជាតិ',
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _FoodScannerPreview extends StatefulWidget {
  const _FoodScannerPreview();

  @override
  State<_FoodScannerPreview> createState() => _FoodScannerPreviewState();
}

class _FoodScannerPreviewState extends State<_FoodScannerPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  late final Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scanAnimation = CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOutCubic,
    );
    _scanController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF155C35).withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: _ScannerFramePainter(_scanAnimation),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Image.asset(
            'assets/images/homepage/Scan.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  _ScannerFramePainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final progress = animation.value;
    final pulse = 0.78 + (0.22 * (1 - (progress - 0.5).abs() * 2));
    final corner = Paint()
      ..color = const Color(0xFF00A957).withValues(alpha: pulse)
      ..strokeWidth = 3.5 + (pulse * 0.5)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const inset = 11.0;
    const length = 27.0;
    const radius = 14.0;
    final path = Path()
      ..moveTo(inset, inset + length)
      ..lineTo(inset, inset + radius)
      ..quadraticBezierTo(inset, inset, inset + radius, inset)
      ..lineTo(inset + length, inset)
      ..moveTo(size.width - inset - length, inset)
      ..lineTo(size.width - inset - radius, inset)
      ..quadraticBezierTo(size.width - inset, inset, size.width - inset, inset + radius)
      ..lineTo(size.width - inset, inset + length)
      ..moveTo(inset, size.height - inset - length)
      ..lineTo(inset, size.height - inset - radius)
      ..quadraticBezierTo(inset, size.height - inset, inset + radius, size.height - inset)
      ..lineTo(inset + length, size.height - inset)
      ..moveTo(size.width - inset - length, size.height - inset)
      ..lineTo(size.width - inset - radius, size.height - inset)
      ..quadraticBezierTo(size.width - inset, size.height - inset, size.width - inset, size.height - inset - radius)
      ..lineTo(size.width - inset, size.height - inset - length);
    canvas.drawPath(path, corner);

    final scanY = inset + 12 + (size.height - (inset * 2) - 24) * progress;
    final glowRect = Rect.fromLTRB(
      inset + 2,
      scanY - 13,
      size.width - inset - 2,
      scanY + 13,
    );
    final glow = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Color(0x3300D66F),
          Colors.transparent,
        ],
      ).createShader(glowRect);
    canvas.drawRect(glowRect, glow);

    final scanLine = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.transparent, Color(0xFF00C968), Colors.transparent],
        stops: [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(inset, scanY, size.width - inset * 2, 2))
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(inset + 2, scanY),
      Offset(size.width - inset - 2, scanY),
      scanLine,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class _ScanBenefit extends StatelessWidget {
  const _ScanBenefit({
    required this.icon,
    required this.labelKey,
    required this.englishLabel,
    required this.khmerLabel,
  });

  final IconData icon;
  final String labelKey;
  final String englishLabel;
  final String khmerLabel;

  @override
  Widget build(BuildContext context) {
    final translatedLabel = labelKey.tr;
    final label = translatedLabel == labelKey
        ? (Get.locale?.languageCode == 'km' ? khmerLabel : englishLabel)
        : translatedLabel;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFD9FAE7),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: HomeQuickActions.green, size: 23),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF006B38),
            fontSize: 12,
            height: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BenefitDivider extends StatelessWidget {
  const _BenefitDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      margin: const EdgeInsets.only(bottom: 19),
      color: HomeQuickActions.green.withValues(alpha: 0.16),
    );
  }
}
