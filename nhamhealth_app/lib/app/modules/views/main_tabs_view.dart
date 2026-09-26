import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/main_tab_scope.dart';
import '../controllers/home/home_controller.dart';
import '../controllers/planner/meal_planner_controller.dart';
import '../controllers/planner/weight_loss_projection_controller.dart';
import 'community/community_page.dart';
import 'home/home_view.dart';
import 'meals/meal_view.dart';
import 'planner/meal_planner_view.dart';

/// Keeps visited main pages mounted when the bottom navigation changes tabs.
class MainTabsView extends StatefulWidget {
  const MainTabsView({super.key, required this.initialIndex, this.tabPages})
    : assert(initialIndex >= 0 && initialIndex < 4),
      assert(tabPages == null || tabPages.length == 4);

  final int initialIndex;
  final List<Widget>? tabPages;

  @override
  State<MainTabsView> createState() => _MainTabsViewState();
}

class _MainTabsViewState extends State<MainTabsView> {
  late int _selectedIndex = widget.initialIndex;
  late final Set<int> _visited = {_selectedIndex};

  void _selectTab(int index) {
    if (index < 0 || index >= 4 || index == _selectedIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedIndex = index;
      _visited.add(index);
    });
    if (index == 0 && Get.isRegistered<HomeController>()) {
      unawaited(Get.find<HomeController>().loadDashboard(showLoading: false));
    } else if (index == 2) {
      if (Get.isRegistered<MealPlannerController>()) {
        final planner = Get.find<MealPlannerController>();
        unawaited(planner.loadDailyNutrition(planner.selectedDate));
      }
      if (Get.isRegistered<WeightLossProjectionController>()) {
        unawaited(
          Get.find<WeightLossProjectionController>().loadForecast(
            forceRefresh: true,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages =
        widget.tabPages ??
        const <Widget>[
          HomeView(),
          MealView(),
          MealPlannerView(),
          CommunityPage(),
        ];
    return MainTabScope(
      selectTab: _selectTab,
      child: SizedBox.expand(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            for (var index = 0; index < pages.length; index++)
              TickerMode(
                enabled: index == _selectedIndex,
                child:
                    _visited.contains(index)
                        ? pages[index]
                        : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
