import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LevelState { done, current, locked }

class LevelData {
  final int levelNumber;
  final String category;
  final List<String> equation;
  final String expectedEquation; // "1+2=3"
  LevelState state;

  LevelData({
    required this.levelNumber,
    required this.category,
    required this.equation,
    required this.expectedEquation,
    required this.state,
  });
}

class CourseProvider extends ChangeNotifier {
  // Streak tracking
  int currentStreak = 0;
  DateTime? lastPlayedDate;
  int _problemsSolvedToday = 0; // Tracks consecutive problems solved today

  int get problemsSolvedToday => _problemsSolvedToday;

  CourseProvider() {
    initStreak();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    int highestUnlockedLevelId = prefs.getInt('highestUnlockedLevelId') ?? 1;

    for (var level in _levels) {
      if (level.levelNumber < highestUnlockedLevelId) {
        level.state = LevelState.done;
      } else if (level.levelNumber == highestUnlockedLevelId) {
        level.state = LevelState.current;
      } else {
        level.state = LevelState.locked;
      }
    }
    notifyListeners();
  }

  Future<void> initStreak() async {
    final prefs = await SharedPreferences.getInstance();
    currentStreak = prefs.getInt('currentStreak') ?? 0;
    String? lastPlayedStr = prefs.getString('lastPlayedDate');

    if (lastPlayedStr != null) {
      lastPlayedDate = DateTime.parse(lastPlayedStr);
    }

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    if (lastPlayedDate == null) {
      // First time playing
      currentStreak = 1;
    } else {
      DateTime lastPlayedDay = DateTime(
          lastPlayedDate!.year, lastPlayedDate!.month, lastPlayedDate!.day);
      int differenceInDays = today.difference(lastPlayedDay).inDays;

      if (differenceInDays == 1) {
        currentStreak++;
      } else if (differenceInDays > 1) {
        currentStreak = 1; // Streak broken
      }
      // If difference is 0, they already played today, keep the current streak
    }

    lastPlayedDate = now;
    await prefs.setInt('currentStreak', currentStreak);
    await prefs.setString('lastPlayedDate', lastPlayedDate!.toIso8601String());

    notifyListeners();
  }

