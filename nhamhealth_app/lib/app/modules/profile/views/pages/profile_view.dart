import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/profile_controller.dart';
import '../widgets/health_stats_card.dart';
import '../widgets/insight_card.dart';
import '../widgets/profile_bottom_navigation.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_post_card.dart';
import '../widgets/progress_card.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 14),

                const ProfileHeader(),

                const SizedBox(height: 8),

                const HealthStatsCard(),

                const SizedBox(height: 8),

                const ProgressCard(),

                const SizedBox(height: 8),

                const InsightCard(),

                const SizedBox(height: 8),

                const ProfilePostCard(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(25, 0, 25, 14),
        child: ProfileBottomNavigation(),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'My Profile',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),

        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.favorite_border_rounded,
            color: Colors.red,
            size: 25,
          ),
        ),

        const SizedBox(width: 2),

        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: controller.openNotifications,
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 25,
                color: Color(0xFF777777),
              ),
            ),

            Positioned(
              right: 3,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF4E50),
                ),
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 2),

        IconButton(
          onPressed: controller.openSettings,
          icon: const Icon(
            Icons.settings_outlined,
            color: Color(0xFF777777),
            size: 25,
          ),
        ),
      ],
    );
  }
}
