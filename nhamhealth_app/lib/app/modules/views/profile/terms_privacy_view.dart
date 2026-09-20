import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_back_header.dart';
import '../../../widgets/forest_glow_background.dart';
import '../../../theme/app_colors.dart';
import '../../controllers/profile/terms_privacy_controller.dart';
import '../../../theme/app_spacing.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

class TermsPrivacyView extends GetView<TermsPrivacyController> {
  const TermsPrivacyView({super.key});

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
        body: Stack(
          children: [
            const _TermsBackground(),

            SafeArea(
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
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required bool isTablet}) {
    final descStyle = TextStyle(
      fontSize: isTablet ? 14.5 : 13,
      height: 1.35,
      fontWeight: FontWeight.w400,
      color: context.appMutedText,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;

        final termsCard = Obx(
          () => _PolicyCard(
            cardKey: const ValueKey<String>('terms-privacy-terms-card'),
            icon: Icons.policy_outlined,
            title: 'profile.terms_of_service',
            subtitle: 'profile.how_to_use_the_app',
            expanded: controller.termsExpanded.value,
            onTap: controller.toggleTerms,
            isTablet: isTablet,
            children: [
              _PolicyDetail(
                icon: Icons.person_outline_rounded,
                title: 'profile.using_the_app',
                subtitle:
                    'profile.download_the_app_to_perform_health_and_wellness_tracking',
                isTablet: isTablet,
              ),
              _PolicyDetail(
                icon: Icons.verified_user_outlined,
                title: 'profile.account_responsibility',
                subtitle:
                    'profile.keep_your_account_secure_and_your_profile_information_accurate',
                isTablet: isTablet,
              ),
              _PolicyDetail(
                icon: Icons.article_outlined,
                title: 'profile.content_and_behavior',
                subtitle:
                    'profile.do_not_misuse_the_app_or_publish_harmful_content',
                isTablet: isTablet,
              ),
              _PolicyDetail(
                icon: Icons.update_rounded,
                title: 'profile.updates',
                subtitle: 'profile.we_may_update_these_terms_when_needed',
                isTablet: isTablet,
              ),
            ],
          ),
        );

        final privacyCard = Obx(
          () => _PolicyCard(
            cardKey: const ValueKey<String>('terms-privacy-privacy-card'),
            icon: Icons.privacy_tip_outlined,
            title: 'profile.privacy_policy',
            subtitle: 'profile.how_we_protect_your_data',
            expanded: controller.privacyExpanded.value,
            onTap: controller.togglePrivacy,
            isTablet: isTablet,
            children: [
              _PolicyDetail(
                icon: Icons.storage_outlined,
                title: 'profile.data_we_collect',
                subtitle:
                    'profile.we_may_collect_basic_account_and_wellness_information_you_provide',
                isTablet: isTablet,
              ),
              _PolicyDetail(
                icon: Icons.manage_accounts_outlined,
                title: 'profile.how_we_use_data',
                subtitle:
                    'profile.your_data_helps_us_personalize_the_app_and_improve_your_experience',
                isTablet: isTablet,
              ),
              _PolicyDetail(
                icon: Icons.lock_outline_rounded,
                title: 'profile.data_security',
                subtitle:
                    'profile.we_protect_your_information_with_secure_systems_and_privacy_safeguards',
                isTablet: isTablet,
              ),
              _PolicyDetail(
                icon: Icons.admin_panel_settings_outlined,
                title: 'profile.your_control',
                subtitle:
                    'profile.you_can_update_or_request_deletion_of_your_personal_data',
                isTablet: isTablet,
              ),
            ],
          ),
        );

        if (isWide) {
          return Column(
            key: const ValueKey<String>('terms-privacy-tablet-two-column'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${'profile.read_the_main_policies_that_protect'.tr} ${'profile.your_account_and_data'.tr}',
                style: descStyle,
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'profile.terms_of_service'.tr,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.appText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        termsCard,
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'profile.privacy_policy'.tr,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: context.appText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        privacyCard,
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Column(
          key: const ValueKey<String>('terms-privacy-single-column'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'profile.read_the_main_policies_that_protect'.tr,
              style: descStyle,
            ),
            const SizedBox(height: 3),
            Text(
              'profile.your_account_and_data'.tr,
              style: descStyle,
            ),
            SizedBox(height: isTablet ? 26 : 23),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                'profile.main_policies'.tr,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  height: 1,
                  fontWeight: isTablet ? FontWeight.w700 : FontWeight.w600,
                  color: context.appText,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 14 : 12),
            termsCard,
            SizedBox(height: isTablet ? 14 : 9),
            privacyCard,
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return AppBackHeader(
      title: 'profile.terms_privacy'.tr,
      onBack: controller.goBack,
      backButtonKey: const ValueKey<String>('terms-privacy-back-button'),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    this.cardKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onTap,
    required this.children,
    this.isTablet = false,
  });

  final Key? cardKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onTap;
  final List<Widget> children;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final iconBoxSize = isTablet ? 46.0 : 40.0;
    final iconSize = isTablet ? 25.0 : 22.0;

    return AnimatedContainer(
      key: cardKey,
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(isTablet ? 22 : 18),
        border: Border.all(
          color:
              expanded
                  ? context.appColorScheme.primary.withValues(alpha: 0.45)
                  : context.appBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(isTablet ? 18 : 14),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 13,
                vertical: isTablet ? 14 : 11,
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
                    child: Icon(icon, color: TermsPrivacyView.green, size: iconSize),
                  ),
                  SizedBox(width: isTablet ? 16 : 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.trOrSelf,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isTablet ? 6 : 5),
                        Text(
                          subtitle.trOrSelf,
                          style: TextStyle(
                            color: const Color(0xFF7C8589),
                            fontSize: isTablet ? 13 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: isTablet ? 24 : 20,
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
            secondChild: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _PolicyDetail extends StatelessWidget {
  const _PolicyDetail({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isTablet = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 20 : 18,
        0,
        isTablet ? 20 : 18,
        isTablet ? 16 : 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isTablet ? 21 : 18, color: TermsPrivacyView.green),
          SizedBox(width: isTablet ? 15 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.trOrSelf,
                  style: TextStyle(
                    fontSize: isTablet ? 15.5 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isTablet ? 5 : 4),
                Text(
                  subtitle.trOrSelf,
                  style: TextStyle(
                    fontSize: isTablet ? 12.5 : 11,
                    height: 1.35,
                    color: const Color(0xFF718078),
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

class _TermsBackground extends StatelessWidget {
  const _TermsBackground();

  @override
  Widget build(BuildContext context) {
    if (context.appIsDark) {
      return const Positioned.fill(
        child: ForestGlowBackground(force: true, child: SizedBox.expand()),
      );
    }
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
