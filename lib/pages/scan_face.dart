import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:face_camera/face_camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import'/config/mongoservice.dart';

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

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  /// ✅ **Request Camera Permission First**
  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeCamera();
    } else {
      setState(() => _resultMessage = "Camera permission denied!");
    }
  }
double _calculateDistance(List<Map<String, double>> detected, List<Map<String, double>> stored) {
  int minLength = min(detected.length, stored.length);  // Ensure same length

  if (minLength == 0) return double.infinity; // Avoid division by zero

  double totalDistance = 0.0;
  for (int i = 0; i < minLength; i++) {
    double dx = detected[i]['x']! - stored[i]['x']!;
    double dy = detected[i]['y']! - stored[i]['y']!;
    totalDistance += (dx * dx) + (dy * dy);
  }
  
  return sqrt(totalDistance / minLength);  // Normalize distance
}


  /// ✅ **Initialize Camera Properly**
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

    // Extract facial landmarks (real embeddings)
    List<Map<String, double>> extractedLandmarks = _extractEmbeddings(
      face,
      Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
    );

    // Compare with stored embeddings
    _compareFace(extractedLandmarks);
  } else {
    _handleNoFaceDetected();
  }
}
,
          onCapture: (file) async {
  if (file == null) return;

  final inputImage = InputImage.fromFilePath(file.path);
  final faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(enableLandmarks: true, enableContours: true),
  );

  final faces = await faceDetector.processImage(inputImage);

  if (faces.isEmpty) {
    setState(() => _resultMessage = "No Face Detected. Try Again.");
    return;
  }

  final face = faces.first;
  List<Map<String, double>> detectedLandmarks = _extractEmbeddings(face, Size(1.0, 1.0)); // Replace with actual image size if available

  await _compareFace(detectedLandmarks);
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

List<Map<String, double>> _extractEmbeddings(Face face, Size imageSize) {
  return [
    if (face.landmarks[FaceLandmarkType.leftEye] != null)
      {
        'x': face.landmarks[FaceLandmarkType.leftEye]!.position.x / imageSize.width,
        'y': face.landmarks[FaceLandmarkType.leftEye]!.position.y / imageSize.height
      },
    if (face.landmarks[FaceLandmarkType.rightEye] != null)
      {
        'x': face.landmarks[FaceLandmarkType.rightEye]!.position.x / imageSize.width,
        'y': face.landmarks[FaceLandmarkType.rightEye]!.position.y / imageSize.height
      },
    if (face.landmarks[FaceLandmarkType.noseBase] != null)
      {
        'x': face.landmarks[FaceLandmarkType.noseBase]!.position.x / imageSize.width,
        'y': face.landmarks[FaceLandmarkType.noseBase]!.position.y / imageSize.height
      },
    if (face.landmarks[FaceLandmarkType.leftMouth] != null)
      {
        'x': face.landmarks[FaceLandmarkType.leftMouth]!.position.x / imageSize.width,
        'y': face.landmarks[FaceLandmarkType.leftMouth]!.position.y / imageSize.height
      },
    if (face.landmarks[FaceLandmarkType.rightMouth] != null)
      {
        'x': face.landmarks[FaceLandmarkType.rightMouth]!.position.x / imageSize.width,
        'y': face.landmarks[FaceLandmarkType.rightMouth]!.position.y / imageSize.height
      },
  ];
}





  /// ✅ **Convert Embeddings to Landmarks**
  List<Map<String, double>> _convertEmbeddingsToLandmarks(List<double> embeddings) {
    return List.generate(embeddings.length, (index) {
      return {'x': embeddings[index], 'y': embeddings[index]};
    });
  }

Future<void> _compareFace(List<Map<String, double>> detectedLandmarks) async {
  try {
    print("🔹 Captured Facial Landmarks: $detectedLandmarks");

    List<Map<String, dynamic>>? storedEmployees = await MongoDatabase.getData();
    if (storedEmployees.isEmpty) {
      setState(() => _resultMessage = "No face data found in database.");
      return;
    }

    bool matchFound = false;
    String matchedEmployeeName = "";
    double threshold = 600.0;

   double minDistance = double.infinity;
String bestMatch = "❌ No Match Found";

for (var employee in storedEmployees) {
  List<dynamic>? storedEmbeddingsRaw = employee['faceEmbeddings'];
  if (storedEmbeddingsRaw == null || storedEmbeddingsRaw.isEmpty) continue;

  List<Map<String, double>> storedEmbeddings = storedEmbeddingsRaw.map((e) {
    return {'x': (e['x'] as num).toDouble(), 'y': (e['y'] as num).toDouble()};
  }).toList();

  double totalDistance = _calculateDistance(detectedLandmarks, storedEmbeddings);
  print("Distance for ${employee['fullName']}: $totalDistance");

  // ✅ Update best match if this distance is the smallest
  if (totalDistance < minDistance) {
    minDistance = totalDistance;
    bestMatch = employee['fullName'];
  }
}


if (minDistance > threshold) {
  setState(() {
    _resultMessage = "❌ No Match Found";
  });
} else {
  setState(() {
    _resultMessage = "✅ Best Match: $bestMatch ($minDistance)";
  });
}


    setState(() {
      _resultMessage = matchFound ? "Match Found: $matchedEmployeeName" : "No Match Found";
      _faceDetected = matchFound;
    });
  } catch (e) {
    setState(() => _resultMessage = "Error accessing database: $e");
  }
}






bool _compareEmbeddings(List<double> detected, List<double> stored) {
  if (detected.length != stored.length) return false;

  double distance = 0.0;
  for (int i = 0; i < detected.length; i++) {
    distance += pow(detected[i] - stored[i], 2);
  }

  print("🔍 Comparing Face Data:");
  print("Detected Face: $detected");
  print("Stored Face: $stored");
  print("Calculated Distance: $distance");

  return distance < 0.3; // Face matching threshold
}


  /// ✅ **Simulated Stored Employees with Face Embeddings**
  List<Map<String, dynamic>> _getStoredEmployees() {
    return [
      {
        'fullName': "John Doe",
        'faceEmbeddings': List.generate(128, (index) => Random().nextDouble()), // Dummy embeddings
      },
      {
        'fullName': "Jane Smith",
        'faceEmbeddings': List.generate(128, (index) => Random().nextDouble()), // Dummy embeddings
      }
    ];
  }

  /// ✅ **Handle No Face Detected**
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
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
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
