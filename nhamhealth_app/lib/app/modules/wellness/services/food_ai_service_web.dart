import 'dart:typed_data';

import 'package:camera/camera.dart';

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

  Future<FoodPredictionModel> analyzeCameraImage(
    CameraImage cameraImage, {
    int rotationDegrees = 0,
  }) async {
    throw const FoodAiException(_unsupportedMessage);
  }

  Uint8List cameraImageToJpeg(
    CameraImage cameraImage, {
    int rotationDegrees = 0,
  }) => throw const FoodAiException(_unsupportedMessage);

  void dispose() {}
}
