import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  FlashMode _flashMode = FlashMode.off;
  CameraLensDirection _cameraDirection = CameraLensDirection.back;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Dispose the old controller if it exists before creating a new one.
    if (mounted && this.widget != null && _controller != null) {
        await _controller.dispose();
    }

    final cameras = await availableCameras();
    final camera = cameras.firstWhere(
        (c) => c.lensDirection == _cameraDirection,
        orElse: () => cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
    );

    // If the widget was removed from the tree while the camera was initializing,
    // we don't want to update the state.
    if (!mounted) {
      return;
    }
    
    return _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _capturePhoto() async {
    if (!_controller.value.isInitialized) {
      return;
    }
    try {
      final XFile file = await _controller.takePicture();
      // You can navigate to a new screen to display the photo.
      // For example:
      // Navigator.push(context, MaterialPageRoute(builder: (context) => DisplayPictureScreen(imagePath: file.path)));
    } catch (e) {
      print(e);
    }
  }

  void _toggleFlash() {
    if (!_controller.value.isInitialized) return;
    final newMode = _flashMode == FlashMode.off ? FlashMode.auto : FlashMode.off;
    _controller.setFlashMode(newMode).then((_) {
      if (mounted) {
        setState(() {
          _flashMode = newMode;
        });
      }
    });
  }

  void _switchCamera() {
    if (_controller.value.isInitialized) {
      setState(() {
        _cameraDirection = _cameraDirection == CameraLensDirection.back
            ? CameraLensDirection.front
            : CameraLensDirection.back;
        _initializeControllerFuture = _initializeCamera();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFlashButton(),
                      _buildCaptureButton(),
                      _buildCameraSwitchButton(),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildCaptureButton() {
    return IconButton(
      icon: Icon(Icons.camera_alt, color: Colors.white, size: 40),
      onPressed: _capturePhoto,
    );
  }

  Widget _buildFlashButton() {
    IconData icon = _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on;
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 30),
      onPressed: _toggleFlash,
    );
  }

  Widget _buildCameraSwitchButton() {
    return IconButton(
      icon: Icon(Icons.switch_camera, color: Colors.white, size: 30),
      onPressed: _switchCamera,
    );
  }
}
