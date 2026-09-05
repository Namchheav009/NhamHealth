import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_back_header.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/page_skeleton.dart';
import '../../controllers/favorites/favorites_controller.dart';
import '../../models/favorites/favorite_food.dart';
import '../../models/meals/meal_model.dart';
import 'widgets/favorite_food_card.dart';
import 'widgets/favorite_post_card.dart';
import 'widgets/favorites_tab_switcher.dart';
import 'widgets/food_filter_sheet.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    body: AppBackground(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontalFor(context),
                8,
                AppSpacing.pageHorizontalFor(context),
                0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppBackButton(onPressed: Get.back),
                      const SizedBox(width: AppBackButton.headerGap),
                      Text(
                        'favorites'.tr,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => FavoritesTabSwitcher(
                      selected: controller.selectedTab.value,
                      onChanged: controller.selectTab,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Expanded(
                    child: Obx(
                      () =>
                          controller.selectedTab.value == FavoritesTab.foods
                              ? _foods(context)
                              : _posts(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _foods(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
        context,
        'Favorite foods',
        Icons.filter_list_rounded,
        onTap: _showFoodFilter,
      ),
      const SizedBox(height: 10),
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
                      ? 'No favorite foods yet'
                      : 'No foods match these filters',
            );
          }
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = switch (constraints.maxWidth) {
                  < 330 => 2,
                  < AppSpacing.tabletBreakpoint => 3,
                  _ => 4,
                };
                final cardWidth =
                    (constraints.maxWidth - ((columns - 1) * 8)) / columns;
                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 10,
                    mainAxisExtent: cardWidth * 1.48,
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

  Widget _posts(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader(
        context,
        'Favorite Posts',
        Icons.calendar_today_outlined,
        postMenu: true,
      ),
      const SizedBox(height: 10),
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
            return const _EmptyFavorites(message: 'No favorite posts yet');
          }
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder:
                  (_, index) => FavoritePostCard(
                    post: visible[index],
                    onOpen:
                        visible[index].postId == null
                            ? null
                            : () => _openPost(visible[index].postId!),
                    onRemove: () => controller.removePost(visible[index].id),
                  ),
            ),
          );
        }),
      ),
    ],
  );

  Widget _sectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    VoidCallback? onTap,
    bool postMenu = false,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          title.tr,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                  'Newest',
                  Icons.access_time_rounded,
                ),
                _sortMenuItem(
                  context,
                  FavoritePostSort.oldest,
                  'Oldest',
                  Icons.schedule_rounded,
                ),
              ],
          child: _filterButton(context, icon),
        )
      else
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: _filterButton(context, icon),
        ),
    ],
  );

  PopupMenuItem<FavoritePostSort> _sortMenuItem(
    BuildContext context,
    FavoritePostSort value,
    String label,
    IconData icon,
  ) {
    final selected = controller.postSort.value == value;
    final primary =
        context.appIsDark
            ? context.appColorScheme.primary
            : const Color(0xFF0AA653);
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: selected ? primary : Colors.grey, size: 21),
          const SizedBox(width: 10),
          Text(
            label.tr,
            style: TextStyle(
              color: selected ? primary : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(BuildContext context, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: context.appSoftGreen,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color:
              context.appIsDark
                  ? context.appColorScheme.primary
                  : const Color(0xFF0AA653),
          size: 19,
        ),
        const SizedBox(width: 5),
        Text(
          'Filter'.tr,
          style: TextStyle(
            color:
                context.appIsDark
                    ? context.appColorScheme.primary
                    : const Color(0xFF0AA653),
            fontWeight: FontWeight.w600,
          ),
        ),
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
        Text(message.tr, style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );
}
