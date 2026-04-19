import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/gemini_service.dart';

class RevealedAnswerScreen extends StatefulWidget {
  final String childsEquation;
  final String correctEquation;

  const RevealedAnswerScreen({
    Key? key,
    required this.childsEquation,
    required this.correctEquation,
  }) : super(key: key);

  @override
  State<RevealedAnswerScreen> createState() => _RevealedAnswerScreenState();
}

class _RevealedAnswerScreenState extends State<RevealedAnswerScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final GeminiService _geminiService = GeminiService(apiKey: 'AIzaSyDRDcQYnmddI3te0Wp5nv-LQmpw3bhKaN0');
  bool _isLoadingGemini = false;

  int _num1 = 0;
  String _operator = '+';
  int _num2 = 0;
  int _answer = 0;
  bool _canParse = false;
  String explanationText = "";

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
        
        var eqParts = widget.correctEquation.split('=');
        if(eqParts.length > 1) {
            _answer = int.parse(eqParts[1].trim());
        }
        _canParse = true;
        explanationText = _operator == '-' 
          ? "Count the first group of $_num1 apple(s), then take away $_num2 apple(s). Together, they leave $_answer apples!"
          : "Count the first group of $_num1 apple(s), then add the $_num2 apples from the next group. Together, they make $_answer apples!";
      }
    } catch (e) {
      _canParse = false;
    }
  }

  void _playGeminiExplanation() async {
    if (!_canParse) return;
    setState(() => _isLoadingGemini = true);
    String expl = await _geminiService.generateRevealedStory(_num1, _operator, _num2, _answer);
    if (mounted) {
      setState(() {
        _isLoadingGemini = false;
        explanationText = expl;
      });
    }
    await _flutterTts.speak(expl);
  }

  Widget _buildCap(String text, Color color) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0,4), blurRadius: 4)],
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          // Header Banner
          Container(
            height: MediaQuery.of(context).size.height * 0.15,
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
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Equation row Caps
                  if (_canParse)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          _buildCap("$_num1", const Color(0xFFE53935)),
                          _buildCap(_operator, const Color(0xFF42A5F5)),
                          _buildCap("$_num2", const Color(0xFFE53935)),
                          _buildCap("=", const Color(0xFF9E9E9E)),
                          _buildCap("?", const Color(0xFFE53935)),
                        ],
                      ),
                    ),

                  // Robot Feedback
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFCC80), width: 2),
                    ),
                    child: Row(
                      children: [
                        const Text("🤖", style: TextStyle(fontSize: 64)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Let's try the number $_answer together!\nLet's look closely at the apples.",
                            style: const TextStyle(
                              color: Color(0xFFE65100),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Counting Check Card
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 4), blurRadius: 8)],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "COUNTING CHECK",
                              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _isLoadingGemini ? null : _playGeminiExplanation,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4FACFE),
                                  shape: BoxShape.circle,
                                ),
                                child: _isLoadingGemini
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.volume_up, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text("Here is how we calculate this:", style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 16),
                        
                        // Apple visual equation
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Wrap(children: List.generate(_num1, (i) => const Text("🍎", style: TextStyle(fontSize: 24)))),
                            Text(" $_operator ", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                            Wrap(children: List.generate(_num2, (i) => const Text("🍎", style: TextStyle(fontSize: 24)))),
                            const Text(" = ", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Wrap(children: List.generate(_answer, (i) => const Text("🍎", style: TextStyle(fontSize: 24)))),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () async {
                            await _flutterTts.speak(explanationText);
                          },
                          child: Text(
                            explanationText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
                          ),
                        )
                      ],
                    ),
                  ),

                  // Final Answer Card
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.redAccent, width: 4),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFFFCDD2), width: 8),
                            boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 4)],
                          ),
                          child: Center(
                            child: Text(
                              "$_answer",
                              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "THE ANSWER IS $_answer!",
                          style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // TRY AGAIN BUTTON
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF42A5F5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
                label: const Text("TRY AGAIN", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
