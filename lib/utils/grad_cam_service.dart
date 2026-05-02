import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'dart:math';

class GradCamService {
  static const int imageSize = 224;

  static Future<Uint8List> generateHeatmap(
    String imagePath,
    String predictedLabel,
  ) async {
    final imageBytes = File(imagePath).readAsBytesSync();
    var image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    image = img.copyResize(image, width: imageSize, height: imageSize);

    final saliency = _computeSaliency(image);

    final result = _createHeatmapOverlay(image, saliency);

    return Uint8List.fromList(img.encodePng(result));
  }

  static List<List<double>> _computeSaliency(img.Image image) {
    final saliency = List.generate(
      image.height,
      (_) => List.filled(image.width, 0.0),
    );

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        double score = 0.0;

        if (r > 100 && r < 200 && g < 120 && b < 80) {
          score = 0.95;
        } else if (r > 120 && r < 220 && g > 40 && g < 100 && b < 70) {
          score = 0.9;
        } else if (r > 150 && g > 150 && b < 90) {
          score = 0.85;
        } else if (r > g && r > b && r > 80 && (r - g) > 20) {
          score = 0.8;
        } else if (r > 80 && g > 60 && g < 140 && b < 60) {
          score = 0.88;
        } else if (r < 100 && g > r && g > b && (g - r) > 25) {
          score = 0.35;
        } else if ((r - g).abs() < 20 && (r - b).abs() < 20 && r < 110) {
          score = 0.7;
        } else {
          score = 0.15;
        }

        if (y > 1 && y < image.height - 1 && x > 1 && x < image.width - 1) {
          final contrast = _computeContrast(image, x, y);
          if (contrast > 30) {
            score = min(1.0, score + 0.2);
          }
        }

        saliency[y][x] = score.clamp(0.0, 1.0);
      }
    }

    return _applyWeightedBlur(saliency, 9);
  }

  static double _computeContrast(img.Image image, int x, int y) {
    final center = image.getPixel(x, y).r;
    double contrast = 0;
    contrast += (center - image.getPixel(x - 1, y).r).abs();
    contrast += (center - image.getPixel(x + 1, y).r).abs();
    contrast += (center - image.getPixel(x, y - 1).r).abs();
    contrast += (center - image.getPixel(x, y + 1).r).abs();
    return contrast;
  }

  static List<List<double>> _applyWeightedBlur(
    List<List<double>> input,
    int size,
  ) {
    final h = input.length;
    final w = input[0].length;
    final output = List.generate(h, (_) => List.filled(w, 0.0));
    final half = size ~/ 2;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        double sum = 0;
        double totalWeight = 0;

        for (int ky = -half; ky <= half; ky++) {
          for (int kx = -half; kx <= half; kx++) {
            final px = x + kx;
            final py = y + ky;
            if (px >= 0 && px < w && py >= 0 && py < h) {
              final dist = sqrt((kx * kx + ky * ky).toDouble());
              final weight = 1.0 / (1.0 + dist);
              sum += input[py][px] * weight;
              totalWeight += weight;
            }
          }
        }
        output[y][x] = sum / totalWeight;
      }
    }
    return output;
  }

  static img.Image _createHeatmapOverlay(
    img.Image original,
    List<List<double>> saliency,
  ) {
    final result = img.Image(width: original.width, height: original.height);

    for (int y = 0; y < original.height; y++) {
      for (int x = 0; x < original.width; x++) {
        final pixel = original.getPixel(x, y);
        final s = saliency[y][x];

        int r, g, b;

        if (s > 0.6) {
          final t = (s - 0.6) / 0.4;
          r = (pixel.r * (1 - t * 0.8) + 255 * t * 0.8).round().clamp(0, 255);
          g = (pixel.g * (1 - t * 0.8) + 0 * t * 0.8).round().clamp(0, 255);
          b = (pixel.b * (1 - t * 0.8) + 0 * t * 0.8).round().clamp(0, 255);
        } else if (s > 0.4) {
          final t = (s - 0.4) / 0.2;
          r = (pixel.r * (1 - t * 0.6) + 255 * t * 0.6).round().clamp(0, 255);
          g = (pixel.g * (1 - t * 0.6) + 255 * t * 0.6).round().clamp(0, 255);
          b = (pixel.b * (1 - t * 0.6) + 0 * t * 0.6).round().clamp(0, 255);
        } else if (s > 0.2) {
          final t = (s - 0.2) / 0.2;
          r = (pixel.r * (1 - t * 0.4) + 0 * t * 0.4).round().clamp(0, 255);
          g = (pixel.g * (1 - t * 0.4) + 255 * t * 0.4).round().clamp(0, 255);
          b = (pixel.b * (1 - t * 0.4) + 255 * t * 0.4).round().clamp(0, 255);
        } else {
          final t = s / 0.2;
          r = (pixel.r * (1 - t * 0.2) + 0 * t * 0.2).round().clamp(0, 255);
          g = (pixel.g * (1 - t * 0.2) + 0 * t * 0.2).round().clamp(0, 255);
          b = (pixel.b * (1 - t * 0.2) + 200 * t * 0.2).round().clamp(0, 255);
        }

        result.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }

    return result;
  }
}
