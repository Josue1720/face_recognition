import 'dart:math';
import 'package:flutter/material.dart';
import 'package:face_camera/face_camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io'; // Import for File class
import '/config/mongoservice.dart';
import '/config/facerecognitionservice.dart'; // Import FaceRecognitionService for FaceNet

class ScanFaceScreen extends StatefulWidget {
  const ScanFaceScreen({super.key});

  @override
  _ScanFaceScreenState createState() => _ScanFaceScreenState();
}

class _ScanFaceScreenState extends State<ScanFaceScreen> {
  late FaceCameraController _controller;
  bool _isCameraReady = false;
  bool _faceDetected = false;
  String _resultMessage = "Center your face in the frame";

  final FaceRecognitionService faceRecognitionService = FaceRecognitionService(); // Initialize FaceRecognitionService

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeCamera();
    } else {
      setState(() => _resultMessage = "Camera permission denied!");
    }
  }

  // Calculate Euclidean Distance between two face embeddings
  double _calculateEuclideanDistance(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      return double.infinity; // Return max distance if sizes don't match
    }

    double distance = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      distance += (embedding1[i] - embedding2[i]) * (embedding1[i] - embedding2[i]);
    }
    return sqrt(distance); // Return the Euclidean distance
  }

  Future<void> _initializeCamera() async {
    try {
      await FaceCamera.initialize();
      setState(() {
        _isCameraReady = true;
        _controller = FaceCameraController(
          autoCapture: false,
          defaultCameraLens: CameraLens.front,
          onFaceDetected: (Face? face) {
            if (face != null) {
              setState(() {
                _faceDetected = true;
                _resultMessage = "Face Detected! Processing...";
              });

              // Capture the face and process it
              _processDetectedFace();
            } else {
              _handleNoFaceDetected();
            }
          },
          onCapture: (file) {
            // Handle the captured file
            if (file != null) {
              print("Captured file path: ${file.path}");
            } else {
              print("No file captured.");
            }
          },
        );
      });
    } catch (e) {
      setState(() {
        _isCameraReady = false;
        _resultMessage = "Error: No Camera Detected";
      });
    }
  }

  Future<void> _processDetectedFace() async {
    try {
      // Capture the image from the camera
      final file = await _controller.takePicture();
      if (file == null) {
        setState(() => _resultMessage = "Error: No image captured");
        return;
      }

      // Preprocess the image and extract embeddings using FaceNet
      final faceEmbedding = faceRecognitionService.getFaceEmbedding(File(file.path));
      if (faceEmbedding.isEmpty) {
        setState(() => _resultMessage = "Error: Failed to extract face embedding");
        return;
      }

      // Compare the embedding with stored data
      await _compareFace(faceEmbedding);
    } catch (e) {
      setState(() => _resultMessage = "Error processing face: $e");
      print("Error in _processDetectedFace: $e");
    }
  }


 /* Future<void> _compareFace(List<double> detectedEmbedding) async {
  try {
    print("🔹 Captured Face Embedding: $detectedEmbedding");

    // Fetch stored employee data (embeddings) from the MongoDB
    List<Map<String, dynamic>>? storedEmployees = await MongoDatabase.getData();
    if (storedEmployees.isEmpty) {
      setState(() => _resultMessage = "No face data found in database.");
      return;
    }

    double threshold = 0.6; // Threshold for Euclidean distance
    double minDistance = double.infinity;
    String bestMatch = "❌ No Match Found";

    for (var employee in storedEmployees) {
      List<dynamic>? storedEmbeddingRaw = employee['faceEmbedding'];
      if (storedEmbeddingRaw == null || storedEmbeddingRaw.isEmpty) continue;

      List<double> storedEmbedding = storedEmbeddingRaw.cast<double>();

      // Compare the detected face with the stored face embedding
      double distance = _calculateEuclideanDistance(detectedEmbedding, storedEmbedding);

      print("Distance for ${employee['fullName']}: $distance");

      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = employee['fullName'];
      }
    }

    if (minDistance > threshold) {
      setState(() {
        _resultMessage = "No Match Found\nShortest Distance: ${minDistance.toStringAsFixed(4)}";
      });
    } else {
      setState(() {
        _resultMessage = "Best Match: $bestMatch\nDistance: ${minDistance.toStringAsFixed(4)}";
      });

      // Log the match in the database
      await _logMatchedFace(bestMatch);
    }
  } catch (e) {
    setState(() => _resultMessage = "Error accessing database: $e");
    print("Error in _compareFace: $e");
  }
} */
Future<void> _compareFace(List<double> detectedEmbedding) async {
  try {
    print("🔹 Captured Face Embedding: $detectedEmbedding");

    // Fetch stored employee data (embeddings) from the MongoDB
    List<Map<String, dynamic>>? storedEmployees = await MongoDatabase.getData();
    if (storedEmployees.isEmpty) {
      setState(() => _resultMessage = "No face data found in database.");
      return;
    }

    double minDistance = double.infinity;
    String bestMatch = "Unknown";
    double threshold = 0.15; // Define a threshold for valid matching

    for (var employee in storedEmployees) {
      List<dynamic>? storedEmbeddingRaw = employee['faceEmbedding'];
      if (storedEmbeddingRaw == null || storedEmbeddingRaw.isEmpty) continue;

      List<double> storedEmbedding = storedEmbeddingRaw.cast<double>();

      // Compare the detected face with the stored face embedding
      double distance = _calculateEuclideanDistance(detectedEmbedding, storedEmbedding);

      print("Distance for ${employee['fullName']}: $distance");
      print(detectedEmbedding.length);

      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = employee['fullName'];
      }
    }

    // Check if the best match is within the threshold
    if (minDistance > threshold) {
      bestMatch = "No Match Found";
    }

    // Update the UI with the result
    setState(() {
      _resultMessage = "Best Match: $bestMatch\nShortest Distance: ${minDistance.toStringAsFixed(4)}";
    });

    if (bestMatch != "No Match Found") {
      // Log the match in the database
      await _logMatchedFace(bestMatch);
    }
  } catch (e) {
    setState(() => _resultMessage = "Error accessing database: $e");
    print("Error in _compareFace: $e");
  }
}

  
  Future<void> _logMatchedFace(String employeeName) async {
    try {
      await MongoDatabase.addMatchedRecord({
        'employeeName': employeeName,
        'timestamp': DateTime.now().toString(),
      });
      print('Face match recorded for $employeeName');
    } catch (e) {
      print('Error logging matched face: $e');
    }
  }

  void _handleNoFaceDetected() {
    setState(() {
      _faceDetected = false;
      _resultMessage = "No Face Detected";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Real-Time Face Recognition")),
      body: _isCameraReady
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Transform(
                  alignment: Alignment.center,
                  // Only flip the preview for the front camera
                  transform: _controller.defaultCameraLens == CameraLens.front
                      ? (Matrix4.identity()..scale(-1.0, 1.0))
                      : Matrix4.identity(),
                  child: SmartFaceCamera(controller: _controller),
                ),

                ),
                const SizedBox(height: 20),
                Text(
                  _resultMessage,
                  style: TextStyle(
                    fontSize: 18,
                    color: _faceDetected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_resultMessage, style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}