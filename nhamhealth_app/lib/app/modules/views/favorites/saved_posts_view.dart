import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/translations/localized_text.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/favorites/favorites_controller.dart';
import '../../models/recipes/community_recipe.dart';
import 'widgets/favorite_post_card.dart';
import 'widgets/post_filter_sheet.dart';

/// A separate destination for saved community posts, reached from Settings.
class SavedPostsView extends GetView<FavoritesController> {
  const SavedPostsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = AppSpacing.isTabletFor(context) ||
        MediaQuery.sizeOf(context).shortestSide >= AppSpacing.tabletBreakpoint;
    final maxWidth = isTablet
        ? AppSpacing.maxWideContentWidth
        : AppSpacing.maxContentWidth;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: AppBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontalFor(context),
                    isTablet ? AppSpacing.pageTop : 12,
                    AppSpacing.pageHorizontalFor(context),
                    0,
                  ),
                  child: Column(
                    children: [
                      AppBackHeader(
                        title: 'profile.saved_posts'.tr,
                        backButtonKey: const ValueKey('saved-posts-back-button'),
                        onBack: Get.back,
                      ),
                      SizedBox(height: isTablet ? 22 : 20),
                      Expanded(child: _posts(context, isTablet: isTablet)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _posts(BuildContext context, {required bool isTablet}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'favorites.favorite_posts'.trOrSelf,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                onTap: _showPostFilter,
                borderRadius: BorderRadius.circular(18),
                child: _filterButton(context, isTablet: isTablet),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 14 : 10),
          Expanded(
            child: Obx(() {
              final visible = controller.posts.toList()
                ..sort((a, b) {
                  final aDate = a.updatedAt ?? a.publishedAt ?? a.createdAt;
                  final bDate = b.updatedAt ?? b.publishedAt ?? b.createdAt;
                  final comparison = (bDate ?? DateTime(1970))
                      .compareTo(aDate ?? DateTime(1970));
                  return controller.postSort.value == FavoritePostSort.newest
                      ? comparison
                      : -comparison;
                });
              if (controller.isPostsLoading.value && visible.isEmpty) {
                return const PageSkeleton.favorites();
              }
              if (visible.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bookmark_border_rounded,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 10),
                      Text('favorites.no_favorite_posts_yet'.trOrSelf,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.loadPosts,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView.separated(
                      key: const ValueKey('saved-posts-list'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(bottom: isTablet ? 32 : 24),
                      itemCount: visible.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: isTablet ? 16 : 12),
                      itemBuilder: (_, index) => _postCard(visible[index]),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      );

  Widget _filterButton(BuildContext context, {required bool isTablet}) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 14 : 10,
          vertical: isTablet ? 8 : 7,
        ),
        decoration: BoxDecoration(
          color: context.appSoftGreen,
          borderRadius: BorderRadius.circular(isTablet ? 20 : 18),
        ),
        child: Row(
          children: [
            Icon(Icons.tune_rounded,
                color: context.appIsDark
                    ? context.appColorScheme.primary
                    : const Color(0xFF0AA653),
                size: isTablet ? 21 : 19),
            const SizedBox(width: 5),
            Text('common.filter'.tr,
                style: TextStyle(
                  color: context.appIsDark
                      ? context.appColorScheme.primary
                      : const Color(0xFF0AA653),
                  fontSize: isTablet ? 14 : 13,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      );

  Widget _postCard(CommunityRecipe post) => FavoritePostCard(
        post: post,
        onOpen: post.postId == null
            ? null
            : () async {
                await Get.toNamed<void>(AppRoutes.communityPostPath(post.postId!));
                await controller.loadPosts();
              },
        onRemove: () => controller.removePost(post.id),
      );

  void _showPostFilter() => Get.bottomSheet<void>(
        PostFilterSheet(
          initialSort: controller.postSort.value,
          onApply: controller.setPostSort,
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black45,
      );
}
