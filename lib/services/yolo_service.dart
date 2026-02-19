import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';

class YoloService {
  late FlutterVision vision;
  bool _isLoaded = false;

  YoloService() {
    vision = FlutterVision();
  }

  Future<void> loadModel() async {
    if (_isLoaded) return;
    await vision.loadYoloModel(
      labels: 'assets/models/labels.txt',
      modelPath: 'assets/models/best_float32.tflite',
      modelVersion: "yolov8", // Adjust if using different YOLO version
      quantization: false,
      numThreads: 1,
      useGpu: false,
    );
    _isLoaded = true;
  }

  Future<List<Map<String, dynamic>>> runInference(CameraImage image) async {
    if (!_isLoaded) return [];

    // Debug input dimensions
    // print("Inference on frame: ${image.width}x${image.height}, format: ${image.format.group}");

    final result = await vision.yoloOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.4,
      confThreshold: 0.35,
      classThreshold: 0.35,
    );

    return result;
  }

  Future<List<Map<String, dynamic>>> runInferenceOnImage(
      Uint8List imageBytes, int height, int width) async {
    if (!_isLoaded) return [];

    final result = await vision.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: height,
        imageWidth: width,
        iouThreshold: 0.4,
        confThreshold: 0.25, // Lowered to 0.25
        classThreshold: 0.25);

    return result;
  }

  Future<void> close() async {
    if (_isLoaded) {
      await vision.closeYoloModel();
      _isLoaded = false;
    }
  }
}
