import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../controllers/home/home_controller.dart';

class TimeGreeting extends GetView<HomeController> {
  const TimeGreeting({super.key});

  ({String title, String subtitle}) _copyFor(DateTime time) {
    if (time.hour < 5) {
      return (title: 'home.good_night', subtitle: 'home.rest_for_tomorrow');
    }
    if (time.hour < 12) {
      return (
        title: 'home.good_morning',
        subtitle: 'home.healthy_choices_today',
      );
    }
    if (time.hour < 17) {
      return (title: 'home.good_afternoon', subtitle: 'home.keep_momentum');
    }
    if (time.hour < 21) {
      return (title: 'home.good_evening', subtitle: 'home.finish_healthy');
    }
    return (title: 'home.good_night', subtitle: 'home.slow_down_rest');
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
      final localizedGreeting = copy.title.tr;
      final greeting = (lastName == null
              ? 'home.greeting'
              : 'home.greeting_named')
          .trParams({
            'greeting': localizedGreeting,
            if (lastName != null) 'name': lastName,
          });

      return Semantics(
        header: true,
        label: '$greeting ${copy.subtitle.tr}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        lastName == null
                            ? 'home.greeting'.trParams({
                              'greeting': localizedGreeting,
                            })
                            : '$localizedGreeting ',
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
              copy.subtitle.tr,
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
