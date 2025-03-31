import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:face_recognition/config/mongoservice.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import '/pages/display.dart';

class TestAdd extends StatefulWidget {
  const TestAdd({super.key});

  @override
  State<TestAdd> createState() => _TestAddState();
}

class _TestAddState extends State<TestAdd> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final employeeIdController = TextEditingController();

  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  String? capturedImagePath;
  int selectedCameraIndex = 1; // Default to front camera

  @override
  void initState() {
    super.initState();
    _initializeCamera(selectedCameraIndex);
  }

  Future<void> _initializeCamera(int cameraIndex) async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        _cameraController = CameraController(
          cameras![cameraIndex],
          ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        await _cameraController!.initialize();
        setState(() {});
      } else {
        debugPrint("No cameras available");
      }
    } catch (e) {
      debugPrint("Camera error: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length;
    await _initializeCamera(selectedCameraIndex);
  }

  Future<void> _captureImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final image = await _cameraController!.takePicture();
        setState(() {
          capturedImagePath = image.path;
        });
      } catch (e) {
        debugPrint("Capture error: $e");
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (capturedImagePath == null) {
      _showSnackBar("Please capture a face image");
      return;
    }

    try {
      final inputImage = InputImage.fromFilePath(capturedImagePath!);
      final faceDetector = GoogleMlKit.vision.faceDetector(
        FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _showSnackBar("No face detected. Please retake.");
        return;
      }

      final face = faces.first;
 final faceEmbeddings = face.landmarks.entries
    .where((entry) => entry.value != null)
    .map((entry) => {
          'type': entry.key.toString(),
          'x': entry.value!.position.x,
          'y': entry.value!.position.y,
        })
    .toList();

await MongoDatabase.insertData({
  'fullName': fullNameController.text,
  'employeeId': employeeIdController.text,
  'imagePath': capturedImagePath,
  'faceEmbeddings': faceEmbeddings, // Store raw landmarks
  'timestamp': DateTime.now().toIso8601String(),
});

      _showSnackBar("Registration Successful");

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Display()),
        );
      });
    } catch (e) {
      _showSnackBar("Error: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    fullNameController.dispose();
    employeeIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isFrontCamera = selectedCameraIndex == 1; // Check if front camera is used

    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Registration", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3D9260),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_cameraController != null &&
                  _cameraController!.value.isInitialized &&
                  capturedImagePath == null)
                Stack(
                  children: [
                    SizedBox(
                      height: 500,
                      child: Transform.scale(
                        scaleX: isFrontCamera ? -1 : 1, // Flip the preview for front camera
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 150,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else if (capturedImagePath != null)
                Column(
                  children: [
                    Transform(
                      alignment: Alignment.center,
                      transform: isFrontCamera ? Matrix4.rotationY(math.pi) : Matrix4.identity(),
                      child: Image.file(File(capturedImagePath!), height: 300),
                    ),
                    const SizedBox(height: 10),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: fullNameController,
                            label: "Full Name",
                            validator: (value) =>
                                value!.isEmpty ? "Enter Full Name" : null,
                          ),
                          _buildTextField(
                            controller: employeeIdController,
                            label: "Employee ID",
                            validator: (value) =>
                                value!.isEmpty ? "Enter Employee ID" : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const Text("Camera not available"),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (capturedImagePath == null)
                    ElevatedButton.icon(
                      onPressed: _captureImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Capture Face"),
                    ),
                  const SizedBox(width: 10),
                  if (capturedImagePath == null)
                    ElevatedButton.icon(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.switch_camera),
                      label: const Text("Switch"),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (capturedImagePath != null)
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text("Register"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        validator: validator,
      ),
    );
  }
}
