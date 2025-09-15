import 'dart:math';

import 'package:dentist_app/screens/FirstPage.dart';
import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.lightBlueAccent,
      child: Center(
        child: Container(
          padding: EdgeInsets.only(left: 10.0, top: 60.0),
          alignment: Alignment.center,
          color: Colors.white30,
          child: Column(
            children: <Widget>[
              Text(
                // Calling a function from a text
                "Welcome to homepage, your number here is: ${generateLuckyNumber()}",
                textDirection: TextDirection.ltr,
                style: TextStyle(color: Colors.yellow, fontSize: 70.0),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FirstPage()),
                  );
                },
                child: const Text("Go to back"),
              ),
            ],
          ),
        ),
      ),
    );
  }


  int generateLuckyNumber() {
    Random random = Random();
    return random.nextInt(10);
  }

}