import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../../config/api_config.dart';
import '../../../../core/services/auth_service.dart';
import '../../models/recipes/community_recipe.dart';

class RecipeRepository {
  RecipeRepository({required AuthService authService, http.Client? client})
    : _auth = authService,
      _client = client ?? http.Client();
  final AuthService _auth;
  final http.Client _client;
  static const _basePath = '/api/community/meals';

  Future<List<CommunityRecipe>> feed() async => _list(_basePath);
  Future<List<CommunityRecipe>> mine() async => _list('$_basePath/mine');
  Future<List<CommunityRecipe>> saved() async => _list('$_basePath/saved');
  Future<CommunityRecipe> detail(int id) async => CommunityRecipe.fromJson(
    _map(await _client.get(_uri('$_basePath/$id'), headers: await _headers())),
  );
  Future<CommunityRecipe> create({
    required String name,
    String description = '',
    int? cookingTimeMinutes,
    int? servings,
    String difficulty = 'EASY',
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
    Uint8List? imageBytes,
  }) => _sendRecipe(
    'POST',
    _basePath,
    name: name,
    description: description,
    cookingTimeMinutes: cookingTimeMinutes,
    servings: servings,
    difficulty: difficulty,
    ingredients: ingredients,
    steps: steps,
    imageBytes: imageBytes,
  );
  Future<CommunityRecipe> update({
    required int id,
    required String name,
    String description = '',
    int? cookingTimeMinutes,
    int? servings,
    String difficulty = 'EASY',
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
    Uint8List? imageBytes,
  }) => _sendRecipe(
    'PUT', '$_basePath/$id',
    name: name,
    description: description,
    cookingTimeMinutes: cookingTimeMinutes,
    servings: servings,
    difficulty: difficulty,
    ingredients: ingredients,
    steps: steps,
    imageBytes: imageBytes,
  );
  Future<CommunityRecipe> publish(int id) =>
      _post('$_basePath/$id/publish');
  Future<CommunityRecipe> aiCheck(int id) =>
      _post('$_basePath/$id/ai-review');
  Future<void> delete(int id) async {
    final response = await _client.delete(
      _uri('$_basePath/$id'),
      headers: await _headers(),
    );
    _ok(response);
  }
  Future<CommunityRecipe> toggleSaved(CommunityRecipe recipe) async {
    final response =
        recipe.saved
            ? await _client.delete(
              _uri('$_basePath/${recipe.id}/saved'),
              headers: await _headers(),
            )
            : await _client.post(
              _uri('$_basePath/${recipe.id}/saved'),
              headers: await _headers(),
            );
    return CommunityRecipe.fromJson(_map(response));
  }

  Future<CommunityRecipe> _sendRecipe(
    String method,
    String path, {
    required String name,
    required String description,
    required int? cookingTimeMinutes,
    required int? servings,
    String difficulty = 'EASY',
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
    Uint8List? imageBytes,
  }) async {
    final request = http.MultipartRequest(method, _uri(path))
      ..headers.addAll(await _headers(contentType: false));
    final payload = {
      'recipeName': name.trim(),
      'description': description.trim(),
      if (cookingTimeMinutes != null) 'cookingTimeMinutes': cookingTimeMinutes,
      if (servings != null) 'servings': servings,
      'difficulty': difficulty,
      'ingredients': ingredients.map((item) => item.toJson()).toList(),
      'steps': steps.map((item) => item.toJson()).toList(),
    };
    request.files.add(
      http.MultipartFile.fromString(
        'recipe',
        jsonEncode(payload),
        contentType: MediaType('application', 'json'),
      ),
    );
    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'recipe-cover.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }
    return CommunityRecipe.fromJson(
      _map(await http.Response.fromStream(await _client.send(request))),
    );
  }

  Future<CommunityRecipe> _post(String path) async => CommunityRecipe.fromJson(
    _map(await _client.post(_uri(path), headers: await _headers())),
  );
  Future<List<CommunityRecipe>> _list(String path) async {
    final response = await _client.get(_uri(path), headers: await _headers());
    _ok(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map(
          (item) =>
              CommunityRecipe.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<Map<String, String>> _headers({bool contentType = true}) async {
    final token = await _auth.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const RecipeException('Please sign in to manage recipes.');
    }
    return {
      'Accept': 'application/json',
      if (contentType) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _map(http.Response response) {
    _ok(response);
    final body = jsonDecode(response.body);
    if (body is Map) return Map<String, dynamic>.from(body);
    throw const RecipeException('The server returned invalid recipe data.');
  }

  void _ok(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String) {
        throw RecipeException(body['message'] as String);
      }
    } on FormatException {
      // Fall through when the server error body is not valid JSON.
    }
    throw RecipeException('Recipe request failed (${response.statusCode}).');
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');
}

class RecipeException implements Exception {
  const RecipeException(this.message);
  final String message;
  @override
  String toString() => message;
}
