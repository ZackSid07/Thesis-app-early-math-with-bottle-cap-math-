import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool isSoundEnabled = true;
  String language = 'English';

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    isSoundEnabled = prefs.getBool('isSoundEnabled') ?? true;
    language = prefs.getString('language') ?? 'English';
    notifyListeners();
  }

  Future<void> toggleSound(bool value) async {
    isSoundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSoundEnabled', value);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }
}
