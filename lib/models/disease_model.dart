import 'dart:io';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class DiseaseModel {
  static const String modelPath = 'assets/model/maize_disease_model.tflite';
  static const int imageSize = 227;
  static const int numClasses = 7;

  static final List<String> labels = [
    'Bacterial Leaf Streak',
    'Common Rust',
    'Gray Leaf Spot',
    'Healthy',
    'Maize Chlorotic Mottle Virus',
    'Maize Streak Virus',
    'Northern Leaf Blight',
  ];

  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      final modelData = await rootBundle.load(modelPath);
      final modelBytes = modelData.buffer.asUint8List();
      _interpreter = Interpreter.fromBuffer(modelBytes);
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }
  }

  img.Image preprocessImage(String imagePath) {
    final bytes = File(imagePath).readAsBytesSync();
    var image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    image = img.copyResize(image, width: imageSize, height: imageSize);
    return image;
  }

  List<double> imageToFloat32List(img.Image image) {
    final List<double> pixels = [];

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        pixels.add(pixel.r / 255.0);
        pixels.add(pixel.g / 255.0);
        pixels.add(pixel.b / 255.0);
      }
    }

    return pixels;
  }

  Future<PredictionResult> predict(String imagePath) async {
    if (_interpreter == null) {
      await loadModel();
    }

    try {
      final image = preprocessImage(imagePath);
      final input = imageToFloat32List(image);

      final inputTensor = Float32List.fromList(input);
      final inputBuffer = inputTensor.reshape([1, imageSize, imageSize, 3]);

      final outputBuffer = Float32List(numClasses).reshape([1, numClasses]);

      _interpreter!.run(inputBuffer, outputBuffer);

      final List<double> probabilities = [];
      for (int i = 0; i < numClasses; i++) {
        probabilities.add(outputBuffer[0][i].toDouble());
      }

      final maxIndex = _findMaxIndex(probabilities);
      final confidence = probabilities[maxIndex];

      return PredictionResult(
        label: labels[maxIndex],
        confidence: confidence,
        allProbabilities: probabilities,
      );
    } catch (e) {
      throw Exception('Prediction failed: $e');
    }
  }

  void dispose() {
    _interpreter?.close();
  }

  int _findMaxIndex(List<double> list) {
    int maxIndex = 0;
    double maxValue = list[0];
    for (int i = 1; i < list.length; i++) {
      if (list[i] > maxValue) {
        maxValue = list[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }
}

class PredictionResult {
  final String label;
  final double confidence;
  final List<double> allProbabilities;

  PredictionResult({
    required this.label,
    required this.confidence,
    required this.allProbabilities,
  });

  double get confidencePercentage => confidence * 100;
}
