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
          scaffoldBackgroundColor: Colors.lightBlueAccent, // applied to all pages
        ),
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
                      fontSize: 40.0,
                      color: Colors.blue[900]
                  )
              )
          ),
          body: const LoginPage()
        )
    );
  }

}