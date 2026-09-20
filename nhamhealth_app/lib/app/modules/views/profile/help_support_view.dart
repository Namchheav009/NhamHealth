import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../theme/app_colors.dart';
import '../../controllers/profile/help_support_controller.dart';
import '../../../theme/app_spacing.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

class HelpSupportView extends GetView<HelpSupportController> {
  const HelpSupportView({super.key});

  static const Color green = Color(0xFF00A651);

  double _contentMaxWidth(BuildContext context) {
    final isTablet = AppSpacing.isTabletFor(context);
    if (isTablet) return AppSpacing.maxWideContentWidth;
    return AppSpacing.maxContentWidth;
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = AppSpacing.isTabletFor(context);
    final hPad = AppSpacing.pageHorizontalFor(context);
    final maxWidth = _contentMaxWidth(context);

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Pinned header matching setting_view pattern
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    AppSpacing.pageTop,
                    hPad,
                    0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: _buildHeader(),
                    ),
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: _buildBody(context, isTablet: isTablet),
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

  Widget _buildBody(BuildContext context, {required bool isTablet}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;

        final contactSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SupportHero(isTablet: isTablet),
            SizedBox(height: isTablet ? 28 : 26),
            Padding(
              padding: EdgeInsets.only(left: isTablet ? 6 : 15),
              child: Text(
                'profile.contact_support'.tr,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: isTablet ? FontWeight.w700 : FontWeight.w600,
                  color: context.appText,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 14 : 12),
            _buildContactCard(context, isTablet: isTablet),
          ],
        );

        final faqSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: isTablet ? 6 : 15),
              child: Text(
                'profile.frequently_asked_questions'.tr,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: isTablet ? FontWeight.w700 : FontWeight.w600,
                  color: context.appText,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 14 : 14),
            _buildFaqList(context, isTablet: isTablet),
          ],
        );

        if (isWide) {
          return Row(
            key: const ValueKey<String>('help-support-tablet-two-column'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: contactSection),
              const SizedBox(width: 24),
              Expanded(child: faqSection),
            ],
          );
        }

        return Column(
          key: const ValueKey<String>('help-support-single-column'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            contactSection,
            SizedBox(height: isTablet ? 30 : 26),
            faqSection,
          ],
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return AppBackHeader(
      title: 'profile.help_support'.tr,
      onBack: controller.goBack,
      backButtonKey: const ValueKey<String>('help-support-back-button'),
    );
  }

  // ============================================================
  // CONTACT SUPPORT
  // ============================================================

  Widget _buildContactCard(BuildContext context, {required bool isTablet}) {
    return Container(
      width: double.infinity,
      key: const ValueKey<String>('help-contact-card'),
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(isTablet ? 22 : 18),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 21 : 17),
        child: Column(
          children: [
            _ContactItem(
              icon: Icons.mail_outline_rounded,
              title: 'profile.email_us',
              subtitle: 'NhamHealth@gmail.com',
              onTap: controller.emailSupport,
              isTablet: isTablet,
            ),
            Padding(
              padding: EdgeInsets.only(left: isTablet ? 74 : 64),
              child: Divider(
                height: 1,
                thickness: 0.7,
                color: context.appBorder,
              ),
            ),
            _ContactItem(
              icon: Icons.phone_outlined,
              title: 'profile.call_us',
              subtitle: '+855 81814451',
              onTap: controller.callSupport,
              isTablet: isTablet,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FAQ
  // ============================================================

  Widget _buildFaqList(BuildContext context, {required bool isTablet}) {
    return Obx(
      () => Column(
        children: List.generate(controller.faqs.length, (index) {
          final faq = controller.faqs[index];
          final isExpanded = controller.expandedIndex.value == index;

          return Padding(
            padding: EdgeInsets.only(bottom: isTablet ? 10 : 8),
            child: _FaqItem(
              itemKey: ValueKey<String>('help-faq-$index'),
              headerKey: ValueKey<String>('help-faq-header-$index'),
              question: faq['question']!,
              answer: faq['answer']!,
              expanded: isExpanded,
              onTap: () {
                controller.toggleFaq(index);
              },
              isTablet: isTablet,
            ),
          );
        }),
      ),
    );
  }
}

class _SupportHero extends StatelessWidget {
  const _SupportHero({this.isTablet = false});

  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final avatarSize = isTablet ? 56.0 : 48.0;
    final iconSize = isTablet ? 30.0 : 27.0;

    return Container(
      key: const ValueKey<String>('help-support-hero'),
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 22 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.appSoftGreen, context.appSurfaceLow],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        border: Border.all(color: context.appBorder),
        boxShadow: context.appTileShadow,
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: context.appSelectedSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: context.appColorScheme.primary,
              size: iconSize,
            ),
          ),
          SizedBox(width: isTablet ? 18 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'profile.how_can_we_help'.tr,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: isTablet ? 19 : 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Text(
                  'profile.contact_us_or_find_quick_answers_below'.tr,
                  style: TextStyle(
                    color: context.appMutedText,
                    fontSize: isTablet ? 14 : 12.5,
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
}

// ================================================================
// CONTACT ITEM
// ================================================================

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isTablet;

  const _ContactItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final rowHeight = isTablet ? 74.0 : 62.0;
    final iconBoxSize = isTablet ? 46.0 : 39.0;
    final iconSize = isTablet ? 24.0 : 21.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTablet ? 18 : 14),
        child: SizedBox(
          height: rowHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 13),
            child: Row(
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.appSoftGreen,
                  ),
                  child: Icon(icon, size: iconSize, color: HelpSupportView.green),
                ),
                SizedBox(width: isTablet ? 16 : 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.trOrSelf,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          height: 1,
                          fontWeight: FontWeight.w600,
                          color: context.appText,
                        ),
                      ),
                      SizedBox(height: isTablet ? 8 : 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 11,
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
                  size: isTablet ? 24 : 21,
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
  final Key? headerKey;
  final String question;
  final String answer;
  final bool expanded;
  final VoidCallback onTap;
  final bool isTablet;

  const _FaqItem({
    required this.itemKey,
    this.headerKey,
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onTap,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final minHeight = isTablet ? 70.0 : 62.0;
    final iconBoxSize = isTablet ? 34.0 : 27.0;
    final iconSize = isTablet ? 19.0 : 16.0;

    return AnimatedContainer(
      key: itemKey,
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
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
            key: headerKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 13,
                  vertical: isTablet ? 16 : 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.appSoftGreen,
                      ),
                      child: Icon(
                        Icons.help_outline_rounded,
                        color: HelpSupportView.green,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: isTablet ? 15 : 12),
                    Expanded(
                      child: Text(
                        question.trOrSelf,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isTablet ? 15.5 : 14,
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
                        size: isTablet ? 22 : 18,
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
              padding: EdgeInsets.fromLTRB(
                isTablet ? 65 : 54,
                0,
                isTablet ? 20 : 18,
                isTablet ? 16 : 14,
              ),
              child: Column(
                children: [
                  Divider(height: 1, thickness: 0.7, color: context.appBorder),
                  SizedBox(height: isTablet ? 13 : 11),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      answer.trOrSelf,
                      style: TextStyle(
                        fontSize: isTablet ? 13 : 11,
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
