import 'dart:math';

import 'package:flutter/material.dart';
import 'HomePage.dart';
import '../Images.dart';
import 'ForgotPage.dart';
import 'RegistrationPage.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  FirstPageState createState() => FirstPageState();
}

class FirstPageState extends State<FirstPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // always dispose controllers to prevent memory leaks
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
              Images.getIconImage(),
              Text(
                // Calling a function from a text
                "Log in to Asnani",
                textDirection: TextDirection.ltr,
                style: TextStyle(color: Colors.white, fontSize: 40.0),
              ),
              // Email field
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Password field
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true, // hides the text
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  String email = emailController.text;
                  String password = passwordController.text;
                  print("Email: $email, Password: $password");
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
                child: const Text("Login"),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ForgotPage()),
                  );
                },
                child: const Text(
                  "Forgot password?",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationPage()),
                  );
                },
                child: const Text(
                  "Register",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
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

  void changeNumber(BuildContext context) {
    AlertDialog alertDialog = AlertDialog(
      title: Text("Number changed to: ${generateLuckyNumber()}"),
      content: Text("Are you happy now?"),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alertDialog;
      },
    );
  }
}
