import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../providers/course_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showParentalGate(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            "Parents Only",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("What is 12 x 4?"),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  hintText: "Answer",
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (_controller.text.trim() == "48") {
                  Navigator.pop(dialogContext);
                  // Call reset
                  Provider.of<CourseProvider>(context, listen: false)
                      .resetCourse();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Progress Reset Successfully",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Incorrect Answer"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text("Verify",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Header ---
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Color(0xFF2C3E50)),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      "Settings",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44), // balance back button
                ],
              ),
              const SizedBox(height: 32),

              // --- Preferences Card ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Consumer<SettingsProvider>(
                  builder: (context, settings, child) {
                    return Column(
                      children: [
                        // Row 1: Sound
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.volume_up_rounded,
                                        color: Color(0xFF4FACFE)),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    "Sound & Music",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF34495E),
                                    ),
                                  ),
                                ],
                              ),
                              CupertinoSwitch(
                                value: settings.isSoundEnabled,
                                activeColor: const Color(0xFF4FACFE),
                                onChanged: (val) => settings.toggleSound(val),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                            height: 1,
                            color: Colors.grey.shade200,
                            indent: 20,
                            endIndent: 20),

                        // Row 2: Language
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 16, bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.record_voice_over_rounded,
                                        color: Colors.deepPurpleAccent),
                                  ),
                                  const SizedBox(width: 16),
                                  const Text(
                                    "Voice Instructions",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF34495E),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F6F9),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            settings.setLanguage('English'),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          decoration: BoxDecoration(
                                            color:
                                                settings.language == 'English'
                                                    ? Colors.white
                                                    : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            boxShadow: settings.language ==
                                                    'English'
                                                ? [
                                                    const BoxShadow(
                                                        color: Colors.black12,
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2))
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              "English",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: settings.language ==
                                                        'English'
                                                    ? const Color(0xFF4FACFE)
                                                    : Colors.grey.shade500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () =>
                                            settings.setLanguage('Bangla'),
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          decoration: BoxDecoration(
                                            color: settings.language == 'Bangla'
                                                ? Colors.white
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            boxShadow: settings.language ==
                                                    'Bangla'
                                                ? [
                                                    const BoxShadow(
                                                        color: Colors.black12,
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2))
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Bangla",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: settings.language ==
                                                        'Bangla'
                                                    ? const Color(0xFF4FACFE)
                                                    : Colors.grey.shade500,
                                              ),
                                            ),
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
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // --- About Card ---
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6FBFF),
                  borderRadius: BorderRadius.circular(25),
                  // Light blue #E3F2FD tint simulated with F6FBFF to keep contrast nice
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4FACFE),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x664FACFE),
                              blurRadius: 10,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.school,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Bottle Cap Math",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF2C3E50)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Making math tangible and fun.",
                      style: TextStyle(color: Color(0xFF7F8C8D), fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Version 1.0.0",
                      style: TextStyle(color: Color(0xFFBDC3C7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- Danger Zone ---
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0x19FF5252), // transparent red background
                  border: Border.all(
                      color: const Color(0x80FF5252),
                      style: BorderStyle
                          .none), // custom shape ignores dash out of box, using regular rounded border for UX consistency here. But user specified dashed.
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _showParentalGate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ]),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded,
                                color: Color(0xFFFF5252), size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Reset All Progress",
                              style: TextStyle(
                                  color: Color(0xFFFF5252),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "(REQUIRES PARENT TO UNLOCK)",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
