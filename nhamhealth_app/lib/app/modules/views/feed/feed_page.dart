import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../widgets/nham_app_bar.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/page_skeleton.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../../providers/home/home_provider.dart';
import '../home/widgets/home_bottom_navigation.dart';
import '../../controllers/profile/setting_controller.dart';
import '../profile/setting_view.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const Color green = Color(0xFF18A957);

  int selectedTab = 0;

  bool likedPost1 = false;
  bool likedPost2 = false;

  int likesPost1 = 1000;
  int likesPost2 = 820;

  AuthenticatedUser? _authenticatedUser;
  int _unreadNotificationCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (mounted) setState(() => _isLoading = true);
    await Future.wait<void>([
      _loadTopBar(),
      Future<void>.delayed(const Duration(milliseconds: 350)),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadTopBar() async {
    if (!Get.isRegistered<AuthService>()) return;
    final authService = Get.find<AuthService>();
    final user = await authService.restoreSession();
    var unreadCount = 0;
    try {
      unreadCount =
          await HomeProvider(
            authService: authService,
          ).getUnreadNotificationCount();
    } on Object {
      // Community content remains available when the badge cannot refresh.
    }
    if (!mounted) return;
    setState(() {
      _authenticatedUser = user;
      _unreadNotificationCount = unreadCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.homeBackground,
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(),
                const SizedBox(height: AppSpacing.topBarBottom),
                _tabs(),
                const SizedBox(height: 10),
                Expanded(
                  child:
                      _isLoading
                          ? const SingleChildScrollView(
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.pageHorizontal,
                              4,
                              AppSpacing.pageHorizontal,
                              110,
                            ),
                            child: PageSkeleton.community(),
                          )
                          : RefreshIndicator(
                            color: green,
                            onRefresh: _reload,
                            child:
                                selectedTab == 0
                                    ? _feedList()
                                    : ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                            parent: BouncingScrollPhysics(),
                                          ),
                                      padding: const EdgeInsets.only(
                                        bottom: 110,
                                      ),
                                      children: [
                                        SizedBox(
                                          height: 420,
                                          child: _following(),
                                        ),
                                      ],
                                    ),
                          ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _bottomNav(),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Padding(
      padding: AppSpacing.topBarPagePadding,
      child: NhamAppBar(
        user: _authenticatedUser,
        unreadNotificationCount: _unreadNotificationCount,
        onFavorites: () => Get.toNamed<void>(AppRoutes.favorites),
        onNotifications: () async {
          await Get.toNamed<void>(AppRoutes.notifications);
          await _loadTopBar();
        },
        onProfile:
            () => Get.offNamed<void>(
              AppRoutes.profile,
              arguments: _authenticatedUser,
            ),
        onSettings: _openSettings,
        onLogout: _logout,
      ),
    );
  }

  void _openSettings() {
    Get.to(
      () => const SettingsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SettingsController>(() => SettingsController());
      }),
    );
  }

  Future<void> _logout() async {
    if (Get.isRegistered<AuthService>()) {
      await Get.find<AuthService>().logout();
    }
    Get.offAllNamed<void>(AppRoutes.login);
  }

  // ============================================================
  // FEED / FOLLOWING
  // ============================================================

  Widget _tabs() {
    return Container(
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [_tabButton('Feed', 0), _tabButton('Following', 1)]),
    );
  }

  Widget _tabButton(String title, int index) {
    final bool selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? green : Colors.transparent,
            borderRadius: BorderRadius.circular(23),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FEED
  // ============================================================

  Widget _feedList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        8,
        AppSpacing.pageHorizontal,
        110,
      ),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      children: [
        _createPost(),

        _postCard(
          postIndex: 1,
          title: 'Healthy breakfast idea!',
          description:
              'Avocado toast with poached egg and fresh fruits.\n'
              'Simple, quick and nutritious!',
          image:
              'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=1200',
          tags: const ['#HealthyMeal', '#HighProtein'],
        ),

        const SizedBox(height: 18),

        _postCard(
          postIndex: 2,
          title: 'Fresh fruit for your day!',
          description:
              'Fresh fruits are a simple way to add vitamins and color to your breakfast.',
          image:
              'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=1200',
          tags: const ['#HealthyMeal', '#FreshFruit'],
        ),
      ],
    );
  }

  // ============================================================
  // CREATE POST
  // ============================================================

  Widget _createPost() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFFEAF7EE),
            child: Icon(Icons.person, color: green),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: const Text(
                'What’s on your mind ?',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFB1B1B1),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.image_outlined,
              size: 28,
              color: Color(0xFF6B786F),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POST CARD
  // ============================================================

  Widget _postCard({
    required int postIndex,
    required String title,
    required String description,
    required String image,
    required List<String> tags,
  }) {
    final bool liked = postIndex == 1 ? likedPost1 : likedPost2;

    final int likes = postIndex == 1 ? likesPost1 : likesPost2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F1F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // USER INFORMATION
          // ====================================================
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Color(0xFFEAF7EE),
                child: Icon(Icons.person, color: green),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sophia Martinez',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '2h ago  •  Nutritionist',
                      style: TextStyle(color: Color(0xFF999999), fontSize: 13),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // THREE DOT POPUP MENU
              // ==================================================
              PopupMenuButton<String>(
                tooltip: '',
                color: Colors.white,
                elevation: 8,

                offset: const Offset(-15, 35),

                constraints: const BoxConstraints(minWidth: 200, maxWidth: 215),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.grey,
                  size: 27,
                ),

                onSelected: (value) {
                  if (value == 'about') {
                    _showAboutPost();
                  }

                  if (value == 'report') {
                    _showReportPost();
                  }
                },

                itemBuilder: (context) {
                  return [
                    const PopupMenuItem<String>(
                      value: 'about',
                      height: 50,
                      child: Text(
                        'About this post',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const PopupMenuDivider(height: 1),

                    const PopupMenuItem<String>(
                      value: 'report',
                      height: 50,
                      child: Text(
                        'Report',
                        style: TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ====================================================
          // TITLE
          // ====================================================
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3D3D3D),
            ),
          ),

          const SizedBox(height: 7),

          // ====================================================
          // DESCRIPTION
          // ====================================================
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.35,
              color: Color(0xFF505050),
            ),
          ),

          const SizedBox(height: 12),

          // ====================================================
          // TAGS
          // ====================================================
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F6EA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: green,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
          ),

          const SizedBox(height: 14),

          // ====================================================
          // IMAGE
          // ====================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              image,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,

              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return Container(
                  width: double.infinity,
                  height: 220,
                  alignment: Alignment.center,
                  color: const Color(0xFFF3F3F3),
                  child: const CircularProgressIndicator(color: green),
                );
              },

              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 220,
                  color: const Color(0xFFF3F3F3),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_outlined,
                    size: 52,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ====================================================
          // ACTIONS
          // ====================================================
          Row(
            children: [
              // LIKE
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (postIndex == 1) {
                        likedPost1 = !likedPost1;

                        if (likedPost1) {
                          likesPost1++;
                        } else {
                          likesPost1--;
                        }
                      } else {
                        likedPost2 = !likedPost2;

                        if (likedPost2) {
                          likesPost2++;
                        } else {
                          likesPost2--;
                        }
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          liked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: liked ? Colors.red : Colors.grey,
                          size: 26,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _formatLikes(likes),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              _divider(),

              // COMMENT
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.grey,
                        size: 25,
                      ),
                      SizedBox(width: 7),
                      Text('200', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),

              _divider(),

              // SHARE
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.reply_rounded, color: Colors.grey, size: 26),
                      SizedBox(width: 7),
                      Text('10', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatLikes(int likes) {
    if (likes >= 1000) {
      final double value = likes / 1000;

      if (likes % 1000 == 0) {
        return '${value.toInt()}k';
      }

      return '${value.toStringAsFixed(1)}k';
    }

    return likes.toString();
  }

  Widget _divider() {
    return Container(width: 1, height: 24, color: const Color(0xFFE1E1E1));
  }

  // ============================================================
  // ABOUT POST
  // ============================================================

  void _showAboutPost() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About this post'),
        content: const Text(
          'This is a healthy meal post shared by a nutritionist.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REPORT
  // ============================================================

  void _showReportPost() {
    Get.snackbar(
      'Report',
      'Report post selected',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  // ============================================================
  // FOLLOWING PAGE
  // ============================================================

  Widget _following() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline_rounded, color: green, size: 70),
          SizedBox(height: 12),
          Text(
            'Following',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            'Posts from people you follow',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _bottomNav() {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(25, 0, 25, 14),
      child: AppBottomNavigation(selectedIndex: 3, onSelect: _selectBottomMenu),
    );
  }

  void _selectBottomMenu(int index) {
    switch (index) {
      case 0:
        Get.offNamed<void>(AppRoutes.home);
        return;
      case 1:
        Get.offNamed<void>(AppRoutes.meals);
        return;
      case 2:
        Get.snackbar(
          'Post',
          'Create post',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      case 3:
        break;
      case 4:
        Get.offNamed<void>(AppRoutes.profile, arguments: _authenticatedUser);
        return;
    }
  }
}
