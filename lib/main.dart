import 'package:flutter/material.dart';
import '../pages/LoginPage.dart';
import '../pages/HomePage.dart';

void main() {
  runApp(MyApp());
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
        home: Scaffold(
          body: const LoginPage()
        )
    );
  }

}