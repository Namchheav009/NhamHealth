import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';

class HomeHeader extends GetView<HomeController> {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),

            const SizedBox(width: 8),

            const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'NHAM',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF5364),
                  ),
                ),
                Text(
                  'HEALTH',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF45C66B),
                  ),
                ),
              ],
            ),
          ],
        ),

        const Spacer(),

        IconButton(
          onPressed: controller.openFavorites,
          icon: const Icon(
            Icons.favorite_border_rounded,
            color: Color(0xFFFF3040),
            size: 29,
          ),
        ),

        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed:
                  controller.openNotifications,
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 29,
              ),
            ),

            Positioned(
              right: 5,
              top: 1,
              child: Container(
                width: 17,
                height: 17,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5364),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 6),

        Stack(
          clipBehavior: Clip.none,
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundImage: AssetImage(
                'assets/images/profile.png',
              ),
            ),

            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF00A651),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}