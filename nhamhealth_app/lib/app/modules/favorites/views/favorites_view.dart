import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/favorites_controller.dart';
import 'widgets/favorite_food_card.dart';
import 'widgets/favorite_post_card.dart';
import 'widgets/favorites_tab_switcher.dart';
import 'widgets/food_filter_sheet.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: Container(
      decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/background/bg.png'), fit: BoxFit.cover)),
      child: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(children: [
          Row(children: [IconButton(onPressed: Get.back, icon: const Icon(Icons.arrow_back, color: Color(0xFF087A42))), const SizedBox(width: 5), const Text('Favorites', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))]),
          const SizedBox(height: 8),
          Obx(() => FavoritesTabSwitcher(selected: controller.selectedTab.value, onChanged: controller.selectTab)),
          const SizedBox(height: 17),
          Expanded(child: Obx(() => controller.selectedTab.value == FavoritesTab.foods ? _foods() : _posts())),
        ]),
      )))),
    ),
  );

  Widget _foods() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionHeader('Favorite foods', Icons.filter_list_rounded, onTap: _showFoodFilter),
    const SizedBox(height: 10),
    Expanded(child: Obx(() {
      final category = controller.selectedFoodCategory.value;
      if (controller.isLoading.value && controller.foods.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      final visible = controller.foods.where((food) => category == 'All' || food.category == category).toList();
      if (visible.isEmpty) return _EmptyFavorites(message: category == 'All' ? 'No favorite foods yet' : 'No foods match this filter');
      return LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth < 330 ? 2 : 3;
        final cardWidth = (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
            mainAxisExtent: cardWidth * 1.48,
          ),
          itemCount: visible.length,
          itemBuilder: (_, index) => FavoriteFoodCard(food: visible[index], onRemove: () => controller.removeFood(visible[index].id)),
        );
      });
    })),
  ]);

  Widget _posts() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _sectionHeader('Favorite Posts', Icons.calendar_today_outlined, postMenu: true),
    const SizedBox(height: 10),
    Expanded(child: Obx(() {
      final visible = controller.posts.where((post) => !controller.hiddenPostIds.contains(post.id)).toList()
        ..sort((a, b) => controller.postSort.value == FavoritePostSort.newest ? a.id.compareTo(b.id) : b.id.compareTo(a.id));
      if (visible.isEmpty) return const _EmptyFavorites(message: 'No favorite posts yet');
      return ListView.separated(padding: const EdgeInsets.only(bottom: 24), itemCount: visible.length, separatorBuilder: (_, _) => const SizedBox(height: 12), itemBuilder: (_, index) => FavoritePostCard(post: visible[index], onRemove: () => controller.removePost(visible[index].id)));
    })),
  ]);

  Widget _sectionHeader(String title, IconData icon, {VoidCallback? onTap, bool postMenu = false}) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
    if (postMenu)
      PopupMenuButton<FavoritePostSort>(
        initialValue: controller.postSort.value,
        onSelected: controller.setPostSort,
        color: Colors.white,
        elevation: 6,
        offset: const Offset(0, 8),
        constraints: const BoxConstraints(minWidth: 142),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        itemBuilder: (_) => [
          _sortMenuItem(FavoritePostSort.newest, 'Newest', Icons.access_time_rounded),
          _sortMenuItem(FavoritePostSort.oldest, 'Oldest', Icons.schedule_rounded),
        ],
        child: _filterButton(icon),
      )
    else
      InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: _filterButton(icon)),
  ]);

  PopupMenuItem<FavoritePostSort> _sortMenuItem(FavoritePostSort value, String label, IconData icon) {
    final selected = controller.postSort.value == value;
    return PopupMenuItem(value: value, child: Row(children: [
      Icon(icon, color: selected ? const Color(0xFF0AA653) : Colors.grey, size: 21),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(color: selected ? const Color(0xFF0AA653) : Colors.grey, fontWeight: FontWeight.w600)),
    ]));
  }

  Widget _filterButton(IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: const Color(0xFFEAF8EF), borderRadius: BorderRadius.circular(18)),
    child: Row(children: [Icon(icon, color: const Color(0xFF0AA653), size: 19), const SizedBox(width: 5), const Text('Filter', style: TextStyle(color: Color(0xFF0AA653), fontWeight: FontWeight.w600))]),
  );

  void _showFoodFilter() {
    Get.bottomSheet<void>(
      FoodFilterSheet(
        categories: controller.foodCategories.toList(growable: false),
        initialCategory: controller.selectedFoodCategory.value,
        onApply: controller.applyFoodCategory,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.message}); final String message;
  @override Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.favorite_border_rounded, size: 48, color: Colors.grey), const SizedBox(height: 10), Text(message, style: const TextStyle(color: Colors.grey))]));
}
