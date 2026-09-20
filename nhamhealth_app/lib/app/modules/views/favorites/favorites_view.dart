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
import '../../models/favorites/favorite_food.dart';
import '../../models/meals/meal_model.dart';
import '../../models/recipes/community_recipe.dart';
import 'widgets/favorite_food_card.dart';
import 'widgets/favorite_post_card.dart';
import 'widgets/favorites_tab_switcher.dart';
import 'widgets/food_filter_sheet.dart';
import 'widgets/post_filter_sheet.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  double _contentMaxWidth(BuildContext context) {
    final isTablet =
        AppSpacing.isTabletFor(context) ||
        MediaQuery.sizeOf(context).shortestSide >= AppSpacing.tabletBreakpoint;
    if (isTablet) return AppSpacing.maxWideContentWidth;
    return AppSpacing.maxContentWidth;
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final isTablet =
        AppSpacing.isTabletFor(context) ||
        MediaQuery.sizeOf(context).shortestSide >= AppSpacing.tabletBreakpoint;
    final maxWidth = _contentMaxWidth(context);
    final topPadding = isTablet ? AppSpacing.pageTop : 12.0;

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.25,
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: AppBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                ),
                child: Padding(
                  key: ValueKey<String>(
                    isTablet
                        ? (isLandscape
                            ? 'favorites-tablet-landscape'
                            : 'favorites-tablet-portrait')
                        : 'favorites-mobile',
                  ),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontalFor(context),
                    topPadding,
                    AppSpacing.pageHorizontalFor(context),
                    0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          AppBackButton(
                            buttonKey: const ValueKey<String>(
                              'favorites-back-button',
                            ),
                            onPressed: Get.back,
                          ),
                          const SizedBox(width: AppBackButton.headerGap),
                          Text(
                            'common.favorites'.tr,
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTablet ? 18 : 14),
                      Obx(
                        () => FavoritesTabSwitcher(
                          selected: controller.selectedTab.value,
                          onChanged: controller.selectTab,
                        ),
                      ),
                      SizedBox(height: isTablet ? 22 : 20),
                      Expanded(
                        child: Obx(
                          () =>
                              controller.selectedTab.value == FavoritesTab.foods
                                  ? _foods(context, isTablet: isTablet)
                                  : _posts(context, isTablet: isTablet),
                        ),
                      ),
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

  Widget _foods(BuildContext context, {required bool isTablet}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
        context,
        'favorites.favorite_foods',
        Icons.filter_list_rounded,
        onTap: _showFoodFilter,
        isTablet: isTablet,
      ),
      SizedBox(height: isTablet ? 14 : 10),
      Expanded(
        child: Obx(() {
          final categories = controller.selectedFoodCategories;
          if (controller.isLoading.value && controller.foods.isEmpty) {
            return const PageSkeleton.favorites();
          }
          final visible =
              controller.foods
                  .where(
                    (food) =>
                        categories.isEmpty ||
                        categories.contains(food.category),
                  )
                  .toList();
          if (visible.isEmpty) {
            return _EmptyFavorites(
              message:
                  categories.isEmpty
                      ? 'common.no_favorite_foods_yet'
                      : 'favorites.no_foods_match_these_filters',
            );
          }
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = switch (constraints.maxWidth) {
                  < 560 => 2,
                  < 860 => 3,
                  _ => 4,
                };
                final spacing = isTablet ? 14.0 : 10.0;
                final cardWidth =
                    (constraints.maxWidth - ((columns - 1) * spacing)) /
                    columns;
                final extent =
                    isTablet
                        ? (cardWidth * 1.25).clamp(240.0, 330.0)
                        : cardWidth * 1.38;
                return GridView.builder(
                  key: ValueKey<String>('favorites-food-grid-$columns'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: isTablet ? 32 : 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    mainAxisExtent: extent,
                  ),
                  itemCount: visible.length,
                  itemBuilder:
                      (_, index) => FavoriteFoodCard(
                        food: visible[index],
                        onOpen: () => _openFood(visible[index]),
                        onRemove:
                            () => controller.removeFood(visible[index].id),
                      ),
                );
              },
            ),
          );
        }),
      ),
    ],
  );

  Widget _posts(BuildContext context, {required bool isTablet}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
        context,
        'favorites.favorite_posts',
        Icons.calendar_today_outlined,
        postMenu: true,
        onTap: _showPostFilter,
        isTablet: isTablet,
      ),
      SizedBox(height: isTablet ? 14 : 10),
      Expanded(
        child: Obx(() {
          final visible =
              controller.posts.toList()..sort((a, b) {
                final aDate = a.updatedAt ?? a.publishedAt ?? a.createdAt;
                final bDate = b.updatedAt ?? b.publishedAt ?? b.createdAt;
                final comparison = (bDate ?? DateTime(1970)).compareTo(
                  aDate ?? DateTime(1970),
                );
                return controller.postSort.value == FavoritePostSort.newest
                    ? comparison
                    : -comparison;
              });
          if (controller.isPostsLoading.value && visible.isEmpty) {
            return const PageSkeleton.favorites();
          }
          if (visible.isEmpty) {
            return const _EmptyFavorites(
              message: 'favorites.no_favorite_posts_yet',
            );
          }
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView.separated(
                  key: const ValueKey<String>('favorites-posts-list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: isTablet ? 32 : 24),
                  itemCount: visible.length,
                  separatorBuilder:
                      (_, _) => SizedBox(height: isTablet ? 16 : 12),
                  itemBuilder: (_, index) => _postCard(visible[index]),
                ),
              ),
            ),
          );
        }),
      ),
    ],
  );

  Widget _postCard(CommunityRecipe post) => FavoritePostCard(
    post: post,
    onOpen: post.postId == null ? null : () => _openPost(post.postId!),
    onRemove: () => controller.removePost(post.id),
  );

  Widget _sectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    bool postMenu = false,
    VoidCallback? onTap,
    bool isTablet = false,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          title.trOrSelf,
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (postMenu)
        PopupMenuButton<FavoritePostSort>(
          initialValue: controller.postSort.value,
          onSelected: controller.setPostSort,
          color: context.appElevatedSurface,
          elevation: 6,
          offset: const Offset(0, 8),
          constraints: const BoxConstraints(minWidth: 142),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          itemBuilder:
              (_) => [
                _sortMenuItem(
                  context,
                  FavoritePostSort.newest,
                  'favorites.newest',
                  Icons.access_time_rounded,
                ),
                _sortMenuItem(
                  context,
                  FavoritePostSort.oldest,
                  'favorites.oldest',
                  Icons.schedule_rounded,
                ),
              ],
          child: _filterButton(context, icon, isTablet: isTablet),
        )
      else
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: _filterButton(context, icon, isTablet: isTablet),
        ),
    ],
  );

  Widget _filterButton(
    BuildContext context,
    IconData icon, {
    bool isTablet = false,
  }) => Container(
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
        Icon(
          icon,
          color:
              context.appIsDark
                  ? context.appColorScheme.primary
                  : const Color(0xFF0AA653),
          size: isTablet ? 21 : 19,
        ),
        const SizedBox(width: 5),
        Text(
          'common.filter'.tr,
          style: TextStyle(
            color:
                context.appIsDark
                    ? context.appColorScheme.primary
                    : const Color(0xFF0AA653),
            fontSize: isTablet ? 14 : 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  PopupMenuItem<FavoritePostSort> _sortMenuItem(
    BuildContext context,
    FavoritePostSort value,
    String label,
    IconData icon,
  ) => PopupMenuItem<FavoritePostSort>(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 19, color: context.appColorScheme.onSurface),
        const SizedBox(width: 10),
        Text(label.trOrSelf),
      ],
    ),
  );

  void _showFoodFilter() {
    Get.bottomSheet<void>(
      FoodFilterSheet(
        categories: controller.foodCategories.toList(growable: false),
        initialCategories: controller.selectedFoodCategories.toSet(),
        onApply: controller.applyFoodCategories,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
    );
  }

  void _showPostFilter() {
    Get.bottomSheet<void>(
      PostFilterSheet(
        initialSort: controller.postSort.value,
        onApply: controller.setPostSort,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
    );
  }

  Future<void> _openFood(FavoriteFood food) async {
    await Get.toNamed<void>(
      AppRoutes.foodDetail,
      arguments: MealModel(
        id: food.id,
        name: food.name,
        calories: food.calories,
        image: food.image,
        category: food.category,
        categoryId: 0,
        isFavorite: true,
      ),
    );
    await controller.loadFoods();
  }

  Future<void> _openPost(int postId) async {
    await Get.toNamed<void>(AppRoutes.communityPostPath(postId));
    await controller.loadPosts();
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.favorite_border_rounded, size: 48, color: Colors.grey),
        const SizedBox(height: 10),
        Text(message.trOrSelf, style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );
}
