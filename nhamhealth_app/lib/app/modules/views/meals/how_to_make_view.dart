import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/app_back_header.dart';
import '../../controllers/meals/how_to_make_controller.dart';
import '../../models/meals/meal_model.dart';

class HowToMakeView extends GetView<HowToMakeController> {
  const HowToMakeView({super.key});

  static const Color green = Color(0xFF009E43);
  static const Color darkGreen = Color(0xFF006A38);
  static const Color descriptionGreen = Color(0xFF79AD91);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return MediaQuery(
      data: media.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Screenshot-based logical design width.
            final scale = (constraints.maxWidth / 500).clamp(0.74, 0.90);

            return Stack(
              children: [
                const _HowToMakeBackground(),

                SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(scale),

                        SizedBox(height: 34 * scale),

                        _buildHowToMakeHeader(scale),

                        SizedBox(height: 27 * scale),

                        _buildSteps(scale),

                        SizedBox(height: 13 * scale),

                        _buildHealthyTip(scale),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(double scale) {
    return Padding(
      padding: EdgeInsets.only(left: 9 * scale),
      child: Row(
        children: [
          AppBackButton(onPressed: controller.goBack),

          const SizedBox(width: AppBackButton.headerGap),

          Text(
            'How to make'.tr,
            style: TextStyle(
              fontSize: 23 * scale,
              height: 1,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HOW TO MAKE HERO
  // ============================================================

  Widget _buildHowToMakeHeader(double scale) {
    return SizedBox(
      width: double.infinity,
      height: 103 * scale,
      child: Row(
        children: [
          SizedBox(width: 14 * scale),

          Container(
            width: 74 * scale,
            height: 74 * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE5F1D0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 9 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(13 * scale),
              child: Image.asset(
                'assets/images/food_detail/howtomake.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          SizedBox(width: 31 * scale),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How to make'.tr,
                  style: TextStyle(
                    fontSize: 24 * scale,
                    height: 1,
                    fontWeight: FontWeight.w500,
                    color: green,
                  ),
                ),

                SizedBox(height: 8 * scale),

                Text(
                  (controller.meal?.name ?? '').tr,
                  style: TextStyle(
                    fontSize: 14.5 * scale,
                    height: 1,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF76C48D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEPS
  // ============================================================

  Widget _buildSteps(double scale) {
    return Column(
      children: List.generate(controller.steps.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == controller.steps.length - 1 ? 0 : 8 * scale,
          ),
          child: _CookingStepCard(step: controller.steps[index], scale: scale),
        );
      }),
    );
  }

  // ============================================================
  // HEALTHY TIP
  // ============================================================

  Widget _buildHealthyTip(double scale) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 66 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 7 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6EE).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45 * scale,
            height: 45 * scale,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFBDE4CD),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.eco_rounded,
              size: 28 * scale,
              color: const Color(0xFF6CAD44),
            ),
          ),

          SizedBox(width: 12 * scale),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Healthy Tip'.tr,
                  style: TextStyle(
                    fontSize: 14.5 * scale,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: green,
                  ),
                ),

                SizedBox(height: 5 * scale),

                Text(
                  'Eat immediately to keep the vegetables fresh and crunchy.\nYou can add grilled chicken or shrimp for extra protein!'
                      .tr,
                  style: TextStyle(
                    fontSize: 10.5 * scale,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: descriptionGreen,
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

// ================================================================
// COOKING STEP CARD
// ================================================================

class _CookingStepCard extends StatelessWidget {
  final MealStepModel step;
  final double scale;

  const _CookingStepCard({required this.step, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 95 * scale),
      padding: EdgeInsets.fromLTRB(8 * scale, 7 * scale, 13 * scale, 7 * scale),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.018),
            blurRadius: 12 * scale,
            offset: Offset(0, 3 * scale),
          ),
        ],
      ),
      child: Row(
        children: [
          // =====================================================
          // IMAGE + STEP NUMBER
          // =====================================================
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipOval(
                child: step.image.startsWith('http')
                    ? Image.network(step.image, width: 82 * scale, height: 82 * scale, fit: BoxFit.cover, errorBuilder: (_, _, _) => _stepFallback())
                    : step.image.startsWith('assets/')
                        ? Image.asset(step.image, width: 82 * scale, height: 82 * scale, fit: BoxFit.cover, errorBuilder: (_, _, _) => _stepFallback())
                        : _stepFallback(),
              ),

              Positioned(
                left: -4 * scale,
                top: 3 * scale,
                child: Container(
                  width: 23 * scale,
                  height: 23 * scale,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: HowToMakeView.green,
                  ),
                  child: Text(
                    '${step.number}',
                    style: TextStyle(
                      fontSize: 11.5 * scale,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(width: 16 * scale),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (step.title.isEmpty ? 'Step ${step.number}' : step.title).tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18 * scale,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: HowToMakeView.green,
                  ),
                ),

                SizedBox(height: 7 * scale),

                Text(
                  step.instruction.tr,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.7 * scale,
                    height: 1.18,
                    fontWeight: FontWeight.w500,
                    color: HowToMakeView.descriptionGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepFallback() => Container(
                      width: 82 * scale,
                      height: 82 * scale,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE6F4E8),
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: HowToMakeView.green,
                        size: 30 * scale,
                      ),
                    );
}

// ================================================================
// BACKGROUND
// ================================================================

class _HowToMakeBackground extends StatelessWidget {
  const _HowToMakeBackground();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.appBackground,
      child: SizedBox.expand(
        child: Opacity(
          opacity: context.appIsDark ? 0.12 : 1,
          child: Image.asset(
            'assets/images/food_detail/background.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
