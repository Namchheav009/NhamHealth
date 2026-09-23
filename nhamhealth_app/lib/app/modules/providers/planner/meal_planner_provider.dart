import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/planner/ai_autofill_response_model.dart';
import '../../models/planner/ai_meal_recommendation_model.dart';
import '../../models/planner/meal_plan.dart';
import '../../models/planner/weight_loss_forecast_model.dart';

class MealPlannerProvider {
  MealPlannerProvider({required AuthService authService, http.Client? client})
    : _authService = authService,
      _client = client ?? http.Client();
  final AuthService _authService;
  final http.Client _client;
  String get _lang => Get.locale?.languageCode ?? 'en';

  Future<WeightLossForecast> getWeightLossForecast({
    int days = 28,
    DateTime? startDate,
    MealPlannerHealthGoal goal = MealPlannerHealthGoal.loseWeight,
  }) async {
    final query = <String, String>{
      'days': days.toString(),
      'lang': _lang,
      'goal': goal.apiValue,
    };
    if (startDate != null) {
      query['startDate'] = _date(startDate);
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/meal-planner/weight-loss-forecast',
    ).replace(queryParameters: query);
    final headers = await _headers();
    final response = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const MealPlannerProviderException(
        'Unable to load weight loss forecast.',
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const MealPlannerProviderException(
        'Weight loss forecast response is incomplete.',
      );
    }
    return WeightLossForecast.fromJson(payload);
  }

  Future<AiAutoFillPlanResponse> aiAutoFillPlan({
    required DateTime startDate,
    int days = 7,
    MealPlannerHealthGoal goal = MealPlannerHealthGoal.loseWeight,
    int targetTimeframeDays = 28,
    bool fillEmptyOnly = true,
    bool includeBeverages = true,
    MealPlannerDietaryPreferences preferences =
        const MealPlannerDietaryPreferences(),
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/meal-planner/ai-autofill',
    ).replace(queryParameters: {'lang': _lang});
    final headers = await _headers();
    headers['Content-Type'] = 'application/json';
    final body = {
      'startDate': _date(startDate),
      'days': days,
      'goal': goal.apiValue,
      'targetTimeframeDays': targetTimeframeDays,
      'fillEmptyOnly': fillEmptyOnly,
      'includeBeverages': includeBeverages,
      ...preferences.toJson(),
    };
    final response = await _client
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MealPlannerProviderException(
        'Unable to auto-fill meal plan with AI.',
        statusCode: response.statusCode,
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const MealPlannerProviderException(
        'AI auto-fill response is incomplete.',
      );
    }
    return AiAutoFillPlanResponse.fromJson(payload);
  }

