import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../models/home/daily_summary_model.dart';
import '../../models/home/home_dashboard_model.dart';
import '../../models/home/mood_model.dart';
import '../../models/home/nutrition_progress_model.dart';
import '../../models/home/recommended_meal_model.dart';

class HomeProvider {
  HomeProvider({
    ProfileRepository? profileRepository,
    AuthService? authService,
    http.Client? client,
  }) : _profileRepository = profileRepository,
       _authService = authService,
       _client = client ?? http.Client();

  final ProfileRepository? _profileRepository;
  final AuthService? _authService;
  final http.Client _client;

  Future<List<MoodModel>> getMoods() async {
    // Keeping this optional makes the provider usable in isolated widget tests.
    final authService = _authService;
    if (authService == null) return const [];

    final token = await authService.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const HomeProviderException(
        'Your session has expired. Please sign in again.',
      );
    }

    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/moods'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HomeProviderException(
        response.statusCode == 401 || response.statusCode == 403
            ? 'Your session has expired. Please sign in again.'
            : 'Unable to load moods (HTTP ${response.statusCode}).',
      );
    }

    try {
      final payload = jsonDecode(response.body);
      if (payload is! List) throw const FormatException();
      return payload
          .map((item) => MoodModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on Object {
      throw const HomeProviderException('The mood response is incomplete.');
    }
  }

  Future<List<RecommendedMealModel>> getRecommendedMeals({int? moodId}) async {
    final authService = _authService;
    if (authService == null) return const [];
    final token = await authService.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const HomeProviderException(
        'Your session has expired. Please sign in again.',
      );
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/ai-recommendations/meals',
    ).replace(queryParameters: moodId == null ? null : {'moodId': '$moodId'});
    final response = await _client
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HomeProviderException(
        response.statusCode == 401 || response.statusCode == 403
            ? 'Your session has expired. Please sign in again.'
            : 'Unable to load recommended meals (HTTP ${response.statusCode}).',
      );
    }

    return _parseRecommendedMeals(response);
  }

  Future<List<RecommendedMealModel>> generateRecommendedMeals({
    required int moodId,
    bool refresh = false,
  }) async {
    final authService = _authService;
    if (authService == null) return const [];
    final token = await authService.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const HomeProviderException(
        'Your session has expired. Please sign in again.',
      );
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/ai-recommendations/meals/generate',
    ).replace(queryParameters: {'moodId': '$moodId', 'refresh': '$refresh'});
    final response = await _client
        .post(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HomeProviderException(
        'Unable to generate meal recommendations (HTTP ${response.statusCode}).',
      );
    }
    return _parseRecommendedMeals(response);
  }

  Future<Set<int>> getFavoriteMealIds() async {
    final response = await _favoriteRequest('GET');
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.map((item) => ((item as Map)['id'] as num).toInt()).toSet();
  }

  Future<int> getUnreadNotificationCount() async {
    final authService = _authService;
    if (authService == null) return 0;
    final token = await authService.readAccessToken();
    if (token == null || token.isEmpty) return 0;
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/unread-count'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HomeProviderException('Unable to load notification count.');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return (payload['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> setMealFavorite(int mealId, {required bool favorite}) async {
    await _favoriteRequest(favorite ? 'POST' : 'DELETE', mealId: mealId);
  }

  Future<http.Response> _favoriteRequest(String method, {int? mealId}) async {
    final authService = _authService;
    if (authService == null) {
      throw const HomeProviderException('Authentication is required.');
    }
    final token = await authService.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const HomeProviderException('Your session has expired.');
    }
    final suffix = mealId == null ? '' : '/$mealId';
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/favorites/meals$suffix');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response =
        method == 'POST'
            ? await _client.post(uri, headers: headers)
            : method == 'DELETE'
            ? await _client.delete(uri, headers: headers)
            : await _client.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HomeProviderException(
        'Unable to update favorite (HTTP ${response.statusCode}).',
      );
    }
    return response;
  }

  List<RecommendedMealModel> _parseRecommendedMeals(http.Response response) {
    try {
      final payload = jsonDecode(response.body);
      if (payload is! List) throw const FormatException();
      return payload
          .map((item) {
            final data = Map<String, dynamic>.from(item as Map);
            final image = data['imageUrl'] as String?;
            if (image != null && image.startsWith('/')) {
              data['imageUrl'] = '${ApiConfig.baseUrl}$image';
            }
            return RecommendedMealModel.fromJson(data);
          })
          .toList(growable: false);
    } on Object {
      throw const HomeProviderException(
        'The recommended meals response is incomplete.',
      );
    }
  }

  Future<HomeDashboardModel> getHomeDashboard({DateTime? date}) async {
    final profile = await _profileRepository?.getDashboard(date: date);

    final calories = profile?.calories;
    final protein = profile?.protein;
    final fat = profile?.fat;
    final water = profile?.water;
    final fiber = profile?.fiber;
    final sugar = profile?.sugar;
    final displayName = profile?.fullName?.trim();

    return HomeDashboardModel(
      userName:
          displayName?.isNotEmpty == true
              ? displayName!.split(RegExp(r'\s+')).first
              : profile?.email.split('@').first ?? 'Friend',
      dailySummary: DailySummaryModel(
        calories: NutritionProgressModel(
          title: 'Calories',
          value: _number(calories?.current ?? 0),
          target: _number(calories?.goal ?? 2000),
          progress: _progress(calories?.current, calories?.goal),
          unit: 'kcal',
        ),
        protein: NutritionProgressModel(
          title: 'Protein',
          value: _number(protein?.current ?? 0),
          target: _number(protein?.goal ?? 120),
          progress: _progress(protein?.current, protein?.goal),
          unit: 'g',
        ),
        fat: NutritionProgressModel(
          title: 'Fat',
          value: _number(fat?.current ?? 0),
          target: _number(fat?.goal ?? 78),
          progress: _progress(fat?.current, fat?.goal),
          unit: 'g',
        ),
        water: NutritionProgressModel(
          title: 'Water',
          value: _number(water?.current ?? 0),
          target: _number(water?.goal ?? 8),
          progress: _progress(water?.current, water?.goal),
          unit: 'glasses',
        ),
        fiber: NutritionProgressModel(
          title: 'Fiber',
          value: _number(fiber?.current ?? 0),
          target: _number(fiber?.goal ?? 25),
          progress: _progress(fiber?.current, fiber?.goal),
          unit: 'g',
        ),
        sugar: NutritionProgressModel(
          title: 'Sugar',
          value: _number(sugar?.current ?? 0),
          target: _number(sugar?.goal ?? 50),
          progress: _progress(sugar?.current, sugar?.goal),
          unit: 'g',
        ),
      ),
      recommendedMeals: const [],
    );
  }

  static String _number(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);

  static double _progress(double? current, double? goal) {
    if (goal == null || goal <= 0) return 0;
    return ((current ?? 0) / goal).clamp(0.0, 1.0).toDouble();
  }
}

class HomeProviderException implements Exception {
  const HomeProviderException(this.message);

  final String message;

  @override
  String toString() => message;
}
