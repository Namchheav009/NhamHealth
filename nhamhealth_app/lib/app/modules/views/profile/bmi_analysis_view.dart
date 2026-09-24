import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../controllers/profile/profile_controller.dart';
import '../../models/profile/bmi_assessment.dart';

class BmiAnalysisView extends GetView<ProfileController> {
  const BmiAnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontalFor(context) - 8,
                      8,
                      AppSpacing.pageHorizontalFor(context),
                      4,
                    ),
                    child: AppBackHeader(title: 'bmi.title', onBack: Get.back),
                  ),
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
      ),
    );
  }

  Widget _content(BuildContext context) {
    final age = controller.age.value;
    final height = controller.height.value.toDouble();
    final weight = controller.weight.value.toDouble();
    final bmi = BmiAssessment.rounded(heightCm: height, weightKg: weight);
    final isComplete = age > 0 && bmi > 0;

    if (!isComplete) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pagePaddingFor(context),
        children: [
          const SizedBox(height: 54),
          _MissingDataCard(onEdit: controller.editProfile),
        ],
      );
    }

    final guidanceKey = BmiAssessment.guidanceKey(age: age, bmi: bmi);
    final focusKeys = BmiAssessment.nutritionFocusKeys(age: age, bmi: bmi);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: AppSpacing.pagePaddingFor(context),
      children: [
        _ResultCard(bmi: bmi, statusKey: controller.bmiStatus),
        const SizedBox(height: 12),
        _SectionCard(
          titleKey: 'bmi.your_measurements',
          icon: Icons.straighten_rounded,
          child: Column(
            children: [
              _MeasurementRow(
                labelKey: 'bmi.height',
                value: '${_measurementText(height)} cm',
              ),
              _MeasurementRow(
                labelKey: 'bmi.weight',
                value: '${_measurementText(weight)} kg',
              ),
              _MeasurementRow(
                labelKey: 'bmi.age',
                value: '$age ${'bmi.years'.tr}',
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          titleKey: 'bmi.health_guidance',
          icon: Icons.favorite_outline_rounded,
          child: Text(
            guidanceKey.tr,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          titleKey: 'bmi.nutrition_focus',
          icon: Icons.eco_outlined,
          child: Column(
            children: [for (final key in focusKeys) _FocusRow(label: key.tr)],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const ValueKey('bmi-nutrition-summary-button'),
          onPressed: () => Get.toNamed<void>(AppRoutes.wellness),
          icon: const Icon(Icons.insights_outlined),
          label: Text('bmi.view_nutrition_summary'.tr),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: context.appColorScheme.primary,
            foregroundColor: context.appColorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const ValueKey('bmi-meal-planner-button'),
          onPressed: () => Get.offAllNamed<void>(AppRoutes.mealPlanner),
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text('bmi.open_meal_planner'.tr),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: context.appColorScheme.primary,
            side: BorderSide(color: context.appColorScheme.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Notice(text: 'bmi.supporting_context'.tr),
        const SizedBox(height: 8),
        _Notice(text: 'bmi.disclaimer'.tr),
        const SizedBox(height: 20),
      ],
    );
  }
}

String _measurementText(double value) {
  final text = value.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.bmi, required this.statusKey});

  final double bmi;
  final String statusKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('bmi-result-card'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        children: [
          Text(
            'bmi.current_bmi'.tr,
            style: TextStyle(
              color: context.appMutedText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bmi.toStringAsFixed(1),
            style: TextStyle(
              color: context.appText,
              fontSize: 50,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: context.appSoftGreen,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              statusKey.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.titleKey,
    required this.icon,
    required this.child,
  });

  final String titleKey;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appElevatedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryGreen),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  titleKey.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({
    required this.labelKey,
    required this.value,
    this.showDivider = true,
  });

  final String labelKey;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  labelKey.tr,
                  style: TextStyle(color: context.appMutedText, fontSize: 14),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: context.appBorder),
      ],
    );
  }
}

class _FocusRow extends StatelessWidget {
  const _FocusRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.check_circle_rounded,
              color: AppColors.primaryGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.appText,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.info_outline_rounded, size: 16, color: context.appMutedText),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: context.appMutedText,
            fontSize: 11.5,
            height: 1.4,
          ),
        ),
      ),
    ],
  );
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
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_ind_outlined,
            size: 44,
            color: context.appColorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            'bmi.missing_title'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appText,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'bmi.missing_message'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMutedText, height: 1.45),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: Text('bmi.edit_profile'.tr),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: AppSpacing.pagePaddingFor(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined, size: 42, color: context.appMutedText),
          const SizedBox(height: 12),
          Text(
            'profile.unable_to_load_your_profile_pull_down_to_retry'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appMutedText),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: Text('common.retry'.tr)),
        ],
      ),
    ),
  );
}