  Future<AiMealRecommendationResult> recommendMeal({
    required DateTime date,
    required MealPlanSlot slot,
    MealPlannerHealthGoal goal = MealPlannerHealthGoal.loseWeight,
    int? currentMealId,
    String? actionType,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/meal-planner/recommend-meal',
    ).replace(queryParameters: {'lang': _lang});
    final headers = await _headers();
    headers['Content-Type'] = 'application/json';
    final body = {
      'date': _date(date),
      'slot': slot.name.toUpperCase(),
      'goal': goal.apiValue,
      'currentMealId': currentMealId,
      'actionType': actionType ?? (currentMealId != null ? 'SWAP' : 'ADD'),
    };
    final response = await _client
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 25));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MealPlannerProviderException(
        'Unable to get AI meal recommendation.',
        statusCode: response.statusCode,
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map) {
      throw const MealPlannerProviderException(
        'AI meal recommendation response is incomplete.',
      );
    }
    return AiMealRecommendationResult.fromJson(
      Map<String, dynamic>.from(payload),
      defaultSlot: slot,
    );
  }

  Future<List<PlannedMeal>> getRecommendations({
    DateTime? date,
    String? dayOfWeek,
    MealPlannerHealthGoal goal = MealPlannerHealthGoal.loseWeight,
  }) {
    final query = <String, String>{'lang': _lang, 'goal': goal.apiValue};
    if (dayOfWeek != null && dayOfWeek.isNotEmpty) {
      query['dayOfWeek'] = dayOfWeek;
    } else if (date != null) {
      query['date'] = _date(date);
    }
    return _getList(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/meal-planner/recommendations',
      ).replace(queryParameters: query),
    );
  }

  Future<List<PlannedMeal>> getRange({
    required DateTime start,
    DateTime? end,
    int? days,
  }) {
    final query = <String, String>{'startDate': _date(start), 'lang': _lang};
    if (end != null) {
      query['endDate'] = _date(end);
    }
    if (days != null && days > 0) {
      query['days'] = days.toString();
    }
    return _getList(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/meal-plans',
      ).replace(queryParameters: query),
    );
  }

  Future<List<PlannedMeal>> getDay(DateTime date) => _getList(
    Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/meal-plans/day',
    ).replace(queryParameters: {'date': _date(date), 'lang': _lang}),
  );

  Future<List<PlannedMeal>> getWeek(DateTime start) => _getList(
    Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/meal-plans/week',
    ).replace(queryParameters: {'startDate': _date(start), 'lang': _lang}),
  );
  Future<PlannedMeal> saveMeal(
    DateTime date,
    PlannedMeal meal,
    double servings,
  ) => _send(
    'POST',
    Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/meal-plans',
    ).replace(queryParameters: {'lang': _lang}),
    {
      'planDate': _date(date),
      'mealType': meal.slot.name.toUpperCase(),
      'plannerMealId': meal.id,
      'servings': servings,
    },
  );

  Future<List<PlannedMeal>> saveBulkMeals(
    List<Map<String, dynamic>> items,
  ) async {
    final headers = await _headers();
    headers['Content-Type'] = 'application/json';
    final response = await _client
        .post(
          Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/meal-plans/bulk',
          ).replace(queryParameters: {'lang': _lang}),
          headers: headers,
          body: jsonEncode(items),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const MealPlannerProviderException(
        'Unable to update meal planner in bulk.',
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is! List) {
      throw const MealPlannerProviderException(
        'Bulk meal planner response is incomplete.',
      );
    }
    return payload
        .map((e) => PlannedMeal.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((m) => m.id > 0)
        .toList();
  }

  Future<PlannedMeal> updateMeal(
    int planId, {
    DateTime? date,
    int? mealId,
    double? servings,
    MealPlanStatus? status,
    double? actualServings,
  }) => _send(
    'PUT',
    Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/meal-plans/$planId',
    ).replace(queryParameters: {'lang': _lang}),
    {
      if (date != null) 'planDate': _date(date),
      if (mealId != null) 'plannerMealId': mealId,
      if (servings != null) 'servings': servings,
      if (status != null) 'status': status.name.toUpperCase(),
      if (actualServings != null) 'actualServings': actualServings,
    },
  );
  Future<void> deleteMeal(int planId) async {
    final response = await _client
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/api/v1/meal-plans/$planId'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const MealPlannerProviderException('Unable to remove meal.');
    }
  }

  Future<List<PlannedMeal>> _getList(Uri uri) async {
    final response = await _client
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const MealPlannerProviderException('Unable to load meal planner.');
    }
    final payload = jsonDecode(response.body);
    if (payload is! List) {
      throw const MealPlannerProviderException(
        'Meal planner response is incomplete.',
      );
    }
    return payload
        .map((e) => PlannedMeal.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((m) => m.id > 0)
        .toList();
  }

  Future<PlannedMeal> _send(
    String method,
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    final headers = await _headers();
    headers['Content-Type'] = 'application/json';
    final response =
        method == 'POST'
            ? await _client
                .post(uri, headers: headers, body: jsonEncode(body))
                .timeout(const Duration(seconds: 15))
            : await _client
                .put(uri, headers: headers, body: jsonEncode(body))
                .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MealPlannerProviderException(
        _errorMessage(response, 'Unable to update meal planner.'),
        statusCode: response.statusCode,
      );
    }
    return PlannedMeal.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = await _authService.readAccessToken();
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String _errorMessage(http.Response response, String fallback) {
    try {
      final payload = jsonDecode(response.body);
      if (payload is Map) {
        final message = '${payload['message'] ?? payload['detail'] ?? payload['error'] ?? ''}'.trim();
        if (message.isNotEmpty) return message;
      }
    } catch (_) {
      // The server did not return JSON; use the stable fallback below.
    }
    return fallback;
  }

  Future<Map<String, dynamic>> analyzeIngredients({
    required String mealName,
    required List<String> ingredients,
    int servings = 1,
    String? lang,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/meal-planner/ingredients/analyze',
    );
    final headers = await _headers();
    headers['Content-Type'] = 'application/json';
    final body = {
      'mealName': mealName,
      'ingredients': ingredients,
      'servings': servings,
      'lang': lang ?? _lang,
    };
    final response = await _client
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MealPlannerProviderException(
        'Unable to analyze ingredients with AI & database.',
        statusCode: response.statusCode,
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const MealPlannerProviderException(
        'Ingredient analysis response is invalid.',
      );
    }
    return payload;
  }

  Future<String?> lookupIngredientImageUrl(String ingredientName) async {
    final name = ingredientName.trim();
    if (name.isEmpty) return null;

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/ingredients',
      ).replace(queryParameters: {'query': name, 'lang': _lang});
      final response = await _client
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final payload = jsonDecode(response.body);
      if (payload is! List) return null;
      final candidates = payload
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => '${item['imageUrl'] ?? ''}'.trim().isNotEmpty)
          .toList(growable: false);
      if (candidates.isEmpty) return null;

      final normalizedName = name.toLowerCase();
      final exact = candidates.where(
        (item) =>
            '${item['name'] ?? ''}'.trim().toLowerCase() == normalizedName,
      );
      final selected = exact.isNotEmpty ? exact.first : candidates.first;
      final imageUrl = '${selected['imageUrl']}'.trim();
      return imageUrl.startsWith('/')
          ? '${ApiConfig.baseUrl}$imageUrl'
          : imageUrl;
    } catch (_) {
      return null;
    }
  }

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class MealPlannerProviderException implements Exception {
  const MealPlannerProviderException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}
