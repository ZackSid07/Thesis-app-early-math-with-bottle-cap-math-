import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../theme/app_theme.dart';
import 'camera_screen.dart';
import '../main.dart'; // To access global cameras

class MathJourneyScreen extends StatefulWidget {
  const MathJourneyScreen({super.key});

  @override
  State<MathJourneyScreen> createState() => _MathJourneyScreenState();
}

class _MathJourneyScreenState extends State<MathJourneyScreen> {
  bool _isMapView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B2E4B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Math Journey",
          style: TextStyle(
            fontFamily: 'Nunito',
            color: Color(0xFF1B2E4B),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.primaryBlue),
            onPressed: () {},
          )
        ],
      ),
      body: Consumer<CourseProvider>(
        builder: (context, courseProvider, child) {
          final levels = courseProvider.levels;
          return Column(
            children: [
              _buildToggleSwitch(),
              Expanded(
                child:
                    _isMapView ? _buildMapView(levels) : _buildListView(levels),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            const BoxShadow(
                color: Colors.black12, offset: Offset(0, 4), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isMapView = true),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        _isMapView ? AppTheme.primaryBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map,
                            color: _isMapView ? Colors.white : Colors.grey,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "Map View",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: _isMapView ? Colors.white : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _isMapView = false),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        !_isMapView ? AppTheme.primaryBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list,
                            color: !_isMapView ? Colors.white : Colors.grey,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "List View",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: !_isMapView ? Colors.white : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(List<LevelData> levels) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      itemCount: levels.length,
      itemBuilder: (context, index) {
        final level = levels[index];
        bool isFirst = index == 0;
        bool isLast = index == levels.length - 1;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Vertical Dotted Line Background
            Positioned(
              top: isFirst ? 50 : 0,
              bottom: isLast ? 50 : 0,
              child: Container(
                width: 4,
                child: ListView.builder(
                  controller: ScrollController(keepScrollOffset: false),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, idx) {
                    return Container(
                      height: 10,
                      width: 4,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Card Content
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
              child: Opacity(
                opacity: level.state == LevelState.locked ? 0.5 : 1.0,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: level.state == LevelState.current
                        ? Border.all(color: AppTheme.primaryBlue, width: 3)
                        : null,
                    boxShadow: [
                      const BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 8),
                          blurRadius: 15),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStateChip(level.state),
                          Text(
                            "Level ${level.levelNumber}",
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6.0,
                        runSpacing: 6.0,
                        children: level.equation.expand((part) {
                          if (part == '=') return ['='];
                          if (part == '+' ||
                              part == '-' ||
                              part == '*' ||
                              part == '/') return [part];
                          if (part == '?') return ['?'];
                          return part.split('');
                        }).map((char) {
                          CapType type;
                          if (char == '+' || char == '-') {
                            type = CapType.operator;
                          } else if (char == '=') {
                            type = CapType.equals;
                          } else if (char == '?') {
                            type = CapType.equals; // Fallback white color
                          } else {
                            type = CapType.number;
                          }

                          // If locked, just show a padlock generic cap
                          if (level.state == LevelState.locked && char == '?') {
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 2.0),
                              child: Icon(Icons.lock,
                                  color: Colors.grey, size: 35),
                            );
                          }

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 2.0),
                            child: char == '?'
                                ? BottleCapWidget(
                                    text: '?',
                                    type: CapType.equals,
                                    size: 38,
                                  )
                                : BottleCapWidget(
                                    text: char,
                                    type: type,
                                    size: 38,
                                  ),
                          );
                        }).toList(),
                      ),
                      if (level.state == LevelState.current) ...[
                        const SizedBox(height: 30),
                        ToyButton(
                          text: "Start Adventure \u2192", // Custom arrow
                          color: AppTheme.primaryBlue,
                          onPressed: () {
                            // Route directly to CameraScreen, injecting the specific target LevelData
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CameraScreen(
                                  cameras: cameras,
                                  targetLevel: level,
                                ),
                              ),
                            );
                          },
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStateChip(LevelState state) {
    Color bgColor;
    Color textColor = Colors.white;
    String text;
    IconData? icon;

    switch (state) {
      case LevelState.done:
        bgColor = AppTheme.successGreen;
        text = "DONE";
        icon = Icons.check_circle;
        break;
      case LevelState.current:
        bgColor = AppTheme.primaryBlue;
        text = "CURRENT";
        icon = Icons.play_arrow;
        break;
      case LevelState.locked:
        bgColor = Colors.grey.shade300;
        textColor = Colors.grey.shade700;
        text = "LOCKED";
        icon = Icons.lock;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: textColor,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<LevelData> levels) {
    // Group levels by Category
    Map<String, List<LevelData>> groupedLevels = {};
    for (var lvl in levels) {
      if (!groupedLevels.containsKey(lvl.category)) {
        groupedLevels[lvl.category] = [];
      }
      groupedLevels[lvl.category]!.add(lvl);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: groupedLevels.keys.length,
      itemBuilder: (context, index) {
        String category = groupedLevels.keys.elementAt(index);
        List<LevelData> categoryLevels = groupedLevels[category]!;

        int doneCount =
            categoryLevels.where((l) => l.state == LevelState.done).length;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              const BoxShadow(
                  color: Colors.black12, offset: Offset(0, 4), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              // Category Header
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text("+",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1B2E4B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$doneCount/${categoryLevels.length}",
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              // Level Rows
              ...categoryLevels.map((lvl) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              "Lvl ${lvl.levelNumber}",
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: lvl.equation.map((char) {
                                CapType type;
                                if (char == '+' || char == '-') {
                                  type = CapType.operator;
                                } else if (char == '=') {
                                  type = CapType.equals;
                                } else if (char == '?') {
                                  type = CapType.equals;
                                } else {
                                  type = CapType.number;
                                }

                                // Omit the '?' or locked symbol in simple list rows
                                if (char == '?') return const SizedBox();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2.0),
                                  child: BottleCapWidget(
                                    text: char,
                                    type: type,
                                    size: 30, // Much smaller for list
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          // Trailing Icon
                          if (lvl.state == LevelState.done)
                            const Icon(Icons.check_circle,
                                color: AppTheme.successGreen)
                          else if (lvl.state == LevelState.locked)
                            const Icon(Icons.lock, color: Colors.grey)
                        ],
                      ),
                      if (lvl.state == LevelState.current) ...[
                        const SizedBox(height: 16),
                        ToyButton(
                          text: "Play Now \u25B6",
                          color: AppTheme.primaryBlue,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CameraScreen(
                                  cameras: cameras,
                                  targetLevel: lvl,
                                ),
                              ),
                            );
                          },
                        ),
                      ]
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
