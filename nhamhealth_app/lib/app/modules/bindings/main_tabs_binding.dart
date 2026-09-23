import 'package:get/get.dart';

import 'community/community_binding.dart';
import 'home/home_binding.dart';
import 'meals/meal_binding.dart';
import 'planner/meal_planner_binding.dart';

class MainTabsBinding extends Bindings {
  @override
  void dependencies() {
    HomeBinding().dependencies();
    MealBinding().dependencies();
    MealPlannerBinding().dependencies();
    CommunityBinding().dependencies();
  }
}
