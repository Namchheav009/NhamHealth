import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';

class HomeBottomNavigation
    extends GetView<HomeController> {
  const HomeBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(
          top: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.06,
            ),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround,
          children: [
            _normalItem(
              index: 0,
              icon: Icons.home_rounded,
              label: 'Home',
            ),

            _normalItem(
              index: 1,
              icon:
                  Icons.restaurant_menu_rounded,
              label: 'Meals',
            ),

            _postButton(),

            _normalItem(
              index: 3,
              icon:
                  Icons.people_outline_rounded,
              label: 'Community',
            ),

            _normalItem(
              index: 4,
              icon:
                  Icons.person_outline_rounded,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _normalItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected =
        controller.selectedBottomIndex.value ==
            index;

    return GestureDetector(
      onTap: () =>
          controller.selectBottomMenu(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 55,
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration:
                  const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF53C98A)
                    : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                color: selected
                    ? Colors.white
                    : Colors.black45,
                size: 25,
              ),
            ),

            if (selected) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color:
                      Color(0xFF53C98A),
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _postButton() {
    return GestureDetector(
      onTap: () =>
          controller.selectBottomMenu(2),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    const Color(0xFF00A651),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: 0.08),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFF00A651),
              size: 31,
            ),
          ),

          const SizedBox(height: 2),

          const Text(
            'Post',
            style: TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}