import 'dart:io';
import 'package:path/path.dart';
import 'facerecognitionservice.dart'; // Import your service

void main() async {
  try {
    print("Initializing FaceRecognitionService...");
    FaceRecognitionService faceService = FaceRecognitionService();

    // Load a sample image (Make sure face.jpg exists in the same directory)
    File testImage = File(join(Directory.current.path, "josue.jpg"));
    if (!testImage.existsSync()) {
      print("Error: Sample image not found!");
      return;
    }

    print("Extracting face embedding...");
    List<double> embedding = faceService.getFaceEmbedding(testImage);

    if (embedding.isNotEmpty) {
      print("✅ Model is working! Face embedding generated:");
      print(embedding);
    } else {
      print("❌ Model failed to generate embedding.");
    }
  } catch (e) {
    print("Error in model test: $e");
  }
}
