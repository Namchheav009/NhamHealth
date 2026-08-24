import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../widgets/app_back_header.dart';

import '../../controllers/profile/terms_privacy_controller.dart';
import '../../../theme/app_spacing.dart';

class TermsPrivacyView extends GetView<TermsPrivacyController> {
  const TermsPrivacyView({super.key});

  static const Color green = Color(0xFF00A651);

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBFB),
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
                          'Read the main policies that protect'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF7C8589),
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          'your account and data.'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF7C8589),
                          ),
                        ),

                        const SizedBox(height: 23),

                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            'Main Policies'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF151515),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Obx(
                          () => _PolicyCard(
                            icon: Icons.policy_outlined,
                            title: 'Terms of Service',
                            subtitle: 'How to use the app',
                            expanded: controller.termsExpanded.value,
                            onTap: controller.toggleTerms,
                            children: const [
                              _PolicyDetail(
                                icon: Icons.person_outline_rounded,
                                title: 'Using the app',
                                subtitle:
                                    'Download the app to perform health and wellness tracking.',
                              ),
                              _PolicyDetail(
                                icon: Icons.verified_user_outlined,
                                title: 'Account Responsibility',
                                subtitle:
                                    'Keep your account secure and your profile information accurate.',
                              ),
                              _PolicyDetail(
                                icon: Icons.article_outlined,
                                title: 'Content & Behavior',
                                subtitle:
                                    'Do not misuse the app or publish harmful content.',
                              ),
                              _PolicyDetail(
                                icon: Icons.update_rounded,
                                title: 'Updates',
                                subtitle:
                                    'We may update these terms when needed.',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 9),

                        Obx(
                          () => _PolicyCard(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            subtitle: 'How we protect your data',
                            expanded: controller.privacyExpanded.value,
                            onTap: controller.togglePrivacy,
                            children: const [
                              _PolicyDetail(
                                icon: Icons.storage_outlined,
                                title: 'Data We Collect',
                                subtitle:
                                    'We may collect basic account and wellness information you provide.',
                              ),
                              _PolicyDetail(
                                icon: Icons.manage_accounts_outlined,
                                title: 'How We Use Data',
                                subtitle:
                                    'Your data helps us personalize the app and improve your experience.',
                              ),
                              _PolicyDetail(
                                icon: Icons.lock_outline_rounded,
                                title: 'Data Security',
                                subtitle:
                                    'We protect your information with secure systems and privacy safeguards.',
                              ),
                              _PolicyDetail(
                                icon: Icons.admin_panel_settings_outlined,
                                title: 'Your Control',
                                subtitle:
                                    'You can update or request deletion of your personal data.',
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
      title: 'Terms & Privacy',
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
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              expanded ? const Color(0xFFBFE4CB) : const Color(0xFFE3EBE6),
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE5F6EA),
                    ),
                    child: Icon(icon, color: TermsPrivacyView.green, size: 22),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle.tr,
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
                  title.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.tr,
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
