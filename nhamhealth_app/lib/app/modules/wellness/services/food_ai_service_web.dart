import 'dart:typed_data';

import '../models/food_prediction_model.dart';

class FoodAiException implements Exception {
  const FoodAiException(this.message);

  final String message;
}

class FoodAiService {
  static const _unsupportedMessage =
      'On-device food analysis is not available in the web app. Please use the Android or iOS app.';

  Future<void> load() async {
    throw const FoodAiException(_unsupportedMessage);
  }

  Future<FoodPredictionModel> analyze(Uint8List bytes) async {
    throw const FoodAiException(_unsupportedMessage);
  }

  void dispose() {}
}
