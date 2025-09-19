import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../pages/LoginPage.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("Test is working");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("🔥 Firebase initialized with project: ${DefaultFirebaseOptions.currentPlatform.projectId}");
  print("Firebase app options: ${Firebase.app().options}");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget{

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFB2CED9), // applied to all pages
        ),
        debugShowCheckedModeBanner: false,
        title: "Asnani", // actual name of the app on the phone
        home: const LoginPage()
    );
  }

}