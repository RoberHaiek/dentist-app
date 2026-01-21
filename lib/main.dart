import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../pages/LoginPage.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/LocalizationService.dart';
import 'services/LocalizationProvider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize localization BEFORE running the app
  await localization.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget{

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LocalizationProvider(
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: context.tr('Asnani'),

            // Set locale based on current language
            locale: Locale(localization.currentLanguage),

            // Support for RTL languages (optional but recommended)
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ar'), // Arabic
              Locale('he'), // Hebrew
            ],

            theme: ThemeData(
              primarySwatch: Colors.teal,
              // Important: Use a font that supports Arabic and Hebrew
              fontFamily: 'Roboto',
              scaffoldBackgroundColor: const Color(0xFFB2CED9),
            ),

            // Set the app to use RTL or LTR based on language
            builder: (context, child) {
              return Directionality(
                textDirection: context.isRTL
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child ?? const SizedBox(),
              );
            },

            home: SafeArea(
                child: LoginPage()
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

}