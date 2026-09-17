import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/planner/meal_plan.dart';

class MealPlannerProvider {
  MealPlannerProvider({required AuthService authService, http.Client? client})
    : _authService = authService,
      _client = client ?? http.Client();
  final AuthService _authService;
  final http.Client _client;
  String get _lang => Get.locale?.languageCode ?? 'en';

  Future<List<PlannedMeal>> getRecommendations({
    DateTime? date,
    String? dayOfWeek,
  }) {
    final query = <String, String>{'lang': _lang};
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
      throw const MealPlannerProviderException(
        'Unable to update meal planner.',
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

  String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class MealPlannerProviderException implements Exception {
  const MealPlannerProviderException(this.message);
  final String message;
  @override
  String toString() => message;
}
