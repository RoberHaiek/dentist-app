import 'package:flutter/material.dart';
import 'LocalizationService.dart';

// Provider widget that rebuilds children when language changes - this has to be done so the whole app changes settings
class LocalizationProvider extends StatefulWidget {
  final Widget child;
  
  const LocalizationProvider({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<LocalizationProvider> createState() => LocalizationProviderState();

  // Access the state from anywhere in the widget tree
  static LocalizationProviderState? of(BuildContext context) {
    return context.findAncestorStateOfType<LocalizationProviderState>();
  }
}

class LocalizationProviderState extends State<LocalizationProvider> {
  // Change language and rebuild the entire app
  Future<void> changeLanguage(String languageCode) async {
    await localization.changeLanguage(languageCode);
    setState(() {});
  }

  // Get current language
  String get currentLanguage => localization.currentLanguage;

  // Check if current language is RTL
  bool get isRTL => localization.isRTL;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Extension for easy access to localization in widgets
extension LocalizationExtension on BuildContext {
  // Get translated string
  String tr(String key, {String? fallback}) {
    return localization.get(key, fallback: fallback);
  }

  // Get translated string with parameters
  String trParams(String key, {Map<String, String>? params, String? fallback}) {
    return localization.getString(key, params: params, fallback: fallback);
  }

  // Get current language code
  String get languageCode => localization.currentLanguage;

  // Check if current language is RTL (Arabic or Hebrew)
  bool get isRTL => localization.isRTL;

  // Change language (requires LocalizationProvider ancestor)
  Future<void> changeLanguage(String languageCode) async {
    final provider = LocalizationProvider.of(this);
    if (provider != null) {
      await provider.changeLanguage(languageCode);
    }
  }
}
