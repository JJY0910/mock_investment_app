import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _storageKey = 'theme_mode';
  
  ThemeMode _mode = ThemeMode.light;
  bool _isLoaded = false;
  
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  bool get isLoaded => _isLoaded;
  
  ThemeProvider() {
    // Auto-load theme on construction
    load();
  }
  
  /// Load theme preference from storage
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_storageKey);
      
      print('[ThemeProvider] Loading saved theme: $savedMode');
      
      if (savedMode != null) {
        switch (savedMode) {
          case 'light':
            _mode = ThemeMode.light;
            break;
          case 'dark':
            _mode = ThemeMode.dark;
            break;
          case 'system':
            _mode = ThemeMode.system;
            break;
          default:
            _mode = ThemeMode.light;
        }
      } else {
        // Default to light theme
        _mode = ThemeMode.light;
      }
      
      _isLoaded = true;
      print('[ThemeProvider] Theme loaded: $_mode (isDark: $isDark)');
      notifyListeners();
    } catch (e) {
      print('[ThemeProvider] Error loading theme: $e');
      _mode = ThemeMode.light;
      _isLoaded = true;
      notifyListeners();
    }
  }
  
  /// Set theme mode and save to storage
  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    
    _mode = mode;
    print('[ThemeProvider] Setting theme to: $mode');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      String modeString;
      
      switch (mode) {
        case ThemeMode.light:
          modeString = 'light';
          break;
        case ThemeMode.dark:
          modeString = 'dark';
          break;
        case ThemeMode.system:
          modeString = 'system';
          break;
      }
      
      await prefs.setString(_storageKey, modeString);
      print('[ThemeProvider] Theme saved: $modeString');
    } catch (e) {
      print('[ThemeProvider] Error saving theme: $e');
    }
    
    notifyListeners();
  }
  
  /// Toggle between light and dark
  Future<void> toggle() async {
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
    print('[ThemeProvider] Toggling theme: $_mode -> $newMode');
    await setMode(newMode);
  }
}
