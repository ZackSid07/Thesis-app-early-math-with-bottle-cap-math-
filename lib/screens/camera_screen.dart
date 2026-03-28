import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../services/yolo_service.dart';
import '../theme/app_theme.dart';
import 'hint_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final LevelData? targetLevel;
  final bool isPracticeMode;

  const CameraScreen({
    Key? key,
    required this.cameras,
    this.targetLevel,
    this.isPracticeMode = false,
  }) : super(key: key);

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

  // Repeated Mistake Tracking

  int consecutiveMistakes = 0;

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
      _processDetections(detections, imageBytes);
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

  void _processDetections(
      List<Map<String, dynamic>> detections, Uint8List capturedImageBytes) {
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
            String aiExplanation =
                "We need one more number to finish the puzzle!";
            _flutterTts.speak(
                "Hmm, I think we are missing the answer after the equals sign. $aiExplanation");
            _controller.pausePreview();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HintScreen(
                  childsEquation: "$leftSide ?",
                  correctEquation: "",
                  correctAnswer: "?",
                  aiExplanation: aiExplanation,
                ),
              ),
            ).then((_) {
              _controller.resumePreview();
            });
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

              // --- Target Level Evaluation ---
              if (widget.isPracticeMode) {
                // --- Practice Mode Evaluation ---
                if (calculatedResult == detectedAnswer) {
                  // Success!
                  consecutiveMistakes = 0;

                  _updateFeedback(
                      "Correct! $num1 $op $num2 = $calculatedResult",
                      _colorSuccess);
                  _speakResult(num1, op ?? "", num2, detectedAnswer);

                  _showSuccessModal(capturedImageBytes,
                      "$num1 $op $num2 = $calculatedResult");
                } else {
                  // Mismatch: Build correct string to pass to Gemini
                  String expectedEqu = "$num1 $op $num2 = $calculatedResult";
                  _handleIncorrectAnswer(
                      num1, op, num2, detectedAnswer, calculatedResult,
                      expectedEquation: expectedEqu);
                }
              } else if (widget.targetLevel != null) {
                // --- Course Curriculum Mode ---
                String expectedEq = widget.targetLevel!.expectedEquation;
                
                String targetLeftSide = expectedEq.split('=')[0].replaceAll(' ', '');
                String detectedLeftSide = "$num1$op$num2".replaceAll(' ', '');
                
                if (detectedLeftSide != targetLeftSide) {
                  String displayTargetLeft = expectedEq.split('=')[0].trim();
                  String msg = "Oops! Build this equation: $displayTargetLeft = ?";
                  
                  _updateFeedback(msg, Colors.orange);
                  _flutterTts.speak("Oops! Please build $displayTargetLeft equals question mark.");
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      )
                    );
                  }
                  return;
                }

                String fullDetectedStr = "$num1 + $num2 = $detectedAnswer";
                if (op == '-') {
                  fullDetectedStr = "$num1 - $num2 = $detectedAnswer";
                } else if (op == '*') {
                  fullDetectedStr = "$num1 * $num2 = $detectedAnswer";
                } else if (op == '/') {
                  fullDetectedStr = "$num1 / $num2 = $detectedAnswer";
                }

                if (fullDetectedStr == expectedEq) {
                  // Perfect Match Against Target!
                  consecutiveMistakes = 0;

                  _updateFeedback("Correct! $fullDetectedStr", _colorSuccess);
                  _speakResult(num1, op, num2, detectedAnswer);

                  // Show the success modal
                  _showSuccessModal(capturedImageBytes, fullDetectedStr);
                } else {
                  // Incorrect for the Target Level.
                  _handleIncorrectAnswer(
                      num1, op, num2, detectedAnswer, calculatedResult,
                      expectedEquation: widget.targetLevel!.expectedEquation);
                }
              } else {
                // --- Free Play Validation Mode (Legacy) ---
                if (calculatedResult == detectedAnswer) {
                  // Reset mistake counter on correct answer
                  consecutiveMistakes = 0;

                  _updateFeedback(
                      "Correct! $num1 $op $num2 = $calculatedResult",
                      _colorSuccess);
                  _speakResult(num1, op!, num2, detectedAnswer);

                  // Show the success modal
                  _showSuccessModal(capturedImageBytes,
                      "$num1 $op $num2 = $calculatedResult");
                } else {
                  _handleIncorrectAnswer(
                      num1, op, num2, detectedAnswer, calculatedResult);
                }
              }
            } catch (e) {
              _updateFeedback(
                  "Could not parse number (Read: $equation)", Colors.red);
            }
          }
        } else {
          // If we don't have 2 numbers around the operator
          if (operands.isEmpty || leftSide.startsWith(op)) {
            _updateFeedback("Missing first number before '$op'", Colors.orange);
            String aiMsg = "We need a number to start our math problem!";
            _flutterTts
                .speak("I don't see a number before the $op sign. $aiMsg");
            _controller.pausePreview();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HintScreen(
                  childsEquation: equation,
                  correctEquation: "",
                  correctAnswer: "?",
                  aiExplanation: aiMsg,
                ),
              ),
            ).then((_) {
              _controller.resumePreview();
            });
          } else {
            _updateFeedback("Missing second number after '$op'", Colors.orange);
            String aiMsg = "We need another number to add or subtract!";
            _flutterTts
                .speak("I don't see a number after the $op sign. $aiMsg");
            _controller.pausePreview();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HintScreen(
                  childsEquation: equation,
                  correctEquation: "",
                  correctAnswer: "?",
                  aiExplanation: aiMsg,
                ),
              ),
            ).then((_) {
              _controller.resumePreview();
            });
          }
        }
      } else {
        _updateFeedback("No operator found (Read: $equation).", Colors.red);
        String aiExplanation =
            "We need an operator like plus or minus to do math!";
        _flutterTts.speak(
            "I don't see a plus or minus sign. Can you add one? $aiExplanation");
        _controller.pausePreview();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HintScreen(
              childsEquation: equation,
              correctEquation: "",
              correctAnswer: "+ or -",
              aiExplanation: aiExplanation,
            ),
          ),
        ).then((_) {
          _controller.resumePreview();
        });
      }
    } else {
      _updateFeedback("No equals sign found (Read: $equation).", Colors.orange);
      String aiExplanation =
          "An equation needs an equals sign to show the answer.";
      _flutterTts.speak("Don't forget the equals sign! $aiExplanation");
      _controller.pausePreview();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HintScreen(
            childsEquation: equation,
            correctEquation: "",
            correctAnswer: "=",
            aiExplanation: aiExplanation,
          ),
        ),
      ).then((_) {
        _controller.resumePreview();
      });
    }
  }

  void _handleIncorrectAnswer(
      int num1, String? op, int num2, int detectedAnswer, int calculatedResult,
      {String? expectedEquation}) {
    String currentWrongEq = "$num1 $op $num2 = $detectedAnswer";
    String actualCorrectEq = expectedEquation ?? "$num1 $op $num2 = $calculatedResult";

    consecutiveMistakes++;

    _updateFeedback(
        "Incorrect. $num1 $op $num2 is NOT $detectedAnswer", Colors.red);

    if (consecutiveMistakes < 2) {
      _flutterTts.speak("Not quite! Try one more time.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Not quite! Try one more time.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } else {
      consecutiveMistakes = 0;
      _controller.pausePreview();
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HintScreen(
            childsEquation: currentWrongEq,
            correctEquation: actualCorrectEq,
          ),
        ),
      ).then((_) {
        _controller.resumePreview();
        _updateFeedback("Align caps and press Check", Colors.white);
      });
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

  String _getDynamicEquation() {
    if (widget.targetLevel != null) {
      final eq = widget.targetLevel!.expectedEquation;
      final parts = eq.split('=');
      if (parts.length == 2) {
        return "${parts[0].trim()} = ?";
      }
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback underlying color
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. Camera Preview
                CameraPreview(_controller),

                // 2. Full-screen UI Overlay
                Column(
                  children: [
                    // Top Section inside SafeArea
                    SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new,
                                      color: AppTheme.primaryBlue, size: 28),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Text(
                                  "BOTTLE CAP MATH",
                                  style: TextStyle(
                                    color: AppTheme.primaryBlue,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.volume_up,
                                      color: AppTheme.primaryBlue, size: 32),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),

                          // Math Question Box
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 8.0),
                            padding: const EdgeInsets.symmetric(
                                vertical: 24.0, horizontal: 24.0),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(0, 8),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Center(
                              child: widget.isPracticeMode
                                  ? const Text(
                                      "Practice Mode: Free Play!",
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    )
                                  : RichText(
                                      text: TextSpan(
                                        children: [
                                          const TextSpan(
                                            text: "Solve: ",
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: Color(
                                                  0xFF1E293B), // Dark navy
                                            ),
                                          ),
                                          TextSpan(
                                            text: _getDynamicEquation(),
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),

                          // Feedback Banner Overlay
                          if (_feedbackMessage.isNotEmpty &&
                              _feedbackMessage != "Align caps and press Check")
                            Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 8.0),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _feedbackColor == Colors.white
                                    ? AppTheme.warningOrange
                                    : _feedbackColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _feedbackMessage,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Middle Fill
                    const Spacer(),

                    // Bottom Section
                    SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Mascot & Speech Bubble
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 24.0, bottom: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(
                                      bottom: 20, right: 12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryBlue.withOpacity(0.9),
                                    borderRadius:
                                        BorderRadius.circular(20).copyWith(
                                      bottomRight: const Radius.circular(0),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    "What's the answer?",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: Colors.white, width: 4),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.smart_toy,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // SNAP Button
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 24.0, right: 24.0, bottom: 24.0),
                            child: InkWell(
                              onTap: () {
                                if (!_isAnalyzing) {
                                  _captureAndAnalyze();
                                }
                              },
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _isAnalyzing
                                      ? Colors.grey
                                      : AppTheme.successGreen,
                                  borderRadius: BorderRadius.circular(50),
                                  border:
                                      Border.all(color: Colors.white, width: 5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 8),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt,
                                        color: Colors.white, size: 36),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isAnalyzing ? "ANALYZING..." : "SNAP",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 3. Center Guide Pill (Exactly centered in Stack)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text(
                      "Line up your answer here!",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                // Blocking overlay
                if (_isAnalyzing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void _showSuccessModal(Uint8List imageBytes, String equationStr) {
    // Keep the camera paused while in the success screen
    _controller.pausePreview();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          // Allow it to span most of the height
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // Header
              const Text(
                "You did it!",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Great job solving the puzzle!",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Photo Card with Checkmark Overlay
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(0, 8),
                            blurRadius: 16,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Large Green Checkmark Badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: AppTheme.successGreen,
                        size: 80,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Equation Row mapping
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: equationStr.split(' ').map((char) {
                    if (char.isEmpty) return const SizedBox.shrink();

                    CapType type;
                    if (char == '=') {
                      type = CapType.equals;
                    } else if (char == '+' ||
                        char == '-' ||
                        char == '*' ||
                        char == '/') {
                      type = CapType.operator;
                    } else {
                      type = CapType.number;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: BottleCapWidget(text: char, type: type, size: 40),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 40),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ToyButton(
                  text: "Next Puzzle \u2192", // Right Arrow Unicode
                  color: AppTheme.primaryBlue,
                  onPressed: () {
                    Navigator.pop(context); // Close modal

                    if (widget.isPracticeMode) {
                      // Practice Mode Retry (Stay on Camera)
                      setState(() {
                        _feedbackMessage = "Align caps and press Check";
                        _feedbackColor = Colors.white;
                      });
                      _controller.resumePreview();
                    } else if (widget.targetLevel != null) {
                      // Mark Complete and Return to Map
                      Provider.of<CourseProvider>(context, listen: false)
                          .completeCurrentLevel(
                              widget.targetLevel!.levelNumber);
                      if (mounted) {
                        Navigator.pop(context); // Go back to Course Map
                      }
                    } else {
                      // Free Play Retry (Legacy)
                      setState(() {
                        _feedbackMessage = "Align caps and press Check";
                        _feedbackColor = Colors.white;
                      });
                      _controller.resumePreview();
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    ).then((_) {
      // If modal dismissed by swiping down, ensure camera resumes
      _controller.resumePreview();
      setState(() {
        _feedbackMessage = "Align caps and press Check";
        _feedbackColor = Colors.white;
      });
    });
  }
}

const Color _colorSuccess = Color(0xFF4CAF50);
