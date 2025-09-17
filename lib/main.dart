import 'package:flutter/material.dart';
import '../screens/FirstPage.dart';
import '../screens/HomePage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget{

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "My first app", // actual name of the app on the phone
        home: Scaffold(
          appBar: AppBar(
              title: Text(
                  "My first app :D",
                  style: TextStyle(
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      fontSize: 40.0
                  )
              )
          ),
          body: const FirstPage()
        )
    );
  }

}