import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/gemini_service.dart';

class HintScreen extends StatefulWidget {
  final String childsEquation;
  final String correctEquation;
  
  // Optional legacy fields for fallback usage in camera_screen
  final String? correctAnswer;
  final String? aiExplanation;

  const HintScreen({
    Key? key,
    required this.childsEquation,
    required this.correctEquation,
    this.correctAnswer,
    this.aiExplanation,
  }) : super(key: key);

  @override
  State<HintScreen> createState() => _HintScreenState();
}

class _HintScreenState extends State<HintScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final GeminiService _geminiService = GeminiService(apiKey: 'AIzaSyAHnn1Atu1EATqEDU7M-fXphjJd29ZEfwo');
  bool _isLoadingGemini = false;
  
  int _num1 = 0;
  String _operator = '+';
  int _num2 = 0;
  bool _canParse = false;
  String explanationText = "Let's count ALL of them together!";

  @override
  void initState() {
    super.initState();
    _initTts();
    _parseCorrectEquation();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.1);
  }
  
  void _parseCorrectEquation() {
    try {
      if (widget.correctEquation.isEmpty) return;
      List<String> parts = widget.correctEquation.split(' ');
      if (parts.length >= 3) {
        _num1 = int.parse(parts[0]);
        _operator = parts[1];
        _num2 = int.parse(parts[2]);
        _canParse = true;
      }
    } catch (e) {
      _canParse = false;
    }
  }

  void _playGeminiExplanation() async {
    if (!_canParse) {
      if (widget.aiExplanation != null) {
        _flutterTts.speak(widget.aiExplanation!);
      }
      return;
    }
    setState(() => _isLoadingGemini = true);
    String expl = await _geminiService.generateHintStory(_num1, _operator, _num2);
    if (mounted) {
      setState(() {
        _isLoadingGemini = false;
        explanationText = expl;
      });
    }
    await _flutterTts.speak(expl);
  }

  @override
  Widget build(BuildContext context) {
    String leftSide = widget.childsEquation;
    String rightSide = "";
    if (widget.childsEquation.contains('=')) {
      var parts = widget.childsEquation.split('=');
      leftSide = "${parts[0].trim()} =";
      if (parts.length > 1) rightSide = parts[1].trim();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          // Header Banner
          Container(
            height: MediaQuery.of(context).size.height * 0.20,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFFA726),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black12, offset: Offset(0, 4), blurRadius: 8)
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "💡 Oops! Almost there.",
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Mistake Display
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "$leftSide ",
                                style: const TextStyle(
                                  color: Color(0xFF1A237E),
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              TextSpan(
                                text: rightSide,
                                style: const TextStyle(
                                  color: Color(0xFFFFA726),
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA726).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.help_rounded, color: Color(0xFFFFA726), size: 28),
                        ),
                      ],
                    ),
                  ),
                  
                  // Hint Card
                  if (_canParse)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 4)),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, offset: Offset(0, 10), blurRadius: 20)
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header & Gemini Gen
                            Row(
                              children: [
                                const Icon(Icons.school_rounded, color: Color(0xFFEC5B13), size: 32),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    "Counting Check!",
                                    style: TextStyle(
                                      color: Color(0xFF1A237E),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _isLoadingGemini ? null : _playGeminiExplanation,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4FACFE).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: _isLoadingGemini 
                                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.volume_up_rounded, color: Color(0xFF4FACFE), size: 24),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Row 1
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: [
                                  Wrap(
                                    children: List.generate(_num1, (index) => 
                                      const Padding(
                                        padding: EdgeInsets.only(right: 2.0),
                                        child: Text("🍎", style: TextStyle(fontSize: 24)),
                                      )
                                    ),
                                  ),
                                  Text(
                                    "First, we have $_num1.",
                                    softWrap: true,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF334155),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _flutterTts.speak("First, we have $_num1."),
                                    child: const Icon(Icons.volume_up_rounded, color: Color(0xFF4FACFE), size: 20),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Row 2
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Opacity(
                                    opacity: _operator == '-' ? 0.5 : 1.0,
                                    child: Wrap(
                                      children: List.generate(_num2, (index) => 
                                        const Padding(
                                          padding: EdgeInsets.only(right: 2.0),
                                          child: Text("🍎", style: TextStyle(fontSize: 20)),
                                        )
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _operator == '-' ? "Then we take away $_num2." : "Then we add $_num2.",
                                      softWrap: true,
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        color: Color(0xFF334155),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _flutterTts.speak(_operator == '-' ? "Then we take away $_num2." : "Then we add $_num2."),
                                    child: const Icon(Icons.volume_up_rounded, color: Color(0xFF4FACFE), size: 20),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            GestureDetector(
                              onTap: () async {
                                await _flutterTts.speak(explanationText);
                              },
                              child: Text(
                                explanationText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF1A237E),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Mascot
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("🤖", style: TextStyle(fontSize: 64)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4FACFE),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black12, offset: Offset(0, 4), blurRadius: 8)
                              ],
                            ),
                            child: const Text(
                              "Let's count the caps one more time!",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 64,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF4FACFE),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF3182CE), offset: Offset(0, 4)),
                  ]
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      "TRY AGAIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
