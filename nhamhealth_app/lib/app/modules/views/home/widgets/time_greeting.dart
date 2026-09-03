import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/home/home_controller.dart';

class TimeGreeting extends GetView<HomeController> {
  const TimeGreeting({super.key});

  ({String title, String subtitle}) _copyFor(DateTime time) {
    if (time.hour < 5) {
      return (
        title: 'Good night',
        subtitle: 'Rest well and recharge for tomorrow.',
      );
    }
    if (time.hour < 12) {
      return (
        title: 'Good morning',
        subtitle: "Let's make healthy choices today.",
      );
    }
    if (time.hour < 17) {
      return (
        title: 'Good afternoon',
        subtitle: 'Keep your healthy momentum going.',
      );
    }
    if (time.hour < 21) {
      return (
        title: 'Good evening',
        subtitle: 'Finish your day with a healthy choice.',
      );
    }
    return (
      title: 'Good night',
      subtitle: 'Slow down, recharge, and rest well.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copyFor(DateTime.now());

    return Obx(() {
      final displayName =
          controller.authenticatedUser.value?.displayName.trim();
      final lastName =
          displayName == null || displayName.isEmpty
              ? null
              : displayName.split(RegExp(r'\s+')).last;
      final greeting =
          lastName == null ? '${copy.title}!' : '${copy.title}, $lastName!';

      return Semantics(
        header: true,
        label: '$greeting ${copy.subtitle}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        lastName == null
                            ? '${copy.title}!'
                            : '${copy.title}, ',
                  ),
                  if (lastName != null)
                    TextSpan(
                      text: '$lastName!',
                      style: const TextStyle(color: AppColors.primaryGreen),
                    ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appText,
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              copy.subtitle,
              style: TextStyle(
                color: context.appMutedText,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    });
  }
}
