import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/help_support_controller.dart';
import '../../../theme/app_spacing.dart';

class HelpSupportView extends GetView<HelpSupportController> {
  const HelpSupportView({super.key});

  static const Color green = Color(0xFF00A651);
  static const Color darkGreen = Color(0xFF006B38);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFBFB),
        body: Stack(
          children: [
            const _HelpSupportBackground(),

            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),

                        const SizedBox(height: 25),

                        const Text(
                          'Need help? Contact us or find quick answers below.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF8BA797),
                          ),
                        ),

                        const SizedBox(height: 31),

                        const Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Text(
                            'Contact Support',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF151515),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildContactCard(),

                        const SizedBox(height: 26),

                        const Padding(
                          padding: EdgeInsets.only(left: 15),
                          child: Text(
                            'Frequently Asked Questions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF151515),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        _buildFaqList(),
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: controller.goBack,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox(
            width: 30,
            height: 30,
            child: Icon(Icons.arrow_back_rounded, size: 21, color: darkGreen),
          ),
        ),

        const SizedBox(width: 7),

        const Text(
          'Help & Support',
          style: TextStyle(
            fontSize: 21,
            height: 1,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTACT SUPPORT
  // ============================================================

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(14),
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
          _ContactItem(
            icon: Icons.mail_outline_rounded,
            title: 'Email Us',
            subtitle: 'NhamHealth@gmail.com',
            onTap: controller.emailSupport,
          ),

          const Padding(
            padding: EdgeInsets.only(left: 64),
            child: Divider(height: 1, thickness: 0.7, color: Color(0xFFDADADA)),
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

  Widget _buildFaqList() {
    return Obx(
      () => Column(
        children: List.generate(controller.faqs.length, (index) {
          final faq = controller.faqs[index];
          final isExpanded = controller.expandedIndex.value == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FaqItem(
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE5F6EA),
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
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF161616),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1,
                          color: Color(0xFF9398A0),
                        ),
                      ),
                    ],
                  ),
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
  final String question;
  final String answer;
  final bool expanded;
  final VoidCallback onTap;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 62,
              child: Padding(
                padding: const EdgeInsets.only(left: 13, right: 13),
                child: Row(
                  children: [
                    Container(
                      width: 27,
                      height: 27,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE5F6EA),
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
                        question,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171717),
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
                                : const Color(0xFFAAB0B4),
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
                  const Divider(
                    height: 1,
                    thickness: 0.7,
                    color: Color(0xFFD9D9D9),
                  ),

                  const SizedBox(height: 11),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      answer,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF72A080),
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

// ================================================================
// BACKGROUND
// ================================================================

class _HelpSupportBackground extends StatelessWidget {
  const _HelpSupportBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // TOP LEFT PINK
        Positioned(
          left: -130,
          top: -90,
          child: _glow(width: 300, height: 310, color: const Color(0xFFFFE9ED)),
        ),

        // TOP RIGHT GREEN
        Positioned(
          right: -125,
          top: -90,
          child: _glow(width: 320, height: 320, color: const Color(0xFFE9FFD9)),
        ),

        // LEFT / CENTER PINK
        Positioned(
          left: -150,
          bottom: -60,
          child: _glow(width: 330, height: 420, color: const Color(0xFFFFE9ED)),
        ),

        // BOTTOM RIGHT GREEN
        Positioned(
          right: -130,
          bottom: -80,
          child: _glow(width: 330, height: 370, color: const Color(0xFFE9FFDD)),
        ),
      ],
    );
  }

  static Widget _glow({
    required double width,
    required double height,
    required Color color,
  }) {
    return IgnorePointer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width),
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.7),
              color.withValues(alpha: 0.30),
              color.withValues(alpha: 0),
            ],
            stops: const [0, 0.5, 1],
          ),
        ),
      ),
    );
  }
}
