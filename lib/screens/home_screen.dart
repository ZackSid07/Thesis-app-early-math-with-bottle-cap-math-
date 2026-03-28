import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../main.dart'; // Access global 'cameras'
import '../theme/app_theme.dart';
import 'camera_screen.dart';
import '../providers/course_provider.dart';
import 'math_journey_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.2);
  }

  String _equationToWords(String expectedEquation, {bool hideAnswer = false}) {
    Map<String, String> wordMap = {
      '0': 'zero',
      '1': 'one',
      '2': 'two',
      '3': 'three',
      '4': 'four',
      '5': 'five',
      '6': 'six',
      '7': 'seven',
      '8': 'eight',
      '9': 'nine',
      '+': 'plus',
      '-': 'minus',
      '*': 'times',
      '/': 'divided by',
      '=': 'equals',
    };

    List<String> tokens = expectedEquation.split(' ');
    if (hideAnswer) {
      int equalsIndex = tokens.indexOf('=');
      if (equalsIndex != -1) {
        tokens = tokens.sublist(0, equalsIndex + 1);
      }
    }

    List<String> outWords = [];
    for (String token in tokens) {
      if (wordMap.containsKey(token)) {
        outWords.add(wordMap[token]!);
      } else {
        int? val = int.tryParse(token);
        if (val != null) {
          outWords.add(_numberToWords(val));
        } else {
          outWords.add(token);
        }
      }
    }
    return outWords.join(" ");
  }

  String _numberToWords(int number) {
    if (number == 0) return "zero";
    if (number < 20) {
      const units = [
        "",
        "one",
        "two",
        "three",
        "four",
        "five",
        "six",
        "seven",
        "eight",
        "nine",
        "ten",
        "eleven",
        "twelve",
        "thirteen",
        "fourteen",
        "fifteen",
        "sixteen",
        "seventeen",
        "eighteen",
        "nineteen"
      ];
      return units[number];
    }
    const tens = [
      "",
      "",
      "twenty",
      "thirty",
      "forty",
      "fifty",
      "sixty",
      "seventy",
      "eighty",
      "ninety"
    ];
    if (number < 100) {
      return tens[number ~/ 10] +
          (number % 10 != 0 ? " ${_numberToWords(number % 10)}" : "");
    }
    return number.toString();
  }

  String _getUsedCapsRequirement(List<String> equationParts) {
    List<String> reds = [];
    List<String> blues = [];
    bool hasEquals = false;

    for (var part in equationParts) {
      if (part == '=') {
        hasEquals = true;
      } else if (part == '+' || part == '-' || part == '*' || part == '/') {
        blues.add(part);
      } else if (part != '?') {
        reds.addAll(part.split(''));
      }
    }

    String req = "Used: ";
    if (reds.isNotEmpty) req += "Red caps ${reds.join(', ')}; ";
    if (blues.isNotEmpty) req += "Blue cap ${blues.join(', ')}; ";
    if (hasEquals) req += "White cap =";

    if (req.endsWith("; ")) req = req.substring(0, req.length - 2);
    return req;
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final activeLevel = courseProvider.currentActiveLevel;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF2), // background-cream
      body: Stack(
        children: [
          // Background Pattern (Dotted Grid)
          Positioned.fill(
            child: CustomPaint(
              painter: DottedGridPainter(),
            ),
          ),
          
          // Floating Ambient Orbs
          Positioned(
            top: 100,
            left: 32,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.pink.shade200.withOpacity(0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.pink.shade200.withOpacity(0.6), blurRadius: 20, spreadRadius: 10)
                ]
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: 48,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.blue.shade200.withOpacity(0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.blue.shade200.withOpacity(0.6), blurRadius: 20, spreadRadius: 10)
                ]
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 3,
            right: 32,
            child: Transform.rotate(
              angle: 0.2,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.yellow.shade200.withOpacity(0.6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.yellow.shade200.withOpacity(0.6), blurRadius: 20, spreadRadius: 10)
                  ]
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 4,
            left: 48,
            child: Transform.rotate(
              angle: -0.8,
              child: Container(
                width: 56,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green.shade200.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.green.shade200.withOpacity(0.6), blurRadius: 15, spreadRadius: 5)
                  ]
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -20,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.yellow.shade300.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.yellow.shade300.withOpacity(0.2), blurRadius: 40, spreadRadius: 20)]
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            right: -10,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF0084FF).withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF0084FF).withOpacity(0.2), blurRadius: 40, spreadRadius: 20)]
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // --- Header Section ---
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 10,
                                              offset: Offset(0, 4))
                                        ]),
                                    child: const Text(
                                      "BOTTLE CAP MATH",
                                      style: TextStyle(
                                        color: Color(0xFF00C6FF),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Math Buddy",
                                        style: TextStyle(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF1A202C),
                                          letterSpacing: -1.0,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text("🎓", style: TextStyle(fontSize: 36)),
                                    ],
                                  ),
                                ],
                              ),
                              const Positioned(
                                top: -10,
                                right: 0,
                                child: Text("🤖", style: TextStyle(fontSize: 36)),
                              )
                            ],
                          ),
                          const SizedBox(height: 30),
        
                          // --- Hear It Button ---
                          GestureDetector(
                            onTap: () {
                              _flutterTts.speak(
                                  _equationToWords(activeLevel.expectedEquation, hideAnswer: activeLevel.equation.contains('?')));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF00C6FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: const Color(0xFF00C6FF).withOpacity(0.2), width: 1),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 2,
                                        offset: Offset(0, 1))
                                  ]),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.volume_up_rounded,
                                      color: Color(0xFF0072FF), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Hear it!",
                                    style: TextStyle(
                                      color: Color(0xFF0072FF),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
        
                          // --- Dynamic Equation Caps ---
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8.0,
                                runSpacing: 12.0,
                                children: activeLevel.equation.expand((part) {
                                  if (part == '=') return ['='];
                                  if (part == '+' ||
                                      part == '-' ||
                                      part == '*' ||
                                      part == '/') return [part];
                                  if (part == '?') return ['?'];
                                  return part.split('');
                                }).map((char) {
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
        
                                  return BottleCapWidget(
                                      text: char, type: type, size: (type == CapType.operator || type == CapType.equals) ? 50 : 64);
                                }).toList(),
                              ),
                              if (activeLevel.equation.contains('?')) ...[
                                const Positioned(
                                  top: -20,
                                  right: 0,
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 30,
                                  ),
                                ),
                                const Positioned(
                                  bottom: -15,
                                  left: 0,
                                  child: Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                ),
                              ]
                            ],
                          ),
        
                          const SizedBox(height: 32),
        
                          // --- Text Translation ---
                          Container(
                            width: 280,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12,
                                      offset: Offset(0, 2),
                                      blurRadius: 4)
                                ]),
                            child: Column(
                              children: [
                                Text(
                                  _equationToWords(activeLevel.expectedEquation, hideAnswer: activeLevel.equation.contains('?'))
                                      .capitalizeFirst() + (activeLevel.equation.contains('?') ? " ?" : ""),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A202C),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getUsedCapsRequirement(activeLevel.equation),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
        
                          const SizedBox(height: 32),
        
                          // --- 3D Puffy Action Buttons ---
                          AnimatedPuffyButton(
                            title: "START SCANNING",
                            color: const Color(0xFF00FF77),
                            shadowColor: const Color(0xFF009E4A),
                            icon: Icons.photo_camera_rounded,
                            onTap: () async {
                              await _flutterTts.speak("Start Scanning");
                              await Future.delayed(const Duration(milliseconds: 400));
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CameraScreen(
                                    cameras: cameras,
                                    targetLevel: courseProvider.currentActiveLevel,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
        
                          AnimatedPuffyButton(
                            title: "Adventure Map",
                            subtext: "LEVEL ${activeLevel.levelNumber} UNLOCKED!",
                            color: const Color(0xFFFF9500),
                            shadowColor: const Color(0xFFC47F00),
                            bgOpacityIcon: Colors.orange.shade800.withOpacity(0.2),
                            iconColor: Colors.orange.shade100,
                            icon: Icons.map_rounded,
                            onTap: () async {
                              await _flutterTts.speak("Adventure Map");
                              await Future.delayed(const Duration(milliseconds: 400));
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MathJourneyScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
        
                          AnimatedPuffyButton(
                            title: "Practice Mode",
                            subtext: "SHARPEN SKILLS",
                            color: const Color(0xFF00C6FF),
                            shadowColor: const Color(0xFF0084FF),
                            bgOpacityIcon: Colors.blue.shade900.withOpacity(0.2),
                            iconColor: Colors.blue.shade100,
                            icon: Icons.videogame_asset_rounded,
                            onTap: () async {
                              await _flutterTts.speak("Practice Mode");
                              await Future.delayed(const Duration(milliseconds: 400));
                              if (!context.mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CameraScreen(
                                    cameras: cameras,
                                    isPracticeMode: true,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // --- Footer (Streak & Settings) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.grey.shade200, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(0, 4),
                                  blurRadius: 8)
                            ]),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_fire_department_rounded,
                                  color: Colors.orange, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "STREAK",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  "${courseProvider.currentStreak} Day${courseProvider.currentStreak == 1 ? '' : 's'}",
                                  style: const TextStyle(
                                    color: Color(0xFF1A202C),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await _flutterTts.speak("Settings");
                          await Future.delayed(const Duration(milliseconds: 400));
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12,
                                    offset: Offset(0, 4),
                                    blurRadius: 8)
                              ]),
                          child: const Icon(Icons.settings_rounded,
                              color: Colors.grey, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class AnimatedPuffyButton extends StatefulWidget {
  final String title;
  final String? subtext;
  final Color color;
  final Color shadowColor;
  final IconData icon;
  final VoidCallback onTap;
  final Color? bgOpacityIcon;
  final Color? iconColor;

  const AnimatedPuffyButton({
    super.key,
    required this.title,
    this.subtext,
    required this.color,
    required this.shadowColor,
    required this.icon,
    required this.onTap,
    this.bgOpacityIcon,
    this.iconColor,
  });

  @override
  State<AnimatedPuffyButton> createState() => _AnimatedPuffyButtonState();
}

class _AnimatedPuffyButtonState extends State<AnimatedPuffyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _shadowAnimation = Tween<double>(begin: 12.0, end: 2.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              margin: EdgeInsets.only(top: 12.0 - _shadowAnimation.value),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(24),
                border: const Border(
                  top: BorderSide(color: Colors.white38, width: 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: Offset(0, _shadowAnimation.value),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: Offset(0, _shadowAnimation.value + 4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.bgOpacityIcon ?? Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: widget.iconColor ?? Colors.white, size: 28),
                        const SizedBox(width: 2),
                        Icon(Icons.volume_up_rounded, color: (widget.iconColor ?? Colors.white).withOpacity(0.8), size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(color: Colors.black26, offset: Offset(1, 1), blurRadius: 2)
                            ]
                          ),
                        ),
                        if (widget.subtext != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtext!.toUpperCase(),
                            style: TextStyle(
                              color: (widget.iconColor ?? Colors.white).withOpacity(0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          )
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DottedGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.12)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const double spacing = 35.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawPoints(ui.PointMode.points, [Offset(i, j)], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
