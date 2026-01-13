import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 즐겨찾기 관리 Provider
/// shared_preferences를 사용하여 영구 저장
class FavoritesProvider extends ChangeNotifier {
  static const String _storageKey = 'favorite_coins';
  
  final Set<String> _favoriteKeys = {};
  bool _isLoaded = false;

  /// Get all favorite keys
  Set<String> get favoriteKeys => Set.unmodifiable(_favoriteKeys);

  /// Check if loaded
  bool get isLoaded => _isLoaded;

  /// Check if a coin is favorited
  bool isFavorite(String pairKey) {
    return _favoriteKeys.contains(pairKey);
  }

  /// Toggle favorite status
  void toggleFavorite(String pairKey) {
    if (_favoriteKeys.contains(pairKey)) {
      _favoriteKeys.remove(pairKey);
    } else {
      _favoriteKeys.add(pairKey);
    }
    _save();
    notifyListeners();
  }

  /// Load favorites from shared_preferences
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? saved = prefs.getStringList(_storageKey);
      
      if (saved != null) {
        _favoriteKeys.clear();
        _favoriteKeys.addAll(saved);
        print('[FavoritesProvider] Loaded ${_favoriteKeys.length} favorites');
      } else {
        print('[FavoritesProvider] No saved favorites found');
      }
      
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      print('[FavoritesProvider] Error loading favorites: $e');
      _isLoaded = true;
    }
  }

  /// Save favorites to shared_preferences
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _favoriteKeys.toList());
      print('[FavoritesProvider] Saved ${_favoriteKeys.length} favorites');
    } catch (e) {
      print('[FavoritesProvider] Error saving favorites: $e');
    }
  }

  /// Clear all favorites (for testing)
  Future<void> clearAll() async {
    _favoriteKeys.clear();
    await _save();
    notifyListeners();
  }
}
