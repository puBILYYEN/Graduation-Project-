import 'package:flutter/material.dart';

class CameraControls extends StatelessWidget {
  final bool isTablet;
  final bool isLandscape;
  final double iconRotation;
  final bool isFlashOn;
  final VoidCallback onFlashToggle;
  final VoidCallback onGalleryTap;
  final VoidCallback onCaptureTap;
  final VoidCallback onSwitchCameraTap;

  const CameraControls({
    Key? key,
    required this.isTablet,
    required this.isLandscape,
    required this.iconRotation,
    required this.isFlashOn,
    required this.onFlashToggle,
    required this.onGalleryTap,
    required this.onCaptureTap,
    required this.onSwitchCameraTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: 10,
            top: isLandscape ? 10 : 20,
            left: 20,
            right: 20,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGalleryButton(),
              _buildCaptureButton(),
              _buildSwitchCameraButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryButton() {
    return GestureDetector(
      onTap: onGalleryTap,
      child: RotatedBox(
        quarterTurns: isLandscape ? 1 : 0,
        child: Icon(
          Icons.photo,
          color: Colors.white,
          size: isTablet ? 32 : 24,
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: onCaptureTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.camera,
            color: Colors.black,
            size: isTablet ? 32 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCameraButton() {
    return GestureDetector(
      onTap: onSwitchCameraTap,
      child: RotatedBox(
        quarterTurns: isLandscape ? 1 : 0,
        child: Icon(
          Icons.switch_camera,
          color: Colors.white,
          size: isTablet ? 32 : 24,
        ),
      ),
    );
  }
}
