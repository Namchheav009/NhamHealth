import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as image;
import 'package:nhamhealth_flutter/app/modules/repositories/wellness/food_nutrition_repository.dart';
import 'package:nhamhealth_flutter/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('food analysis displays the actionable API provider error', () async {
    final repository = FoodNutritionRepository(
      tokenStorage: _TokenStorage(),
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/ai/food/analyze');
        return http.Response(
          jsonEncode({
            'status': 503,
            'message':
                'The food recognition provider is not configured on the API server.',
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final photo = Uint8List.fromList(
      image.encodePng(image.Image(width: 4, height: 4)),
    );

    await expectLater(
      repository.analyzeImage(photo),
      throwsA(
        isA<FoodNutritionException>().having(
          (error) => error.message,
          'message',
          'The food recognition provider is not configured on the API server.',
        ),
      ),
    );
  });
}

class _TokenStorage extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => 'test-token';
}
