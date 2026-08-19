import 'package:get/get.dart';

import '../models/favorite_food.dart';
import '../models/favorite_post.dart';

enum FavoritesTab { foods, posts }

enum FavoritePostSort { newest, oldest }

class FavoritesController extends GetxController {
  final selectedTab = FavoritesTab.foods.obs;
  final hiddenFoodIds = <int>{}.obs;
  final hiddenPostIds = <int>{}.obs;
  final selectedFoodCategory = 'All'.obs;
  final postSort = FavoritePostSort.newest.obs;

  static const foodCategories = <String>[
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Drink',
  ];

  final foods = const <FavoriteFood>[
    FavoriteFood(id: 1, name: 'Grilled Chicken\nPower Bowl', image: 'assets/images/meals/healthy_salad.jpg', calories: 520, rating: 4.8, category: 'Lunch'),
    FavoriteFood(id: 2, name: 'Fresh Garden\nSalad Bowl', image: 'assets/images/homepage/healthy_salad.png', calories: 360, rating: 4.9, category: 'Breakfast'),
    FavoriteFood(id: 3, name: 'Protein Veggie\nPower Bowl', image: 'assets/images/meals/healthy_salad.jpg', calories: 440, rating: 4.7, category: 'Dinner'),
    FavoriteFood(id: 4, name: 'Chicken Avocado\nBowl', image: 'assets/images/homepage/healthy_salad.png', calories: 490, rating: 4.8, category: 'Lunch'),
    FavoriteFood(id: 5, name: 'Balanced Lunch\nPower Bowl', image: 'assets/images/meals/healthy_salad.jpg', calories: 510, rating: 4.9, category: 'Lunch'),
    FavoriteFood(id: 6, name: 'Green Protein\nSalad', image: 'assets/images/homepage/healthy_salad.png', calories: 390, rating: 4.7, category: 'Snack'),
    FavoriteFood(id: 7, name: 'Lean Chicken\nSalad', image: 'assets/images/meals/healthy_salad.jpg', calories: 470, rating: 4.8, category: 'Dinner'),
    FavoriteFood(id: 8, name: 'Garden Fresh\nPower Bowl', image: 'assets/images/homepage/healthy_salad.png', calories: 350, rating: 4.6, category: 'Breakfast'),
    FavoriteFood(id: 9, name: 'Healthy Chicken\nBowl', image: 'assets/images/meals/healthy_salad.jpg', calories: 500, rating: 4.9, category: 'Dinner'),
  ];

  final posts = const <FavoritePost>[
    FavoritePost(id: 1, author: 'Sophia Martinez', role: 'Nutritionist', timeAgo: '2h ago', title: 'Healthy breakfast idea!', body: 'Avocado toast with poached egg and fresh fruits.\nSimple, quick and nutritious!', image: 'assets/images/meals/healthy_salad.jpg', likes: 1000, comments: 200, shares: 10),
    FavoritePost(id: 2, author: 'Sophia Martinez', role: 'Nutritionist', timeAgo: '6h ago', title: 'A colorful snack for today!', body: 'Fresh fruit is an easy way to add more fiber and vitamins to your day.', image: 'assets/images/homepage/healthy_salad.png', likes: 824, comments: 96, shares: 18),
  ];

  void selectTab(FavoritesTab tab) => selectedTab.value = tab;
  void applyFoodCategory(String category) => selectedFoodCategory.value = category;
  void setPostSort(FavoritePostSort sort) => postSort.value = sort;
  void removeFood(int id) => hiddenFoodIds.add(id);
  void removePost(int id) => hiddenPostIds.add(id);
}
