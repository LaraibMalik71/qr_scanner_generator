import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isFlashlightOn = false;

  bool get isFlashlightOn => _isFlashlightOn;
  bool _isVibrationEnabled = true;
  bool _isScanSoundEnabled = true;

  bool get isScanSoundEnabled => _isScanSoundEnabled;

  bool get isVibrationEnabled => _isVibrationEnabled;
  Future<void> setScanSound(bool value) async {
    _isScanSoundEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isScanSoundEnabled', value);

    notifyListeners();
  }

  Future<void> loadVibrationPreference() async {
    final prefs = await SharedPreferences.getInstance();

    _isVibrationEnabled = prefs.getBool('isVibrationEnabled') ?? true;

    notifyListeners();
  }

  Future<void> setVibration(bool value) async {
    _isVibrationEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isVibrationEnabled', value);

    notifyListeners();
  }

  void setFlashlight(bool value) {
    _isFlashlightOn = value;
    notifyListeners();
  }

  void resetFlashlight() {
    _isFlashlightOn = false;
    notifyListeners();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isVibrationEnabled = prefs.getBool('isVibrationEnabled') ?? true;
    _isScanSoundEnabled = prefs.getBool('isScanSoundEnabled') ?? true;

    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);

    notifyListeners();
  }
}
