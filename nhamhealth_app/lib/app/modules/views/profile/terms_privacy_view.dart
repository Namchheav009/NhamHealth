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

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: Stack(
          children: [
            const _TermsBackground(),

            SafeArea(
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

                        const SizedBox(height: 27),

                        Text(
                          'profile.read_the_main_policies_that_protect'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: FontWeight.w400,
                            color: context.appMutedText,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          'profile.your_account_and_data'.tr,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: FontWeight.w400,
                            color: context.appMutedText,
                          ),
                        ),

                        const SizedBox(height: 23),

                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            'profile.main_policies'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              color: context.appText,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Obx(
                          () => _PolicyCard(
                            icon: Icons.policy_outlined,
                            title: 'profile.terms_of_service',
                            subtitle: 'profile.how_to_use_the_app',
                            expanded: controller.termsExpanded.value,
                            onTap: controller.toggleTerms,
                            children: const [
                              _PolicyDetail(
                                icon: Icons.person_outline_rounded,
                                title: 'profile.using_the_app',
                                subtitle:
                                    'profile.download_the_app_to_perform_health_and_wellness_tracking',
                              ),
                              _PolicyDetail(
                                icon: Icons.verified_user_outlined,
                                title: 'profile.account_responsibility',
                                subtitle:
                                    'profile.keep_your_account_secure_and_your_profile_information_accurate',
                              ),
                              _PolicyDetail(
                                icon: Icons.article_outlined,
                                title: 'profile.content_and_behavior',
                                subtitle:
                                    'profile.do_not_misuse_the_app_or_publish_harmful_content',
                              ),
                              _PolicyDetail(
                                icon: Icons.update_rounded,
                                title: 'profile.updates',
                                subtitle:
                                    'profile.we_may_update_these_terms_when_needed',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 9),

                        Obx(
                          () => _PolicyCard(
                            icon: Icons.privacy_tip_outlined,
                            title: 'profile.privacy_policy',
                            subtitle: 'profile.how_we_protect_your_data',
                            expanded: controller.privacyExpanded.value,
                            onTap: controller.togglePrivacy,
                            children: const [
                              _PolicyDetail(
                                icon: Icons.storage_outlined,
                                title: 'profile.data_we_collect',
                                subtitle:
                                    'profile.we_may_collect_basic_account_and_wellness_information_you_provide',
                              ),
                              _PolicyDetail(
                                icon: Icons.manage_accounts_outlined,
                                title: 'profile.how_we_use_data',
                                subtitle:
                                    'profile.your_data_helps_us_personalize_the_app_and_improve_your_experience',
                              ),
                              _PolicyDetail(
                                icon: Icons.lock_outline_rounded,
                                title: 'profile.data_security',
                                subtitle:
                                    'profile.we_protect_your_information_with_secure_systems_and_privacy_safeguards',
                              ),
                              _PolicyDetail(
                                icon: Icons.admin_panel_settings_outlined,
                                title: 'profile.your_control',
                                subtitle:
                                    'profile.you_can_update_or_request_deletion_of_your_personal_data',
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppBackHeader(
      title: 'profile.terms_privacy'.tr,
      onBack: controller.goBack,
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onTap,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: context.appElevatedSurface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
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
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.appSoftGreen,
                    ),
                    child: Icon(icon, color: TermsPrivacyView.green, size: 22),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.trOrSelf,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle.trOrSelf,
                          style: const TextStyle(
                            color: Color(0xFF7C8589),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: TermsPrivacyView.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.trOrSelf,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.trOrSelf,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: Color(0xFF718078),
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
    return Positioned.fill(
      child: const DecoratedBox(
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
