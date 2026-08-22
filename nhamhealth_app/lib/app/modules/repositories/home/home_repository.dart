import '../../models/home/home_dashboard_model.dart';
import '../../models/home/mood_model.dart';
import '../../models/home/recommended_meal_model.dart';
import '../../providers/home/home_provider.dart';

class HomeRepository {
  final HomeProvider provider;

  HomeRepository({
    required this.provider,
  });

  Future<HomeDashboardModel> getHomeDashboard({DateTime? date}) {
    return provider.getHomeDashboard(date: date);
  }

  Future<List<MoodModel>> getMoods() => provider.getMoods();

  Future<List<RecommendedMealModel>> getRecommendedMeals({int? moodId}) =>
      provider.getRecommendedMeals(moodId: moodId);

  Future<List<RecommendedMealModel>> generateRecommendedMeals({
    required int moodId,
    bool refresh = false,
  }) => provider.generateRecommendedMeals(moodId: moodId, refresh: refresh);

  Future<Set<int>> getFavoriteMealIds() => provider.getFavoriteMealIds();

  Future<int> getUnreadNotificationCount() => provider.getUnreadNotificationCount();

  Future<void> setMealFavorite(int mealId, {required bool favorite}) =>
      provider.setMealFavorite(mealId, favorite: favorite);
}
