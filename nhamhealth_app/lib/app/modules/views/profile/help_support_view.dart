import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../theme/app_colors.dart';

import '../../controllers/profile/help_support_controller.dart';
import '../../../theme/app_spacing.dart';

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

                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Text(
                          'Contact Support'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.appText,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildContactCard(context),

                      const SizedBox(height: 26),

                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Text(
                          'Frequently Asked Questions'.tr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.appText,
                          ),
                        ),
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return AppBackHeader(title: 'Help & Support', onBack: controller.goBack);
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
            title: 'Email Us',
            subtitle: 'NhamHealth@gmail.com',
            onTap: controller.emailSupport,
          ),

          Padding(
            padding: const EdgeInsets.only(left: 64),
            child: Divider(height: 1, thickness: 0.7, color: context.appBorder),
          ),

          _ContactItem(
            icon: Icons.phone_outlined,
            title: 'Call Us',
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
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [context.appSoftGreen, context.appSurfaceLow],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.appBorder),
      boxShadow: context.appTileShadow,
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.appSelectedSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.support_agent_rounded,
            color: context.appColorScheme.primary,
            size: 27,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How can we help?'.tr,
                style: TextStyle(
                  color: context.appText,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Contact us or find quick answers below.'.tr,
                style: TextStyle(
                  color: context.appMutedText,
                  fontSize: 12.5,
                  height: 1.4,
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
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 62,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.appSoftGreen,
                  ),
                  child: Icon(icon, size: 21, color: HelpSupportView.green),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.tr,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w600,
                          color: context.appText,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1,
                          color: context.appMutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.appMutedText,
                  size: 21,
                ),
              ],
            ),
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
                  ? context.appColorScheme.primary.withValues(alpha: 0.45)
                  : context.appBorder,
        ),
        boxShadow: context.appTileShadow,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 62),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.appSoftGreen,
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        color: HelpSupportView.green,
                        size: 16,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        question.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: context.appText,
                        ),
                      ),
                    ),

                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
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
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,

            firstChild: const SizedBox.shrink(),

            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(54, 0, 18, 14),
              child: Column(
                children: [
                  Divider(height: 1, thickness: 0.7, color: context.appBorder),

                  const SizedBox(height: 11),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      answer.tr,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                        color: context.appMutedText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
