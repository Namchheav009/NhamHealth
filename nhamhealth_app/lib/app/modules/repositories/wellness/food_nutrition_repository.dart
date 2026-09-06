import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image;

import '../../../../config/api_config.dart';
import '../../../../core/storage/token_storage.dart';
import '../../models/wellness/food_nutrition_model.dart';

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
      return FoodNutritionModel.fromJson(payload).asDatabaseVerified();
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
    if (_imageMediaSubtype(bytes) == null) {
      throw const FoodNutritionException(
        'Choose a valid JPG, PNG, or WebP food image.',
      );
    }
    final uploadBytes = _prepareAiImage(bytes);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/v1/ai/food/analyze'),
    )..headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        uploadBytes,
        filename: _jpegFilename(filename),
        contentType: http.MediaType('image', 'jpeg'),
      ),
    );
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 180));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const FoodNutritionException(
          'Your session has expired. Please sign in again.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final providerMessage = _serverErrorMessage(response.body);
        throw FoodNutritionException(
          providerMessage ??
              (response.statusCode == 503
                  ? 'Food analysis is temporarily unavailable. Please try again '
                      'shortly. If it continues, check the AI provider keys, billing, '
                      'and usage limits.'
                  : 'Cloud food AI could not analyze this image.'),
        );
      }
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) {
        throw const FoodNutritionException('The AI response was invalid.');
      }
      return FoodNutritionModel.fromJson(payload);
    } on FoodNutritionException {
      rethrow;
    } on TimeoutException {
      throw const FoodNutritionException(
        'Food analysis took too long. Please try again with a smaller, clearer photo.',
      );
    } catch (_) {
      throw FoodNutritionException(
        'Could not reach the NhamHealth API at ${ApiConfig.baseUrl}. Start the API server and try again.',
      );
    }
  }

  String? _serverErrorMessage(String responseBody) {
    try {
      final payload = jsonDecode(responseBody);
      if (payload is! Map<String, dynamic>) return null;
      for (final key in const ['message', 'detail']) {
        final value = payload[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    } catch (_) {
      // Older API versions may return an empty or non-JSON error body.
    }
    return null;
  }

  String? _imageMediaSubtype(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpeg';
    }
    const pngSignature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
    if (bytes.length >= pngSignature.length) {
      var isPng = true;
      for (var index = 0; index < pngSignature.length; index++) {
        if (bytes[index] != pngSignature[index]) {
          isPng = false;
          break;
        }
      }
      if (isPng) return 'png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }
    return null;
  }

  Uint8List _prepareAiImage(Uint8List bytes) {
    final decoded = image.decodeImage(bytes);
    if (decoded == null || decoded.width <= 0 || decoded.height <= 0) {
      throw const FoodNutritionException(
        'Choose a valid JPG, PNG, or WebP food image.',
      );
    }
    final oriented = image.bakeOrientation(decoded);
    Uint8List? smallest;
    for (final maxDimension in const [640, 512]) {
      final image.Image resized;
      if (oriented.width <= maxDimension && oriented.height <= maxDimension) {
        resized = oriented;
      } else if (oriented.width >= oriented.height) {
        resized = image.copyResize(
          oriented,
          width: maxDimension,
          interpolation: image.Interpolation.average,
        );
      } else {
        resized = image.copyResize(
          oriented,
          height: maxDimension,
          interpolation: image.Interpolation.average,
        );
      }
      for (final quality in const [76, 64, 52]) {
        final encoded = Uint8List.fromList(
          image.encodeJpg(resized, quality: quality),
        );
        smallest = encoded;
        if (encoded.length <= _maxInlineAiImageBytes) return encoded;
      }
    }
    if (smallest != null && smallest.length <= _nvidiaAbsoluteImageLimit) {
      return smallest;
    }
    throw const FoodNutritionException(
      'This photo is too detailed for cloud analysis. Crop it and try again.',
    );
  }

  String _jpegFilename(String filename) {
    final clean = filename.trim();
    final dot = clean.lastIndexOf('.');
    final base = dot > 0 ? clean.substring(0, dot) : clean;
    return '${base.isEmpty ? 'food' : base}.jpg';
  }

  Future<void> submitFeedback({
    required int analysisId,
    required bool confirmed,
    required String foodName,
    required double servingSize,
    required String servingUnit,
  }) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      throw const FoodNutritionException(
        'Please sign in again to confirm this food.',
      );
    }
    try {
      final response = await _client
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/v1/ai/food/$analysisId/feedback',
            ),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'confirmed': confirmed,
              'foodName': foodName.trim(),
              'servingSize': servingSize,
              'servingUnit': servingUnit.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FoodNutritionException(
          _serverErrorMessage(response.body) ??
              'Could not save your AI correction.',
        );
      }
    } on FoodNutritionException {
      rethrow;
    } catch (_) {
      throw const FoodNutritionException(
        'Could not reach the feedback service.',
      );
    }
  }
}

const int _maxInlineAiImageBytes = 175 * 1024;
const int _nvidiaAbsoluteImageLimit = 180 * 1024;
