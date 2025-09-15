import 'dart:math';

import 'package:flutter/material.dart';
import 'Homepage.dart';
import '../Images.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.lightBlueAccent,
      child: Center(
        child: Container(
          padding: EdgeInsets.only(left: 10.0, top: 60.0),
          alignment: Alignment.center,
          margin: EdgeInsets.all(30.0),
          color: Colors.white30,
          child: Column(
            children: <Widget>[
              Text(
                // Calling a function from a text
                "Welcome page, your number is: ${generateLuckyNumber()}",
                textDirection: TextDirection.ltr,
                style: TextStyle(color: Colors.white, fontSize: 40.0),
              ),
              Images(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Homepage()),
                  );
                },
                child: const Text("Go to Homepage"),
              ),
              ElevatedButton(
                onPressed: () {
                  changeNumber(context);
                },
                child: const Text("I don't like my number"),
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
  
  void changeNumber(BuildContext context){
    
    AlertDialog alertDialog = AlertDialog(
      title: Text("Number changed to: ${generateLuckyNumber()}"),
      content: Text("Are you happy now?"),
    );
    
    showDialog(context: context, builder: (BuildContext context){
      return alertDialog;
    });
  }
}
