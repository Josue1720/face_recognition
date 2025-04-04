import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'dart:math';
import 'dart:io';
import 'package:image/image.dart' as img;

class FaceRecognitionService {
  late Interpreter _interpreter;

  FaceRecognitionService() {
    _initialize();
  }

  Future<void> _initialize() async {
    _loadModel();
  }

  /// Load the MobileFaceNet model
  void _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
  }

  /// Preprocess the face image (crop, resize, normalize)
  List<double> _preprocessImage(File imageFile) {
    // Load the image using the `image` package
    final rawImage = img.decodeImage(imageFile.readAsBytesSync());
    if (rawImage == null) {
      throw Exception("Failed to decode image");
    }

    // Resize the image to 112x112 (MobileFaceNet input size)
    final resizedImage = img.copyResize(rawImage, width: 112, height: 112);

    // Normalize the image (convert to float32 and scale to [-1, 1])
    final Float32List normalizedImage = Float32List(112 * 112 * 3);
    int index = 0;
    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final pixel = resizedImage.getPixel(x, y);
        normalizedImage[index++] = ((img.getRed(pixel) / 255.0) - 0.5) * 2.0;
        normalizedImage[index++] = ((img.getGreen(pixel) / 255.0) - 0.5) * 2.0;
        normalizedImage[index++] = ((img.getBlue(pixel) / 255.0) - 0.5) * 2.0;
      }
    }

    return normalizedImage.toList();
  }

List<double> getFaceEmbeddingFromPixels(List<double> imagePixels) {
  if (imagePixels.length != 112 * 112 * 3) {
    throw Exception("Invalid pixel length. Expected: ${112 * 112 * 3}, but got: ${imagePixels.length}");
  }

  // Reshape the flat list into the required shape: [1, 112, 112, 3]
  final inputTensor = imagePixels.reshape([1, 112, 112, 3]);

  // Prepare output tensor for 192-dimensional embedding
  var outputTensor = List.generate(1, (index) => List.filled(192, 0.0)); // 192-d embedding

  // Run the model
  _interpreter.run(inputTensor, outputTensor);

  return outputTensor[0]; // Return the 192-d embedding
}

  /// Get face embeddings from the preprocessed image
 List<double> getFaceEmbedding(File imageFile) {
  try {
    // Preprocess the image
    final input = _preprocessImage(imageFile);

    // Ensure the input tensor has the correct shape
    if (input.length != 112 * 112 * 3) {
      throw Exception("Invalid input length. Expected: ${112 * 112 * 3}, but got: ${input.length}");
    }

    // Reshape the input into the required shape: [1, 112, 112, 3]
    final inputTensor = input.reshape([1, 112, 112, 3]);

    // Prepare output tensor for 192-dimensional embedding
    var outputTensor = List.generate(1, (index) => List.filled(192, 0.0)); // 192-d embedding

    // Run the model
    _interpreter.run(inputTensor, outputTensor);

    return outputTensor[0]; // Return the 192-d embedding
  } catch (e) {
    print("Error in getFaceEmbedding: $e");
    return [];
  }
}

  /// Calculate cosine similarity between two embeddings
  double cosineSimilarity(List<double> vectorA, List<double> vectorB) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < vectorA.length; i++) {
      dotProduct += vectorA[i] * vectorB[i];
      normA += vectorA[i] * vectorA[i];
      normB += vectorB[i] * vectorB[i];
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}