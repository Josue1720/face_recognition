import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:face_recognition/config/mongoservice.dart';
import 'dart:io';
import '/pages/display.dart';
import '/config/facerecognitionservice.dart'; 
import 'package:image/image.dart' as img;
import 'package:google_ml_kit/google_ml_kit.dart';


class RegisterUser extends StatefulWidget {
  const RegisterUser({super.key});

  @override
  State<RegisterUser> createState() => _TestAddState();
}

class _TestAddState extends State<RegisterUser> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final employeeIdController = TextEditingController();

  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  String? capturedImagePath;
  int selectedCameraIndex = 1; // Default to front camera
  FaceRecognitionService faceRecognitionService = FaceRecognitionService();
   
  @override
  void initState() {
    super.initState();
    _initializeCamera(selectedCameraIndex);
  }

Future<File> resizeImage(File imageFile) async {
  final bytes = await imageFile.readAsBytes();
  img.Image? image = img.decodeImage(bytes);

  if (image == null) {
    throw Exception("Error decoding image");
  }

  // Ensure the image is in RGB format (removes alpha if present)
  img.Image rgbImage = img.bakeOrientation(image);
  rgbImage = img.copyResize(rgbImage, width: 112, height: 112);

  // Ensure it's strictly RGB (drops alpha channel)
  if (rgbImage.channels == 4) {
    rgbImage = img.copyCrop(rgbImage, 0, 0, rgbImage.width, rgbImage.height);
  }

  // Save the resized image
  final resizedFile = File(imageFile.path.replaceFirst('.jpg', '_resized.jpg'))
    ..writeAsBytesSync(img.encodeJpg(rgbImage));

  return resizedFile;
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


Future<File> cropFace(File imageFile) async {
  final inputImage = InputImage.fromFilePath(imageFile.path);

  //Uses face detector
  final faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableTracking: false,
    ),
  );

  //detect face in pciture
  final List<Face> faces = await faceDetector.processImage(inputImage);

  if (faces.isEmpty) {
    throw Exception("No face detected");
  }

  // Get the bounding box for the first face
  final face = faces[0];
  final Rect boundingBox = face.boundingBox;

  // Open the image file and decode it
  final bytes = await imageFile.readAsBytes();
  img.Image? image = img.decodeImage(bytes);

  if (image == null) {
    throw Exception("Error decoding image");
  }

  // Crop the face from the image using the bounding box
  final croppedImage = img.copyCrop(
    image,
    boundingBox.left.toInt(),
    boundingBox.top.toInt(),
    boundingBox.width.toInt(),
    boundingBox.height.toInt(),
  );

  // Save the cropped image
  final croppedFile = File(imageFile.path.replaceFirst('.jpg', '_cropped.jpg'))
    ..writeAsBytesSync(img.encodeJpg(croppedImage));

  return croppedFile;
}

Future<File> cropAndResizeFace(File imageFile) async {
  final inputImage = InputImage.fromFilePath(imageFile.path);

  // Initialize the face detector
  final faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableTracking: false,
    ),
  );

  // Detect faces in the image
  final List<Face> faces = await faceDetector.processImage(inputImage);

  if (faces.isEmpty) {
    throw Exception("No face detected");
  }

  // Get the bounding box for the first face
  final face = faces[0];
  final Rect boundingBox = face.boundingBox;

  // Open the image file and decode it
  final bytes = await imageFile.readAsBytes();
  img.Image? image = img.decodeImage(bytes);

  if (image == null) {
    throw Exception("Error decoding image");
  }

  // Crop the face from the image using the bounding box
  final croppedImage = img.copyCrop(
    image,
    boundingBox.left.toInt(),
    boundingBox.top.toInt(),
    boundingBox.width.toInt(),
    boundingBox.height.toInt(),
  );

  // Resize the cropped image to 112x112
  img.Image resizedImage = img.copyResize(croppedImage, width: 112, height: 112);

  // Save the resized cropped image
  final croppedFile = File(imageFile.path.replaceFirst('.jpg', '_cropped_resized.jpg'))
    ..writeAsBytesSync(img.encodeJpg(resizedImage));

  return croppedFile;
}


Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;
  if (capturedImagePath == null) {
    _showSnackBar("Please capture a face image");
    return;
  }

  try {
    // Crop imag
    File croppedResizedImageFile = await cropAndResizeFace(File(capturedImagePath!));

    // Decode the cropped and resized image
    final bytes = await croppedResizedImageFile.readAsBytes();
    img.Image? croppedResizedImage = img.decodeImage(bytes);

    if (croppedResizedImage == null) {
      throw Exception("Error decoding cropped and resized image");
    }

    // Convert image pixels to a normalized list of floats (RGB values between -1 and 1)
    List<double> imagePixels = [];
    for (int y = 0; y < croppedResizedImage.height; y++) {
      for (int x = 0; x < croppedResizedImage.width; x++) {
        int pixel = croppedResizedImage.getPixel(x, y);
        imagePixels.add((((pixel >> 16) & 0xFF) / 255.0 - 0.5) * 2.0); // Red
        imagePixels.add((((pixel >> 8) & 0xFF) / 255.0 - 0.5) * 2.0);  // Green
        imagePixels.add(((pixel & 0xFF) / 255.0 - 0.5) * 2.0);         // Blue
      }
    }

    // Debugging: Ensure the length of imagePixels is correct
    print("Cropped and Resized Image Pixel Length: ${imagePixels.length}");

    // Generate embeddings using the flat list of image pixels
    final faceEmbedding = faceRecognitionService.getFaceEmbeddingFromPixels(imagePixels);

    print("Face Embedding: $faceEmbedding");

    // Parse employee ID
    int? employeeId;
    try {
      employeeId = int.parse(employeeIdController.text);
    } catch (e) {
      _showSnackBar("Invalid Employee ID. Please enter a number.");
      return;
    }

    // Store the embeddings and employee details in MongoDB
    await MongoDatabase.insertData({
      'fullName': fullNameController.text,
      'employeeId': employeeId,
      'imagePath': croppedResizedImageFile.path,
      'faceEmbedding': faceEmbedding, // Store 192-d face embedding
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Show success message and navigate to Display page
    _showSnackBar("Registration Successful");
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Display()));
    });
  } catch (e) {
    // Handle errors
    _showSnackBar("Error: $e");
    print("Error: $e");
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
      icon: const Icon(Icons.camera_alt, color: Colors.white),
      label: const Text("Capture Face", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // rectangular
        ),
      ),
    ),
  const SizedBox(width: 10),
  if (capturedImagePath == null)
    ElevatedButton.icon(
      onPressed: _switchCamera,
      icon: const Icon(Icons.switch_camera, color: Colors.white),
      label: const Text("Switch", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // rectangular
        ),
      ),
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
