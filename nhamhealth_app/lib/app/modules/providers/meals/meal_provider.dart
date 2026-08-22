import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/meals/meal_model.dart';
import '../../models/meals/meal_category_model.dart';

class MealProvider {
  MealProvider({required AuthService authService, http.Client? client})
    : _authService = authService,
      _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<List<MealModel>> getMeals({String keyword = '', int categoryId = 0}) async {
    final query = <String, String>{};
    if (keyword.trim().isNotEmpty) query['keyword'] = keyword.trim();
    if (categoryId != 0) query['categoryId'] = '$categoryId';
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/meals').replace(
      queryParameters: query,
    );
    final payload = await _getList(uri);
    return payload
        .map((item) => MealModel.fromJson(item, baseUrl: ApiConfig.baseUrl))
        .toList(growable: false);
  }

  Future<List<MealCategoryModel>> getCategories() async {
    final payload = await _getList(Uri.parse('${ApiConfig.baseUrl}/api/v1/meal-categories'));
    return payload
        .map(MealCategoryModel.fromJson)
        .toList(growable: false);
  }

  Future<Set<int>> getFavoriteMealIds() async {
    final payload = await _getList(Uri.parse('${ApiConfig.baseUrl}/api/v1/favorites/meals'));
    return payload
        .map((item) => (item['id'] as num).toInt())
        .toSet();
  }

  Future<int> getUnreadNotificationCount() async {
    final payload = await _getObject('/api/v1/notifications/unread-count');
    return (payload['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> setFavorite(int mealId, {required bool favorite}) async {
    final token = await _token();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/favorites/meals/$mealId',
    );
    final headers = {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
    final response = favorite
        ? await _client.post(uri, headers: headers)
        : await _client.delete(uri, headers: headers);
    _ensureSuccess(response, 'Unable to update favorite');
  }

  Future<List<Map<String, dynamic>>> _getList(Uri uri) async {
    final token = await _token();
    final response = await _client
        .get(
          uri,
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    _ensureSuccess(response, 'Unable to load meals');

    try {
      final payload = jsonDecode(response.body);
      if (payload is! List) throw const FormatException();
      return payload
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
    } on Object {
      throw const MealProviderException('The meal response is incomplete.');
    }
  }

  Future<Map<String, dynamic>> _getObject(String path) async {
    final token = await _token();
    final response = await _client
        .get(
          Uri.parse('${ApiConfig.baseUrl}$path'),
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    _ensureSuccess(response, 'Unable to load notifications');
    try {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } on Object {
      throw const MealProviderException(
        'The notification response is incomplete.',
      );
    }
  }

  Future<String> _token() async {
    final token = await _authService.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const MealProviderException(
        'Your session has expired. Please sign in again.',
      );
    }
    return token;
  }

  void _ensureSuccess(http.Response response, String message) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MealProviderException('$message (HTTP ${response.statusCode}).');
    }
  }
}

class MealProviderException implements Exception {
  const MealProviderException(this.message);

  final String message;

  @override
  String toString() => message;
}
