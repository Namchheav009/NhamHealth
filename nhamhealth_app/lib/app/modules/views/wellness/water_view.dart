import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/wellness/water_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/app_back_header.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

class WaterView extends GetView<WaterController> {
  const WaterView({super.key});

  static const Color _waterBlue = Color(0xFF35AEEB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        lightDecoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF8FF), Colors.white, Color(0xFFF1FFF7)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: _waterBlue,
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
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Padding(
                        padding: AppSpacing.pagePaddingFor(context),
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
  }

  Widget _header(BuildContext context) {
    final horizontal = AppSpacing.pageHorizontalFor(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 4),
          child: Row(
            children: [
              AppBackButton(onPressed: Get.back),
              Expanded(
                child: Text(
                  'common.water'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.appText,
                  ),
                ),
              ),
              const SizedBox(width: AppBackButton.layoutSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (controller.isLoading.value && controller.currentGlasses.value == 0) {
      return const Padding(
        padding: EdgeInsets.only(top: 120),
        child: Center(child: CircularProgressIndicator(color: _waterBlue)),
      );
    }

    return Column(
      children: [
        _progressCard(context),
        const SizedBox(height: 16),
        _amountCard(context),
        if (controller.errorMessage.value != null) ...[
          const SizedBox(height: 12),
          _errorCard(context, controller.errorMessage.value!),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey<String>('add-water-button'),
            onPressed:
                controller.isSaving.value ? null : controller.addSelectedWater,
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
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _waterBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressCard(BuildContext context) {
    final current = _number(controller.currentGlasses.value);
    final target = _number(controller.targetGlasses.value);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: _waterBlue.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              size: 42,
              color: _waterBlue,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'wellness.water_progress'.trParams({
              'current': current,
              'target': target,
            }),
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'wellness.water_added_today'.tr,
            style: TextStyle(fontSize: 13, color: context.appMutedText),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: controller.progress,
              minHeight: 11,
              backgroundColor: context.appMutedSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(_waterBlue),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${controller.percentage}%',
                style: const TextStyle(
                  color: _waterBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                (controller.remainingGlasses == 1
                        ? 'wellness.glass_remaining'
                        : 'wellness.glasses_remaining')
                    .trParams({'count': _number(controller.remainingGlasses)}),
                style: TextStyle(fontSize: 12, color: context.appMutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'wellness.choose_amount'.tr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.appText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'wellness.1_glass_is_about_250_ml'.tr,
            style: TextStyle(fontSize: 12, color: context.appMutedText),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepButton(
                key: const ValueKey<String>('decrease-water'),
                icon: Icons.remove_rounded,
                onTap: controller.decreaseSelection,
              ),
              SizedBox(
                width: 150,
                child: Column(
                  children: [
                    Text(
                      '${controller.selectedGlasses.value}',
                      style: TextStyle(
                        fontSize: 38,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: context.appText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      (controller.selectedGlasses.value == 1
                              ? 'wellness.selected_water_amount_one'
                              : 'wellness.selected_water_amount_many')
                          .trParams({
                            'count': '${controller.selectedGlasses.value}',
                            'milliliters': '${controller.selectedMilliliters}',
                          }),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appMutedText,
                      ),
                    ),
                  ],
                ),
              ),
              _stepButton(
                key: const ValueKey<String>('increase-water'),
                icon: Icons.add_rounded,
                onTap: controller.increaseSelection,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [1, 2, 3, 4]
                .map(
                  (amount) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: amount == 1 ? 0 : 7),
                      child: ChoiceChip(
                        label: Text('+$amount'),
                        selected: controller.selectedGlasses.value == amount,
                        onSelected: (_) => controller.selectGlasses(amount),
                        selectedColor: _waterBlue.withValues(alpha: 0.18),
                        side: BorderSide(
                          color:
                              controller.selectedGlasses.value == amount
                                  ? _waterBlue
                                  : context.appBorder,
                        ),
                        labelStyle: TextStyle(
                          color: context.appText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _stepButton({
    required Key key,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return IconButton.filledTonal(
      key: key,
      onPressed: onTap,
      icon: Icon(icon),
      color: _waterBlue,
      style: IconButton.styleFrom(
        backgroundColor: _waterBlue.withValues(alpha: 0.12),
        minimumSize: const Size.square(46),
      ),
    );
  }

  Widget _errorCard(BuildContext context, String message) {
    return Container(
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
  }

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
    color: context.appSurfaceLow,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: context.appBorder.withValues(alpha: 0.7)),
    boxShadow: context.appCardShadow,
  );

  String _number(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
}
