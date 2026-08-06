import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';

class HomeHeader extends GetView<HomeController> {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Image.asset(
            'assets/icons/logo.png',
            width: 52,
            height: 52,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NHAM',
                style: TextStyle(
                  height: 1.05,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFF5364),
                ),
              ),
              Text(
                'HEALTH',
                style: TextStyle(
                  height: 1.05,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF45C66B),
                ),
              ),
            ],
          ),
          const Spacer(),
          _HeaderButton(
            onTap: controller.openFavorites,
            child: const Icon(
              Icons.favorite_border_rounded,
              color: Color(0xFFFF2437),
              size: 28,
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _HeaderButton(
                onTap: controller.openNotifications,
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF333333),
                  size: 27,
                ),
              ),
              Positioned(
                right: 3,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5364),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage(
                  'assets/images/homepage/profile.jpg',
                ),
              ),
              Positioned(
                right: -1,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A651),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 23,
      child: SizedBox(width: 42, height: 46, child: Center(child: child)),
    );
  }
}
