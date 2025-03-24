import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class AddPerson extends StatefulWidget {
  const AddPerson({super.key});

  @override
  State<AddPerson> createState() => _AddPersonState();
}

class _AddPersonState extends State<AddPerson> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController employeeIdController = TextEditingController();

  CameraController? _cameraController;
  List<CameraDescription>? cameras;
  String? capturedImagePath;
  int selectedCameraIndex = 0;

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
      File imageFile = File(capturedImagePath!);

      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse("http://localhost:5000/api/register"),
        );
        request.fields['fullName'] = fullName;
        request.fields['employeeId'] = employeeId;
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ));

        var response = await request.send();
        if (response.statusCode == 200) {
          print("Registration successful");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Registration Successful")),
          );
        } else {
          print("Error: ${response.reasonPhrase}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${response.reasonPhrase}")),
          );
        }
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
        title: const Text("Face Registration"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_cameraController != null && _cameraController!.value.isInitialized && capturedImagePath == null)
                SizedBox(
                  height: 500,
                  child: CameraPreview(_cameraController!),
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
              if (capturedImagePath == null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _captureImage,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Capture Face"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.switch_camera),
                      label: const Text("Switch Camera"),
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
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      validator: validator,
    );
  }
}
