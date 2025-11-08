import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/models/measurement.dart';

class CameraControls extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onSwitchCamera;
  final VoidCallback onGallery;
  final MeasurementMethod currentMethod;
  final Function(MeasurementMethod) onMethodChanged;

  const CameraControls({
    Key? key,
    required this.onCapture,
    required this.onSwitchCamera,
    required this.onGallery,
    required this.currentMethod,
    required this.onMethodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMethodSelector(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.switch_camera),
                  color: Colors.white,
                  onPressed: onSwitchCamera,
                ),
                FloatingActionButton(
                  onPressed: onCapture,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.camera, color: Colors.black),
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library),
                  color: Colors.white,
                  onPressed: onGallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var method in MeasurementMethod.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ChoiceChip(
              label: Text(
                method.toString().split('.').last,
                style: TextStyle(
                  color: currentMethod == method ? Colors.black : Colors.white,
                ),
              ),
              selected: currentMethod == method,
              selectedColor: Colors.white,
              backgroundColor: Colors.black45,
              onSelected: (selected) {
                if (selected) {
                  onMethodChanged(method);
                }
              },
            ),
          ),
      ],
    );
  }
}