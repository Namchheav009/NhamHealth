import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../models/wellness/food_prediction_model.dart';

class FoodAiException implements Exception {
  const FoodAiException(this.message);
  final String message;
}

class FoodAiService {
  Interpreter? _interpreter;
  List<String> _labels = const [];

  Future<void> load() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/ai/food_model.tflite');
      final labels = await rootBundle.loadString('assets/ai/food_labels.txt');
      _labels =
          labels
              .split(RegExp(r'\r?\n'))
              .map((label) => label.trim())
              .where((label) => label.isNotEmpty)
              .toList();
      if (_labels.isEmpty) {
        throw const FoodAiException('Food labels are empty.');
      }
    } on FoodAiException {
      rethrow;
    } catch (_) {
      _interpreter?.close();
      _interpreter = null;
      throw const FoodAiException(
        'AI model is not installed yet. Add food_model.tflite and food_labels.txt to assets/ai/.',
      );
    }
  }

  Future<FoodPredictionModel> analyze(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FoodAiException(
        'That image could not be read. Try another photo.',
      );
    }
    return _analyzeImage(img.bakeOrientation(decoded));
  }

  Future<FoodPredictionModel> _analyzeImage(img.Image decoded) async {
    await load();
    final interpreter = _interpreter!;
    try {
      final input = interpreter.getInputTensor(0);
      final output = interpreter.getOutputTensor(0);
      final shape = input.shape;
      if (shape.length != 4 || shape.first != 1 || shape.last != 3) {
        throw const FoodAiException(
          'This model uses an unsupported image tensor format. Expected NHWC RGB.',
        );
      }
      final height = shape[1];
      final width = shape[2];
      // Classifiers are trained with square crops. Stretching a portrait meal
      // photo into a square distorts the food and noticeably hurts accuracy.
      final cropSize =
          decoded.width < decoded.height ? decoded.width : decoded.height;
      final cropped = img.copyCrop(
        decoded,
        x: (decoded.width - cropSize) ~/ 2,
        y: (decoded.height - cropSize) ~/ 2,
        width: cropSize,
        height: cropSize,
      );
      final resized = img.copyResize(cropped, width: width, height: height);
      final Object inputData;
      if (input.type == TensorType.uint8) {
        inputData = [
          List.generate(
            height,
            (y) => List.generate(width, (x) {
              final pixel = resized.getPixel(x, y);
              return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
            }),
          ),
        ];
      } else if (input.type == TensorType.float32) {
        inputData = [
          List.generate(
            height,
            (y) => List.generate(width, (x) {
              final pixel = resized.getPixel(x, y);
              return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
            }),
          ),
        ];
      } else {
        throw FoodAiException('Unsupported model input type: ${input.type}.');
      }

      final classCount = output.shape.reduce((a, b) => a * b);
      final outputData =
          output.type == TensorType.uint8
              ? List<int>.filled(classCount, 0).reshape(output.shape)
              : List<double>.filled(classCount, 0).reshape(output.shape);
      interpreter.run(inputData, outputData);
      final raw =
          outputData
              .expand((value) => value is List ? value : [value])
              .cast<num>()
              .toList();
      if (raw.isEmpty) {
        throw const FoodAiException('The AI model returned no result.');
      }
      var best = 0;
      for (var i = 1; i < raw.length; i++) {
        if (raw[i] > raw[best]) best = i;
      }
      var confidence = raw[best].toDouble();
      if (output.type == TensorType.uint8) confidence /= 255;
      final label =
          best < _labels.length ? _labels[best] : 'Food class ${best + 1}';
      if (best == 0 || label == '__background__') {
        throw const FoodAiException(
          'No food was detected. Center one meal in the frame and try again.',
        );
      }
      return FoodPredictionModel(
        foodName: label,
        confidence: confidence.clamp(0, 1),
        classIndex: best,
      );
    } on FoodAiException {
      rethrow;
    } catch (_) {
      throw const FoodAiException(
        'Food analysis failed. Try a clearer, well-lit image.',
      );
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
