import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../../theme/app_colors.dart';
import '../../../bindings/assistant/assistant_binding.dart';
import '../../../controllers/home/home_controller.dart';
import '../../assistant/assistant_view.dart';

class HomeChatbotButton extends GetView<HomeController> {
  const HomeChatbotButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open AI Assistant'.tr,
      child: Tooltip(
        message: 'Chat with AI Assistant'.tr,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey<String>('home-ai-food-analyze'),
            onTap:
                () => Get.to<void>(
                  () => const AssistantView(),
                  binding: AssistantBinding(),
                  transition: Transition.rightToLeft,
                ),
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Transform.scale(
                        scale: 1.25,
                        child: Lottie.asset(
                          'assets/animations/chatbot.json',
                          fit: BoxFit.contain,
                          repeat: true,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF39D879),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x4439D879), blurRadius: 5),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33075E2D),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
