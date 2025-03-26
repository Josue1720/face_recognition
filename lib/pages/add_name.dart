import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:face_recognition/config/mongoservice.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io'; // Import the dart:io package
import '/pages/display.dart';

class TestAdd extends StatefulWidget {
  const TestAdd({super.key});

  @override
  State<TestAdd> createState() => _TestAddState();
}

class _TestAddState extends State<TestAdd> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController employeeIdController = TextEditingController();

  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  String? capturedImagePath;
  int selectedCameraIndex = 0; // Store selected camera index (0 = back, 1 = front)

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
          cameras![cameraIndex], // Select camera by index
          ResolutionPreset.high,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        await _cameraController!.initialize();
        setState(() {});
      } else {
        print("No cameras available");
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.isEmpty) return;

    selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length; // Toggle between cameras
    await _initializeCamera(selectedCameraIndex);
  }

  Future<void> _captureImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final image = await _cameraController!.takePicture();
        setState(() {
          capturedImagePath = image.path;
        });
        print("Image captured: ${image.path}");
      } catch (e) {
        print("Error capturing image: $e");
      }
    } else {
      print("Camera is not initialized");
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (capturedImagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please capture a face image")),
        );
        return;
      }

      String fullName = fullNameController.text;
      String employeeId = employeeIdController.text;

      try {
        // Detect face and extract embeddings
        final inputImage = InputImage.fromFilePath(capturedImagePath!);
       final faceDetector = GoogleMlKit.vision.faceDetector(
  FaceDetectorOptions(
    enableLandmarks: true,  // Enable landmark detection
    enableContours: true,   // Enable facial contour detection
    performanceMode: FaceDetectorMode.accurate, // Use accurate mode
  ),
);

        final faces = await faceDetector.processImage(inputImage);

        if (faces.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No face detected in the image")),
          );
          return;
        }

        final face = faces.first;
       final faceEmbeddings = face.landmarks.entries
    .where((entry) => entry.value != null) // Filter out null landmarks
    .map((entry) => {
      'type': entry.key.toString(),
      'x': entry.value!.position.x,  // Use `!` to ensure non-null values
      'y': entry.value!.position.y
    }).toList();


        // Save registration details and embeddings to MongoDB
        await MongoDatabase.insertData({
          'fullName': fullName,
          'employeeId': employeeId,
          'imagePath': capturedImagePath,
          'faceEmbeddings': faceEmbeddings,
          'timestamp': DateTime.now().toIso8601String(),
        });

        print("Registered: $fullName ($employeeId)");
        print("Image Path: $capturedImagePath");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful")),
        );

        // Delay navigation until after the SnackBar shows
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Display()),
          );
        });
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Face Registration" , style: TextStyle(color: Colors.white),),
        backgroundColor: const Color(0xFF3D9260),
         centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_cameraController != null && _cameraController!.value.isInitialized && capturedImagePath == null)
                Stack(
                  children: [
                    SizedBox(
                      height: 500,
                      child: CameraPreview(_cameraController!),
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
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else if (capturedImagePath != null)
                Column(
                  children: [
                    Image.file(
                      File(capturedImagePath!),
                      height: 300,
                    ),
                    const SizedBox(height: 10),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: fullNameController,
                            label: "Full Name",
                            validator: (value) => value!.isEmpty ? "Enter Full Name" : null,
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: employeeIdController,
                            label: "Employee ID",
                            validator: (value) => value!.isEmpty ? "Enter Employee ID" : null,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  const SizedBox(width: 10),
                  if (capturedImagePath == null)
                    ElevatedButton.icon(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.switch_camera),
                      label: const Text("Switch Camera"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (capturedImagePath != null)
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
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
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
        ),
        validator: validator,
      ),
    );
  }
}