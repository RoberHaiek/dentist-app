import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  Map<String, dynamic> _localizedStrings = {};
  String _currentLanguage = 'he'; // Default language

  // Supported languages
  static const List<String> supportedLanguages = ['en', 'ar', 'he'];
  
  // Language display names
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ar': 'العربية',
    'he': 'עברית',
  };

  // RTL languages
  static const List<String> rtlLanguages = ['ar', 'he'];

  String get currentLanguage => _currentLanguage;
  
  bool get isRTL => rtlLanguages.contains(_currentLanguage);

  /// Initialize the localization service
  Future<void> init() async {
    // Load saved language preference
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'he';
    
    // Load translations from JSON file
    await _loadTranslations();
  }

  /// Load translations from the JSON file
  Future<void> _loadTranslations() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/strings.json');
      _localizedStrings = json.decode(jsonString);
    } catch (e) {
      print('Error loading translations: $e');
      // Fallback to empty map
      _localizedStrings = {};
    }
  }

  /// Change the current language
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.contains(languageCode)) {
      print('Language $languageCode is not supported');
      return;
    }
    
    _currentLanguage = languageCode;
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
  }

  /// Get a translated string by key
  String get(String key, {String? fallback}) {
    if (_localizedStrings.containsKey(key)) {
      final translations = _localizedStrings[key];
      if (translations is Map && translations.containsKey(_currentLanguage)) {
        return translations[_currentLanguage];
      }
    }
    
    // Fallback: return the key itself or custom fallback
    return fallback ?? key;
  }

  /// Get a translated string with parameters
  /// Example: getString('hello_name', params: {'name': 'John'})
  /// In JSON: "hello_name": {"en": "Hello {name}", ...}
  String getString(String key, {Map<String, String>? params, String? fallback}) {
    String text = get(key, fallback: fallback);
    
    if (params != null) {
      params.forEach((key, value) {
        text = text.replaceAll('{$key}', value);
      });
    }
    
    return text;
  }

  /// Check if a key exists
  bool hasKey(String key) {
    return _localizedStrings.containsKey(key);
  }

  /// Get all supported languages with their display names
  Map<String, String> getSupportedLanguages() {
    return languageNames;
  }
}

// Global instance for easy access
final localization = LocalizationService();
