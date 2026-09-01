import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/favorites/favorite_food.dart';

class FavoritesProvider {
  FavoritesProvider({required AuthService authService, http.Client? client})
    : _authService = authService,
      _client = client ?? http.Client();

  final AuthService _authService;
  final http.Client _client;

  Future<List<FavoriteFood>> getFoods() async {
    final response = await _request('GET');
    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload
        .map((item) {
          final data = Map<String, dynamic>.from(item as Map);
          final image = data['imageUrl'] as String?;
          if (image != null && image.startsWith('/')) {
            data['imageUrl'] = '${ApiConfig.baseUrl}$image';
          }
          return FavoriteFood.fromJson(data);
        })
        .toList(growable: false);
  }

  Future<List<String>> getFoodCategories() async {
    final token = await _authService.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const FavoritesException('Your session has expired.');
    }

    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/meal-categories'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FavoritesException(
        'Unable to load meal categories (HTTP ${response.statusCode}).',
      );
    }

    try {
      final payload = jsonDecode(response.body) as List<dynamic>;
      return payload
          .map((item) => (item as Map)['name'] as String? ?? '')
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .toList(growable: false);
    } on Object {
      throw const FavoritesException(
        'The meal category response is incomplete.',
      );
    }
  }

  Future<void> addFood(int mealId) async => _request('POST', mealId: mealId);

  Future<void> removeFood(int mealId) async =>
      _request('DELETE', mealId: mealId);

  Future<http.Response> _request(String method, {int? mealId}) async {
    final token = await _authService.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const FavoritesException('Your session has expired.');
    }
    final suffix = mealId == null ? '' : '/$mealId';
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/favorites/meals$suffix');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final response = switch (method) {
      'POST' => await _client.post(uri, headers: headers),
      'DELETE' => await _client.delete(uri, headers: headers),
      _ => await _client.get(uri, headers: headers),
    };
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FavoritesException(
        'Unable to update favorites (HTTP ${response.statusCode}).',
      );
    }
    return response;
  }
}

class FavoritesException implements Exception {
  const FavoritesException(this.message);
  final String message;
  @override
  String toString() => message;
}
