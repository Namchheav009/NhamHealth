import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../controllers/profile/help_support_controller.dart';

class HelpSupportView extends GetView<HelpSupportController> {
  const HelpSupportView({super.key});

  static const Color green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: AppBackground(
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: AppSpacing.pagePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 25),

                      _SupportHero(),

                      const SizedBox(height: 26),

                      _buildSectionHeader(context, 'profile.contact_support'),

                      const SizedBox(height: 12),

                      _buildContactCard(context),

                      const SizedBox(height: 26),

                      _buildSectionHeader(
                        context,
                        'profile.frequently_asked_questions',
                      ),

                      const SizedBox(height: 14),

                      _buildFaqList(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 16,
          decoration: BoxDecoration(
            color: green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.tr,
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: context.appText,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return AppBackHeader(
      title: 'profile.help_support'.tr,
      onBack: controller.goBack,
    );
  }

  // ============================================================
  // CONTACT SUPPORT
  // ============================================================

  Widget _buildContactCard(BuildContext context) {
    return Container(
      width: double.infinity,
      key: const ValueKey<String>('help-contact-card'),
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: Column(
        children: [
          _ContactItem(
            icon: Icons.mail_outline_rounded,
            title: 'profile.email_us',
            subtitle: 'NhamHealth@gmail.com',
            onTap: controller.emailSupport,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 70),
            child: Divider(height: 1, thickness: 0.7, color: context.appBorder),
          ),

          _ContactItem(
            icon: Icons.phone_outlined,
            title: 'profile.call_us',
            subtitle: '+855 81814451',
            onTap: controller.callSupport,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FAQ
  // ============================================================

  Widget _buildFaqList(BuildContext context) {
    return Obx(
      () => Column(
        children: List.generate(controller.faqs.length, (index) {
          final faq = controller.faqs[index];
          final isExpanded = controller.expandedIndex.value == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FaqItem(
              itemKey: ValueKey<String>('help-faq-$index'),
              question: faq['question']!,
              answer: faq['answer']!,
              expanded: isExpanded,
              onTap: () {
                controller.toggleFaq(index);
              },
            ),
          );
        }),
      ),
    );
  }
}

class _SupportHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('help-support-hero'),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          context.appSoftGreen.withValues(alpha: 0.88),
          context.appSurfaceLow,
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: HelpSupportView.green.withValues(alpha: 0.22),
        width: 1.2,
      ),
      boxShadow: context.appTileShadow,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: Lottie.asset(
            'assets/animations/Customer Support.json',
            fit: BoxFit.contain,
            repeat: true,
            animate:
                !Get.testMode &&
                !WidgetsBinding.instance.runtimeType.toString().contains(
                  'Test',
                ),
            errorBuilder:
                (context, error, stackTrace) => Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: context.appSoftGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: HelpSupportView.green,
                    size: 36,
                  ),
                ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'profile.how_can_we_help'.tr,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'profile.contact_us_or_find_quick_answers_below'.tr,
                style: TextStyle(
                  color: context.appMutedText,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ================================================================
// CONTACT ITEM
// ================================================================

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.appSoftGreen,
                ),
                child: Icon(icon, size: 21, color: HelpSupportView.green),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.trOrSelf,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: context.appText,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.appMutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.appMutedText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// FAQ ITEM
// ================================================================

class _FaqItem extends StatelessWidget {
  final Key itemKey;
  final String question;
  final String answer;
  final bool expanded;
  final VoidCallback onTap;

  const _FaqItem({
    required this.itemKey,
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: itemKey,
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              expanded
                  ? HelpSupportView.green.withValues(alpha: 0.5)
                  : context.appBorder,
          width: expanded ? 1.2 : 1,
        ),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.appSoftGreen,
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: HelpSupportView.green,
                      size: 18,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      question.trOrSelf,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        color: context.appText,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color:
                          expanded
                              ? HelpSupportView.green
                              : context.appMutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,

            firstChild: const SizedBox.shrink(),

            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.appSoftGreen.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  answer.trOrSelf,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: context.appText.withValues(alpha: 0.88),
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
