import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/food_nutrition_model.dart';

class FoodNutritionException implements Exception {
  const FoodNutritionException(this.message);
  final String message;
}

class FoodNutritionRepository {
  FoodNutritionRepository({http.Client? client, TokenStorage? tokenStorage})
    : _client = client ?? http.Client(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  final http.Client _client;
  final TokenStorage _tokenStorage;

  Future<FoodNutritionModel?> searchFood(String name) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const FoodNutritionException(
        'Please sign in again to load nutrition.',
      );
    }
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/foods/search',
    ).replace(queryParameters: {'name': name});
    try {
      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 404) {
        return null;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const FoodNutritionException(
          'Your session has expired. Please sign in again.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const FoodNutritionException(
          'Nutrition is temporarily unavailable. Please try again.',
        );
      }
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        throw const FoodNutritionException(
          'The nutrition response was invalid.',
        );
      }
      return FoodNutritionModel.fromJson(payload);
    } on FoodNutritionException {
      rethrow;
    } catch (_) {
      throw const FoodNutritionException(
        'Could not reach the nutrition service. Check your connection and try again.',
      );
    }
  }

  Future<FoodNutritionModel> analyzeImage(
    Uint8List bytes, {
    String filename = 'food.jpg',
  }) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const FoodNutritionException(
        'Please sign in again to analyze food.',
      );
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/food/analyze'),
    )..headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes('image', bytes, filename: filename),
    );
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const FoodNutritionException(
          'Your session has expired. Please sign in again.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FoodNutritionException(
          response.statusCode == 503
              ? 'Cloud food AI is not configured on the server.'
              : 'Cloud food AI could not analyze this image.',
        );
      }
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        throw const FoodNutritionException('The AI response was invalid.');
      }
      return FoodNutritionModel.fromJson(payload);
    } on FoodNutritionException {
      rethrow;
    } catch (_) {
      throw const FoodNutritionException(
        'Could not reach cloud food AI. Check the server connection.',
      );
    }
  }
}
