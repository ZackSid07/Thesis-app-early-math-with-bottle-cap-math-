import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import '../services/yolo_service.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late YoloService _yoloService;
  late FlutterTts _flutterTts;

  bool _isAnalyzing = false; // State for loading spinner
  String _feedbackMessage = "Align caps and press Check";
  Color _feedbackColor = Colors.white;

  // Speech Debounce State
  String _lastSpokenEquation = "";

  @override
  void initState() {
    super.initState();
    _yoloService = YoloService();
    _initializeCamera();
    _initTts();
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.max, // Changed to max for best detail
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize().then((_) async {
      await _controller.setFocusMode(FocusMode.auto);
      // Lock to portrait to ensure consistent orientation
      await _controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await _yoloService.loadModel();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _yoloService.close();
    super.dispose();
  }

  // --- Core Capture & Analyze Logic ---
  Future<void> _captureAndAnalyze() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _feedbackMessage = "Analyzing Equation...";
      _feedbackColor = Colors.blue;
    });

    try {
      // 0. Ensure Focus
      if (_controller.value.isInitialized) {
        await _controller.setFocusPoint(const Offset(0.5, 0.5));
        await Future.delayed(
            const Duration(milliseconds: 200)); // Brief settle time
      }

      // 1. Capture Image
      final XFile imageFile = await _controller.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // 2. Mock Analysis Delay (UX)
      await Future.delayed(const Duration(seconds: 2));

      // 3. Decode & Rotate Image
      // detected caps are "Vertical" in the image buffer (X constant, Y varies).
      // This means the image is rotated 90 degrees relative to the horizon.
      // We need to rotate it back to be "Horizontal" (Upright).
      // Attempting -90 rotation (Counter-Clockwise) first.

      // 3. Decode & Crop to Center Square
      final img.Image? capturedImage = img.decodeImage(imageBytes);
      if (capturedImage == null) throw Exception("Failed to decode image");

      // Calculate Square Crop
      int size = capturedImage.width < capturedImage.height
          ? capturedImage.width
          : capturedImage.height;
      int xOffset = (capturedImage.width - size) ~/ 2;
      int yOffset = (capturedImage.height - size) ~/ 2;

      final img.Image croppedImage = img.copyCrop(capturedImage,
          x: xOffset, y: yOffset, width: size, height: size);

      // Re-encode to pass to YOLO
      final Uint8List croppedBytes =
          Uint8List.fromList(img.encodeJpg(croppedImage));

      print("Cropped Image: ${croppedImage.width}x${croppedImage.height}");

      // 4. Run Inference on CROPPED bytes
      final detections = await _yoloService.runInferenceOnImage(
          croppedBytes, croppedImage.height, croppedImage.width);

      print("Raw Detections (Cropped): $detections");

      // 5. Process Results
      _processDetections(detections);
    } catch (e) {
      print("Error analyzing image: $e");
      setState(() {
        _feedbackMessage = "Error capturing image. Try again.";
        _feedbackColor = Colors.red;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _processDetections(List<Map<String, dynamic>> detections) {
    // 1. Filter Garbage & Normalize
    List<Map<String, dynamic>> validDetections = [];
    for (var det in detections) {
      String rawTag = det['tag'].toString();
      String? symbol;

      // Map labels to symbols
      if (rawTag == 'equal')
        symbol = '=';
      else if (rawTag == 'plus')
        symbol = '+';
      else if (rawTag == 'minus')
        symbol = '-';
      else if (rawTag == 'multiply')
        symbol = '*';
      else if (rawTag == 'divide')
        symbol = '/';
      else if (int.tryParse(rawTag) != null) symbol = rawTag;

      if (symbol != null) {
        validDetections.add({
          'symbol': symbol,
          'box': det['box'], // [x1, y1, x2, y2, confidence]
          'confidence': det['box'][4] ?? 0.0,
        });
      }
    }

    if (validDetections.isEmpty) {
      _updateFeedback("No bottle caps found! Try again.", Colors.orange);
      return;
    }

    // 2. Sort by X-Axis (Left-to-Right)
    validDetections.sort((a, b) {
      double centerA = (a['box'][0] + a['box'][2]) / 2;
      double centerB = (b['box'][0] + b['box'][2]) / 2;
      return centerA.compareTo(centerB);
    });

    // 3. Dedupe (Remove overlaps)
    // Use dynamic threshold based on box width (e.g., 50%)
    List<Map<String, dynamic>> uniqueDetections = [];
    for (var current in validDetections) {
      bool isDuplicate = false;
      double widthA = (current['box'][2] - current['box'][0]).abs();
      double threshold = widthA * 0.5; // 50% of width overlap

      for (var existing in uniqueDetections) {
        double centerA = (current['box'][0] + current['box'][2]) / 2;
        double centerB = (existing['box'][0] + existing['box'][2]) / 2;

        if ((centerA - centerB).abs() < threshold) {
          if (current['confidence'] > existing['confidence']) {
            uniqueDetections.remove(existing);
            uniqueDetections.add(current);
          } else {
            isDuplicate = true; // existing is better
          }
          break;
        }
      }
      if (!isDuplicate) {
        uniqueDetections.add(current);
      }
    }
    // Re-sort unique by X
    uniqueDetections.sort((a, b) {
      double centerA = (a['box'][0] + a['box'][2]) / 2;
      double centerB = (b['box'][0] + b['box'][2]) / 2;
      return centerA.compareTo(centerB);
    });

    // 4. Construct Equation
    StringBuffer equationBuffer = StringBuffer();
    for (var det in uniqueDetections) {
      equationBuffer.write(det['symbol']);
    }
    String equation = equationBuffer.toString();
    print("Sorted Equation: $equation");

    // 5. Strict Validation
    if (equation.contains('=')) {
      List<String> parts = equation.split('=');
      String leftSide = parts[0];
      String rightSide = parts.length > 1 ? parts[1] : "";

      String? op;
      if (leftSide.contains('+'))
        op = '+';
      else if (leftSide.contains('-'))
        op = '-';
      else if (leftSide.contains('*'))
        op = '*';
      else if (leftSide.contains('/')) op = '/';

      if (op != null) {
        List<String> operands = leftSide.split(op);
        // Clean empty parts from split
        operands.removeWhere((s) => s.isEmpty);

        if (operands.length >= 2) {
          if (rightSide.isEmpty) {
            _updateFeedback("Missing answer cap after '='", Colors.orange);
          } else {
            try {
              int num1 = int.parse(operands[0]);
              int num2 = int.parse(operands[1]);
              int detectedAnswer = int.parse(rightSide);

              int calculatedResult = 0;
              switch (op) {
                case '+':
                  calculatedResult = num1 + num2;
                  break;
                case '-':
                  calculatedResult = num1 - num2;
                  break;
                case '*':
                  calculatedResult = num1 * num2;
                  break;
                case '/':
                  calculatedResult = (num1 / num2).round();
                  break;
              }

              if (calculatedResult == detectedAnswer) {
                _updateFeedback("Correct! $num1 $op $num2 = $calculatedResult",
                    _colorSuccess);
                _speakResult(num1, op, num2, detectedAnswer);
              } else {
                _updateFeedback(
                    "Incorrect. $num1 $op $num2 is NOT $detectedAnswer",
                    Colors.red);
                _flutterTts.speak("Oops! That is not correct.");
              }
            } catch (e) {
              _updateFeedback(
                  "Could not parse number (Read: $equation)", Colors.red);
            }
          }
        } else {
          _updateFeedback(
              "Invalid equation format (Read: $equation).", Colors.red);
        }
      } else {
        _updateFeedback("No operator found (Read: $equation).", Colors.red);
      }
    } else {
      _updateFeedback("No equals sign found (Read: $equation).", Colors.orange);
    }
  }

  void _speakResult(int n1, String op, int n2, int res) async {
    String opText;
    switch (op) {
      case '+':
        opText = "plus";
        break;
      case '-':
        opText = "minus";
        break;
      case '*':
        opText = "times";
        break;
      case '/':
        opText = "divided by";
        break;
      default:
        opText = "";
    }
    await _flutterTts.speak("Correct! $n1 $opText $n2 equals $res!");
  }

  void _updateFeedback(String msg, Color color) {
    if (mounted) {
      setState(() {
        _feedbackMessage = msg;
        _feedbackColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Snap & Solve")),
      body: Column(
        children: [
          // 1. Camera Preview
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_controller),
                      // Guide Overlay
                      Center(
                          child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                                color: Colors.white.withOpacity(0.5), width: 2),
                          ),
                        ),
                      )),
                      if (_isAnalyzing)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),

          // 2. Feedback Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: _feedbackColor,
            child: Text(
              _feedbackMessage,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 3. Capture Button
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            child: Center(
              child: SizedBox(
                width: 80,
                height: 80,
                child: FloatingActionButton(
                  onPressed: _isAnalyzing ? null : _captureAndAnalyze,
                  backgroundColor: _isAnalyzing ? Colors.grey : Colors.blue,
                  child: const Icon(Icons.camera_alt, size: 40),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

const Color _colorSuccess = Color(0xFF4CAF50);
