import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/wellness/water_controller.dart';

class WaterView extends GetView<WaterController> {
  const WaterView({super.key});

  static const _blue = Color(0xFF25A9E8);
  static const _image = 'assets/images/homepage/Water.png';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.transparent,
    body: AppBackground(
      lightDecoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            context.appSoftPink,
            context.appBackground,
            context.appSoftGreen,
          ],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          color: _blue,
          onRefresh: controller.loadWater,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _header(context)),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Padding(
                      padding: AppSpacing.pagePaddingFor(
                        context,
                      ).copyWith(top: 12, bottom: 28),
                      child: Obx(() => _content(context)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _header(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontalFor(context),
          12,
          AppSpacing.pageHorizontalFor(context),
          4,
        ),
        child: Row(
          children: [
            AppBackButton(onPressed: Get.back),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'common.water'.tr,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: context.appText,
                ),
              ),
            ),
            Container(
              width: AppBackButton.layoutSize,
              height: AppBackButton.layoutSize,
              decoration: BoxDecoration(
                color: context.appElevatedSurface,
                shape: BoxShape.circle,
                boxShadow: context.appTileShadow,
              ),
              child: const Icon(Icons.bar_chart_rounded, color: _blue),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _content(BuildContext context) {
    if (controller.isLoading.value && controller.currentGlasses.value == 0) {
      return const PageSkeleton.water();
    }
    return Column(
      children: [
        _progressHero(context),
        const SizedBox(height: 10),
        _benefits(context),
        const SizedBox(height: 10),
        _amountCard(context),
        if (controller.errorMessage.value != null) ...[
          const SizedBox(height: 12),
          _errorCard(context, controller.errorMessage.value!),
        ],
        const SizedBox(height: 12),
        _submitButton(),
        const SizedBox(height: 10),
        _todayTotal(context),
        const SizedBox(height: 10),
        _tipCard(context),
      ],
    );
  }

  Widget _progressHero(BuildContext context) => Container(
    key: const ValueKey('water-progress-hero'),
    height: 195,
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE7F8FF)]),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDDF3FC)),
      boxShadow: context.appCardShadow,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        final imageWidth = compact ? 190.0 : 230.0;
        final contentRight = compact ? 165.0 : 205.0;
        return Stack(
          children: [
            Positioned(
              right: compact ? -12 : -4,
              top: compact ? 5 : 2,
              width: imageWidth,
              bottom: -2,
              child: Image.asset(_image, fit: BoxFit.contain),
            ),
            Positioned(
              left: 18,
              top: 16,
              right: contentRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'common.today'.tr,
                    style: TextStyle(
                      color: context.appMutedText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'wellness.water_progress'.trParams({
                        'current': _number(controller.currentGlasses.value),
                        'target': _number(controller.targetGlasses.value),
                      }),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: context.appText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'wellness.water_added_today'.tr,
                    style: TextStyle(color: context.appMutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: contentRight - 12,
              bottom: 42,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: controller.progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE5EDF2),
                  valueColor: const AlwaysStoppedAnimation<Color>(_blue),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: contentRight - 12,
              bottom: 15,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${controller.percentage}%',
                    style: const TextStyle(
                      color: _blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      _remainingText(),
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.appMutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _benefits(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: _cardDecoration(context),
    child: const Row(
      children: [
        _Benefit(Icons.bolt_rounded, Color(0xFF10B968), 'wellness.more_energy'),
        _Benefit(
          Icons.favorite_rounded,
          Color(0xFFFF496A),
          'wellness.better_health',
        ),
        _Benefit(
          Icons.face_rounded,
          Color(0xFFFFB21C),
          'wellness.healthier_skin',
        ),
        _Benefit(
          Icons.psychology_rounded,
          Color(0xFF7367F0),
          'wellness.better_focus',
        ),
      ],
    ),
  );

  Widget _amountCard(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: _cardDecoration(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wellness.choose_amount'.tr,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: context.appText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'wellness.1_glass_is_about_250_ml'.tr,
          style: TextStyle(fontSize: 12, color: context.appMutedText),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepButton(
              key: const ValueKey('decrease-water'),
              icon: Icons.remove_rounded,
              tooltip: 'wellness.decrease_water'.tr,
              onTap:
                  controller.selectedGlasses.value > 1
                      ? controller.decreaseSelection
                      : null,
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_drink_outlined,
                        color: _blue,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${controller.selectedGlasses.value}',
                        style: TextStyle(
                          fontSize: 27,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: context.appText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedAmountText(),
                    style: TextStyle(fontSize: 12, color: context.appMutedText),
                  ),
                ],
              ),
            ),
            _stepButton(
              key: const ValueKey('increase-water'),
              icon: Icons.add_rounded,
              tooltip: 'wellness.increase_water'.tr,
              onTap:
                  controller.selectedGlasses.value <
                          WaterController.maximumGlassesPerEntry
                      ? controller.increaseSelection
                      : null,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'wellness.quick_select'.tr,
          style: TextStyle(
            color: context.appMutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (var amount = 1; amount <= 4; amount++) ...[
              if (amount > 1) const SizedBox(width: 7),
              Expanded(child: _amountOption(context, amount)),
            ],
          ],
        ),
      ],
    ),
  );

  Widget _amountOption(BuildContext context, int amount) {
    final selected = controller.selectedGlasses.value == amount;
    return InkWell(
      key: ValueKey('water-quick-$amount'),
      onTap: () => controller.selectGlasses(amount),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
        decoration: BoxDecoration(
          color: selected ? _blue.withValues(alpha: 0.09) : context.appSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _blue : context.appBorder),
        ),
        child: Column(
          children: [
            Icon(
              Icons.local_drink_rounded,
              size: 16,
              color: selected ? _blue : context.appMutedText,
            ),
            const SizedBox(height: 2),
            Text(
              '$amount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.appText,
              ),
            ),
            Text(
              '${amount * 250} ml',
              maxLines: 1,
              style: TextStyle(fontSize: 9, color: context.appMutedText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton() => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      key: const ValueKey('add-water-button'),
      onPressed: controller.isSaving.value ? null : controller.addSelectedWater,
      icon:
          controller.isSaving.value
              ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Icon(Icons.water_drop_rounded),
      label: Text(
        controller.isSaving.value
            ? 'wellness.adding'.tr
            : 'wellness.add_to_todays_water'.tr,
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
  );

  Widget _todayTotal(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: _cardDecoration(context),
    child: Row(
      children: [
        _iconBox(Icons.bar_chart_rounded, _blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'wellness.todays_total'.tr,
                style: TextStyle(color: context.appMutedText, fontSize: 12),
              ),
              Text(
                '${(controller.currentGlasses.value * 250).round()} ml',
                style: TextStyle(
                  color: context.appText,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${_number(controller.currentGlasses.value)} ${'common.glasses'.tr}',
                style: TextStyle(color: context.appMutedText, fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            color: _blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'wellness.water_goal_ml'.trParams({
                  'amount': '${(controller.targetGlasses.value * 250).round()}',
                }),
                style: const TextStyle(
                  color: Color(0xFF12628A),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _remainingText(),
                style: TextStyle(color: context.appMutedText, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _tipCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFAEC),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFFFE9AD)),
    ),
    child: Row(
      children: [
        _iconBox(Icons.lightbulb_rounded, const Color(0xFFFFB400)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'wellness.tip'.tr,
                style: TextStyle(
                  color: context.appText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'wellness.water_tip'.tr,
                style: TextStyle(
                  color: context.appMutedText,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _iconBox(IconData icon, Color color) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Icon(icon, color: color),
  );

  Widget _stepButton({
    required Key key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) => IconButton.filledTonal(
    key: key,
    tooltip: tooltip,
    onPressed: onTap,
    icon: Icon(icon),
    color: _blue,
    style: IconButton.styleFrom(
      backgroundColor: _blue.withValues(alpha: 0.11),
      minimumSize: const Size.square(40),
    ),
  );

  Widget _errorCard(BuildContext context, String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.appDangerSurface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline_rounded, color: context.appOnDangerSurface),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message.trOrSelf,
            style: TextStyle(color: context.appOnDangerSurface),
          ),
        ),
        IconButton(
          tooltip: 'common.retry'.tr,
          onPressed: controller.loadWater,
          icon: const Icon(Icons.refresh_rounded),
          color: context.appOnDangerSurface,
        ),
      ],
    ),
  );

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
    color: context.appElevatedSurface.withValues(alpha: 0.94),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: context.appBorder.withValues(alpha: 0.65)),
    boxShadow: context.appTileShadow,
  );

  String _remainingText() => (controller.remainingGlasses == 1
          ? 'wellness.glass_remaining'
          : 'wellness.glasses_remaining')
      .trParams({'count': _number(controller.remainingGlasses)});

  String _selectedAmountText() => (controller.selectedGlasses.value == 1
          ? 'wellness.selected_water_amount_one'
          : 'wellness.selected_water_amount_many')
      .trParams({
        'count': '${controller.selectedGlasses.value}',
        'milliliters': '${controller.selectedMilliliters}',
      });

  String _number(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.color, this.labelKey);

  final IconData icon;
  final Color color;
  final String labelKey;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          labelKey.tr,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            color: context.appText,
            fontSize: 9,
            height: 1.15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
