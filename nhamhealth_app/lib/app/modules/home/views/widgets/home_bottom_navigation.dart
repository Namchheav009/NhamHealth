import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import 'inner_shadow.dart';

class HomeBottomNavigation extends GetView<HomeController> {
  const HomeBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 64,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFFBFFF2)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: InnerShadow(
                borderRadius: BorderRadius.circular(34),
                shadows: const [
                  BoxShadow(
                    color: Color(0x1800522F),
                    blurRadius: 12,
                    offset: Offset(-2, -1),
                  ),
                  BoxShadow(
                    color: Color(0xCCFFFFFF),
                    blurRadius: 6,
                    offset: Offset(2, 1),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _navigationItem(index: 0, icon: Icons.home_rounded),
                        _navigationItem(
                          index: 1,
                          icon: Icons.restaurant_menu_rounded,
                        ),
                        const SizedBox(width: 48),
                        _navigationItem(
                          index: 3,
                          icon: Icons.people_outline_rounded,
                        ),
                        _navigationItem(
                          index: 4,
                          icon: Icons.person_outline_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Center(child: _postButton()),
          ),
        ],
      ),
    );
  }

  Widget _navigationItem({required int index, required IconData icon}) {
    final selected = controller.selectedBottomIndex.value == index;

    return InkWell(
      onTap: () => controller.selectBottomMenu(index),
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: selected ? 66 : 43,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF49BD7E) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: InnerShadow(
          borderRadius: BorderRadius.circular(25),
          shadows:
              selected
                  ? const [
                    BoxShadow(
                      color: Color(0x2A006834),
                      blurRadius: 7,
                      offset: Offset(-1, -1),
                    ),
                    BoxShadow(
                      color: Color(0x594EED96),
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ]
                  : const [],
          child: Center(
            child: Icon(
              icon,
              color: selected ? Colors.white : const Color(0xFF888A87),
              size: selected ? 27 : 25,
            ),
          ),
        ),
      ),
    );
  }

  Widget _postButton() {
    return InkWell(
      onTap: () => controller.selectBottomMenu(2),
      borderRadius: BorderRadius.circular(25),
      child: SizedBox(
        width: 48,
        height: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF009B49), width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF009B49).withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF009B49),
                size: 30,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Post',
              style: TextStyle(
                fontSize: 9,
                height: 1,
                color: Color(0xFF777777),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
