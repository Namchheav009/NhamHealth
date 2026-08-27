abstract class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String accountCreated = '/account-created';
  static const String home = '/home';
  static const String assistant = '/assistant';
  static const String meals = '/meals';
  static const String foodDetail = '/meals/food-detail';
  static const String ingredients = '/meals/food-detail/ingredients';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String changePassword = '/profile/change-password';
  static const String notifications = '/notifications';
  static const String favorites = '/favorites';
  static const String language = '/profile/language';

  static const String wellness = '/wellness';
  static const String calories = '/wellness/calories';
  static const String protein = '/wellness/protein';
  static const String water = '/wellness/water';
  static const String fiber = '/wellness/fiber';
  static const String sugar = '/wellness/sugar';

  static const String aiMealAutoFill = '/wellness/ai-meal-auto-fill';
  static const String aiFood = '/wellness/ai-food';
  static const String foodSourceDetail =
      '/wellness/calories/food-source-detail';
  static const String community = '/community';
  static const String communityPost = '/community/posts/:postId';

  static String communityPostPath(int postId) => '/community/posts/$postId';
}
