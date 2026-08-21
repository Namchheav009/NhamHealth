import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const Color green = Color(0xFF18A957);
  static const Color bg = Color(0xFFFFFAFA);

  int selectedTab = 0;

  bool likedPost1 = false;
  bool likedPost2 = false;

  int likesPost1 = 1000;
  int likesPost2 = 820;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),

            const SizedBox(height: 14),

            _tabs(),

            const SizedBox(height: 10),

            Expanded(
              child: selectedTab == 0
                  ? _feedList()
                  : _following(),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _bottomNav(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        0,
      ),
      child: Row(
        children: [
          // LOGO
          Image.asset(
            'assets/icons/logo.png',
            width: 54,
            height: 54,
            fit: BoxFit.contain,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: green,
                  size: 30,
                ),
              );
            },
          ),

          const SizedBox(width: 10),

          // NHAM HEALTH
          const Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'NHAM ',
                    style: TextStyle(
                      color: Color(0xFFFF647B),
                    ),
                  ),
                  TextSpan(
                    text: 'HEALTH',
                    style: TextStyle(
                      color: Color(0xFF49B36F),
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // SEARCH
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.search_rounded,
              size: 29,
              color: Color(0xFF73777E),
            ),
          ),

          const SizedBox(width: 15),

          // NOTIFICATION
          // Red number 2 removed
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 29,
              color: Color(0xFF73777E),
            ),
          ),

          const SizedBox(width: 15),

          // AI / ASSISTANT ICON
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.face_retouching_natural_outlined,
              size: 29,
              color: Color(0xFF73777E),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEED / FOLLOWING
  // ============================================================

  Widget _tabs() {
    return Container(
      height: 62,
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(31),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _tabButton(
            'Feed',
            0,
          ),
          _tabButton(
            'Following',
            1,
          ),
        ],
      ),
    );
  }

  Widget _tabButton(
    String title,
    int index,
  ) {
    final bool selected =
        selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? green
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(26),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: selected
                  ? Colors.white
                  : Colors.black87,
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
        20,
        8,
        20,
        20,
      ),
      physics:
          const BouncingScrollPhysics(),
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
          tags: const [
            '#HealthyMeal',
            '#HighProtein',
          ],
        ),

        const SizedBox(height: 18),

        _postCard(
          postIndex: 2,
          title: 'Fresh fruit for your day!',
          description:
              'Fresh fruits are a simple way to add vitamins and color to your breakfast.',
          image:
              'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=1200',
          tags: const [
            '#HealthyMeal',
            '#FreshFruit',
          ],
        ),
      ],
    );
  }

  // ============================================================
  // CREATE POST
  // ============================================================

  Widget _createPost() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 4,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor:
                Color(0xFFEAF7EE),
            child: Icon(
              Icons.person,
              color: green,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: const Text(
                'What’s on your mind ?',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      Color(0xFFB1B1B1),
                  fontWeight:
                      FontWeight.w500,
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
    final bool liked =
        postIndex == 1
            ? likedPost1
            : likedPost2;

    final int likes =
        postIndex == 1
            ? likesPost1
            : likesPost2;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFF1F1F1),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ====================================================
          // USER INFORMATION
          // ====================================================

          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor:
                    Color(0xFFEAF7EE),
                child: Icon(
                  Icons.person,
                  color: green,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sophia Martinez',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '2h ago  •  Nutritionist',
                      style: TextStyle(
                        color:
                            Color(0xFF999999),
                        fontSize: 13,
                      ),
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

                offset:
                    const Offset(-15, 35),

                constraints:
                    const BoxConstraints(
                  minWidth: 200,
                  maxWidth: 215,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20),
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
                    const PopupMenuItem<
                        String>(
                      value: 'about',
                      height: 50,
                      child: Text(
                        'About this post',
                        style: TextStyle(
                          color:
                              Color(0xFF667085),
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),

                    const PopupMenuDivider(
                      height: 1,
                    ),

                    const PopupMenuItem<
                        String>(
                      value: 'report',
                      height: 50,
                      child: Text(
                        'Report',
                        style: TextStyle(
                          color:
                              Color(0xFF667085),
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w500,
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
            children: tags.map(
              (tag) {
                return Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFE3F6EA,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(18),
                  ),
                  child: Text(
                    tag,
                    style:
                        const TextStyle(
                      color: green,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                );
              },
            ).toList(),
          ),

          const SizedBox(height: 14),

          // ====================================================
          // IMAGE
          // ====================================================

          ClipRRect(
            borderRadius:
                BorderRadius.circular(15),
            child: Image.network(
              image,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,

              loadingBuilder: (
                context,
                child,
                loadingProgress,
              ) {
                if (loadingProgress ==
                    null) {
                  return child;
                }

                return Container(
                  width: double.infinity,
                  height: 220,
                  alignment:
                      Alignment.center,
                  color: const Color(
                    0xFFF3F3F3,
                  ),
                  child:
                      const CircularProgressIndicator(
                    color: green,
                  ),
                );
              },

              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return Container(
                  width: double.infinity,
                  height: 220,
                  color: const Color(
                    0xFFF3F3F3,
                  ),
                  alignment:
                      Alignment.center,
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
                      if (postIndex ==
                          1) {
                        likedPost1 =
                            !likedPost1;

                        if (likedPost1) {
                          likesPost1++;
                        } else {
                          likesPost1--;
                        }
                      } else {
                        likedPost2 =
                            !likedPost2;

                        if (likedPost2) {
                          likesPost2++;
                        } else {
                          likesPost2--;
                        }
                      }
                    });
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          liked
                              ? Icons
                                  .favorite_rounded
                              : Icons
                                  .favorite_border_rounded,
                          color: liked
                              ? Colors.red
                              : Colors.grey,
                          size: 26,
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        Text(
                          _formatLikes(
                            likes,
                          ),
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
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
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Icon(
                        Icons
                            .chat_bubble_outline_rounded,
                        color:
                            Colors.grey,
                        size: 25,
                      ),
                      SizedBox(width: 7),
                      Text(
                        '200',
                        style: TextStyle(
                          color:
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              _divider(),

              // SHARE
              const Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      Icon(
                        Icons.reply_rounded,
                        color:
                            Colors.grey,
                        size: 26,
                      ),
                      SizedBox(width: 7),
                      Text(
                        '10',
                        style: TextStyle(
                          color:
                              Colors.grey,
                        ),
                      ),
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
      final double value =
          likes / 1000;

      if (likes % 1000 == 0) {
        return '${value.toInt()}k';
      }

      return '${value.toStringAsFixed(1)}k';
    }

    return likes.toString();
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 24,
      color: const Color(0xFFE1E1E1),
    );
  }

  // ============================================================
  // ABOUT POST
  // ============================================================

  void _showAboutPost() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(20),
        ),
        title: const Text(
          'About this post',
        ),
        content: const Text(
          'This is a healthy meal post shared by a nutritionist.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text(
              'Close',
            ),
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
      snackPosition:
          SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  // ============================================================
  // FOLLOWING PAGE
  // ============================================================

  Widget _following() {
    return const Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline_rounded,
            color: green,
            size: 70,
          ),
          SizedBox(height: 12),
          Text(
            'Following',
            style: TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Posts from people you follow',
            style: TextStyle(
              color: Colors.grey,
            ),
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
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          18,
          6,
          18,
          12,
        ),
        child: SizedBox(
          height: 88,
          child: Stack(
            clipBehavior: Clip.none,
            alignment:
                Alignment.bottomCenter,
            children: [
              Container(
                height: 68,
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius
                          .circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(
                        0.06,
                      ),
                      blurRadius: 14,
                      offset:
                          const Offset(
                        0,
                        5,
                      ),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceAround,
                  children: [
                    _navItem(
                      Icons.home_rounded,
                      false,
                      () {
                        Get.offNamed(
                          AppRoutes.home,
                        );
                      },
                    ),

                    _navItem(
                      Icons
                          .restaurant_menu_rounded,
                      false,
                      () {
                        Get.offNamed(
                          AppRoutes.meals,
                        );
                      },
                    ),

                    const SizedBox(
                      width: 54,
                    ),

                    _navItem(
                      Icons.people_rounded,
                      true,
                      () {},
                    ),

                    _navItem(
                      Icons
                          .person_outline_rounded,
                      false,
                      () {
                        Get.offNamed(
                          AppRoutes.profile,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // CENTER POST BUTTON
              Positioned(
                top: -3,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.snackbar(
                          'Post',
                          'Create post',
                          snackPosition:
                              SnackPosition
                                  .BOTTOM,
                        );
                      },
                      child: Container(
                        width: 66,
                        height: 66,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.white,
                          shape:
                              BoxShape.circle,
                          border:
                              Border.all(
                            color: green,
                            width: 2,
                          ),
                        ),
                        child:
                            const Icon(
                          Icons.add_rounded,
                          color: green,
                          size: 47,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    const Text(
                      'Post',
                      style: TextStyle(
                        color:
                            Color(
                          0xFF808080,
                        ),
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(26),
      child: Container(
        width: selected ? 70 : 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(
                  0xFF47BC76,
                )
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(26),
        ),
        child: Icon(
          icon,
          size: 31,
          color: selected
              ? Colors.white
              : const Color(
                  0xFF8A8A8A,
                ),
        ),
      ),
    );
  }
}