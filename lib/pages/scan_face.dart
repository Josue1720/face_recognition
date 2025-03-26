import 'package:flutter/material.dart';
import 'package:face_camera/face_camera.dart';

class ScanFaceScreen extends StatefulWidget {
  @override
  _ScanFaceScreenState createState() => _ScanFaceScreenState();
}

class _ScanFaceScreenState extends State<ScanFaceScreen> {
  late FaceCameraController _controller;
  bool _isCameraReady = false;
  bool _faceDetected = false;
  String _resultMessage = "Center your face in the frame";
  int _noFaceCounter = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
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
            if (face != null && face.boundingBox != null) {
              bool isFaceProperlyAligned = face.boundingBox.width > 50;
              if (isFaceProperlyAligned) {
                setState(() {
                  _faceDetected = true;
                  _noFaceCounter = 0;
                  _resultMessage = "Face in Camera";
                });
              } else {
                _handleNoFaceDetected();
              }
            } else {
              _handleNoFaceDetected();
            }
          },
          onCapture: (file) {},
        );
      });
    } catch (e) {
      setState(() {
        _isCameraReady = false;
        _resultMessage = "Error: No Camera Detected";
      });
    }
  }

  void _handleNoFaceDetected() {
    _noFaceCounter++;
    if (_noFaceCounter >= 5) {
      setState(() {
        _faceDetected = false;
        _resultMessage = "No Face Detected";
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (!_faceDetected) {
          setState(() {
            _resultMessage = "Center your face in the frame";
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Real-Time Face Detection")),
      body: _isCameraReady
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0), // Flip horizontally
                    child: SmartFaceCamera(
                      controller: _controller,
                      
                    ),
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