  // Mock Curriculum Data Structure
  final List<LevelData> _levels = [
    LevelData(
        levelNumber: 1,
        category: "Single-Digit Addition",
        equation: ["1", "+", "2", "=", "?"],
        expectedEquation: "1 + 2 = 3",
        state: LevelState.current),
    LevelData(
        levelNumber: 2,
        category: "Single-Digit Addition",
        equation: ["1", "+", "4", "=", "?"],
        expectedEquation: "1 + 4 = 5",
        state: LevelState.locked),
    LevelData(
        levelNumber: 3,
        category: "Single-Digit Addition",
        equation: ["1", "+", "6", "=", "?"],
        expectedEquation: "1 + 6 = 7",
        state: LevelState.locked),
    LevelData(
        levelNumber: 4,
        category: "Single-Digit Addition",
        equation: ["2", "+", "6", "=", "?"],
        expectedEquation: "2 + 6 = 8",
        state: LevelState.locked),
    LevelData(
        levelNumber: 5,
        category: "Single-Digit Addition",
        equation: ["2", "+", "7", "=", "?"],
        expectedEquation: "2 + 7 = 9",
        state: LevelState.locked),
    LevelData(
        levelNumber: 6,
        category: "Single-Digit Addition",
        equation: ["3", "+", "5", "=", "?"],
        expectedEquation: "3 + 5 = 8",
        state: LevelState.locked),
    LevelData(
        levelNumber: 7,
        category: "Single-Digit Addition",
        equation: ["4", "+", "5", "=", "?"],
        expectedEquation: "4 + 5 = 9",
        state: LevelState.locked),
    LevelData(
        levelNumber: 8,
        category: "Single-Digit Subtraction",
        equation: ["9", "-", "1", "=", "?"],
        expectedEquation: "9 - 1 = 8",
        state: LevelState.locked),
    LevelData(
        levelNumber: 9,
        category: "Single-Digit Subtraction",
        equation: ["9", "-", "2", "=", "?"],
        expectedEquation: "9 - 2 = 7",
        state: LevelState.locked),
    LevelData(
        levelNumber: 10,
        category: "Single-Digit Subtraction",
        equation: ["9", "-", "4", "=", "?"],
        expectedEquation: "9 - 4 = 5",
        state: LevelState.locked),
    LevelData(
        levelNumber: 11,
        category: "Single-Digit Subtraction",
        equation: ["8", "-", "3", "=", "?"],
        expectedEquation: "8 - 3 = 5",
        state: LevelState.locked),
    LevelData(
        levelNumber: 12,
        category: "Single-Digit Subtraction",
        equation: ["7", "-", "1", "=", "?"],
        expectedEquation: "7 - 1 = 6",
        state: LevelState.locked),
    LevelData(
        levelNumber: 13,
        category: "Single-Digit Subtraction",
        equation: ["7", "-", "5", "=", "?"],
        expectedEquation: "7 - 5 = 2",
        state: LevelState.locked),
    LevelData(
        levelNumber: 14,
        category: "Single-Digit Subtraction",
        equation: ["6", "-", "2", "=", "?"],
        expectedEquation: "6 - 2 = 4",
        state: LevelState.locked),
    LevelData(
        levelNumber: 15,
        category: "Double-Digit + Single-Digit",
        equation: ["24", "+", "7", "=", "?"],
        expectedEquation: "24 + 7 = 31",
        state: LevelState.locked),
    LevelData(
        levelNumber: 16,
        category: "Double-Digit + Single-Digit",
        equation: ["25", "+", "9", "=", "?"],
        expectedEquation: "25 + 9 = 34",
        state: LevelState.locked),
    LevelData(
        levelNumber: 17,
        category: "Double-Digit + Single-Digit",
        equation: ["38", "+", "7", "=", "?"],
        expectedEquation: "38 + 7 = 45",
        state: LevelState.locked),
    LevelData(
        levelNumber: 18,
        category: "Double-Digit + Single-Digit",
        equation: ["74", "+", "6", "=", "?"],
        expectedEquation: "74 + 6 = 80",
        state: LevelState.locked),
    LevelData(
        levelNumber: 19,
        category: "Double-Digit - Single-Digit",
        equation: ["34", "-", "5", "=", "?"],
        expectedEquation: "34 - 5 = 29",
        state: LevelState.locked),
    LevelData(
        levelNumber: 20,
        category: "Double-Digit - Single-Digit",
        equation: ["50", "-", "8", "=", "?"],
        expectedEquation: "50 - 8 = 42",
        state: LevelState.locked),
    LevelData(
        levelNumber: 21,
        category: "Double-Digit - Single-Digit",
        equation: ["80", "-", "6", "=", "?"],
        expectedEquation: "80 - 6 = 74",
        state: LevelState.locked),
    LevelData(
        levelNumber: 22,
        category: "Double-Digit - Single-Digit",
        equation: ["92", "-", "5", "=", "?"],
        expectedEquation: "92 - 5 = 87",
        state: LevelState.locked),
    LevelData(
        levelNumber: 23,
        category: "Double-Digit + Double-Digit",
        equation: ["14", "+", "25", "=", "?"],
        expectedEquation: "14 + 25 = 39",
        state: LevelState.locked),
    LevelData(
        levelNumber: 24,
        category: "Double-Digit + Double-Digit",
        equation: ["27", "+", "38", "=", "?"],
        expectedEquation: "27 + 38 = 65",
        state: LevelState.locked),
    LevelData(
        levelNumber: 25,
        category: "Double-Digit + Double-Digit",
        equation: ["34", "+", "56", "=", "?"],
        expectedEquation: "34 + 56 = 90",
        state: LevelState.locked),
  ];

  List<LevelData> get levels => _levels;

  LevelData get currentActiveLevel => _levels.firstWhere(
        (level) => level.state == LevelState.current,
        orElse: () => _levels.lastWhere(
          (level) => level.state == LevelState.done,
          orElse: () => _levels.first,
        ),
      );

  void completeCurrentLevel(int levelId) {
    // 1. Find and mark the target level as done
    int index = _levels.indexWhere((l) => l.levelNumber == levelId);
    if (index != -1 && _levels[index].state != LevelState.done) {
      _levels[index].state = LevelState.done;

      // Increment today's solved problems
      _problemsSolvedToday++;

      // Check for streak logic
      if (_problemsSolvedToday >= 4) {
        _problemsSolvedToday = 0; // Reset for next streak cycle if needed
      }

      // 2. Unlock the immediate next sequential level, if it exists
      int nextLevelId = levelId;
      if (index + 1 < _levels.length) {
        _levels[index + 1].state = LevelState.current;
        nextLevelId = _levels[index + 1].levelNumber;
      }

      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('highestUnlockedLevelId', nextLevelId);
      });

      // Propagate state rebuild down the widget tree
      notifyListeners();
    }
  }

  Future<void> resetCourse() async {
    currentStreak = 0;
    lastPlayedDate = null;
    _problemsSolvedToday = 0;

    for (int i = 0; i < _levels.length; i++) {
      _levels[i].state = i == 0 ? LevelState.current : LevelState.locked;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentStreak', 0);
    await prefs.remove('lastPlayedDate');
    await prefs.setInt('highestUnlockedLevelId', 1);

    notifyListeners();
  }
}
