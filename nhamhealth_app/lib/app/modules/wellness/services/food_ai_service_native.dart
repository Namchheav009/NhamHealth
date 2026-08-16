import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/food_prediction_model.dart';

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
    return _analyzeImage(decoded);
  }

  Future<FoodPredictionModel> analyzeCameraImage(
    CameraImage cameraImage, {
    int rotationDegrees = 0,
  }) async {
    final converted = _cameraImageToRgb(cameraImage);
    final upright =
        rotationDegrees == 0
            ? converted
            : img.copyRotate(converted, angle: rotationDegrees);
    return _analyzeImage(upright);
  }

  Uint8List cameraImageToJpeg(
    CameraImage cameraImage, {
    int rotationDegrees = 0,
  }) {
    final converted = _cameraImageToRgb(cameraImage);
    final upright =
        rotationDegrees == 0
            ? converted
            : img.copyRotate(converted, angle: rotationDegrees);
    return Uint8List.fromList(img.encodeJpg(upright, quality: 78));
  }

  img.Image _cameraImageToRgb(CameraImage frame) {
    if (frame.format.group == ImageFormatGroup.bgra8888) {
      return img.Image.fromBytes(
        width: frame.width,
        height: frame.height,
        bytes: frame.planes.first.bytes.buffer,
        rowStride: frame.planes.first.bytesPerRow,
        order: img.ChannelOrder.bgra,
      );
    }
    if (frame.planes.length < 3) {
      throw const FoodAiException('Unsupported live camera image format.');
    }

    final image = img.Image(width: frame.width, height: frame.height);
    final yPlane = frame.planes[0];
    final uPlane = frame.planes[1];
    final vPlane = frame.planes[2];
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    for (var y = 0; y < frame.height; y++) {
      final uvRow = y ~/ 2;
      for (var x = 0; x < frame.width; x++) {
        final uvIndex = uvRow * uPlane.bytesPerRow + (x ~/ 2) * uvPixelStride;
        final yValue = yPlane.bytes[y * yPlane.bytesPerRow + x];
        final uValue = uPlane.bytes[uvIndex];
        final vValue = vPlane.bytes[uvIndex];
        final r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        final g = (yValue -
                0.344136 * (uValue - 128) -
                0.714136 * (vValue - 128))
            .round()
            .clamp(0, 255);
        final b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);
        image.setPixelRgb(x, y, r, g, b);
      }
    }
    return image;
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
      final resized = img.copyResize(decoded, width: width, height: height);
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
      return FoodPredictionModel(
        foodName:
            best < _labels.length ? _labels[best] : 'Food class ${best + 1}',
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
