import 'package:flutter/material.dart';

class ForgotPage extends StatelessWidget {
  const ForgotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: const Center(
        child: Text("Here you can reset your password"),
      ),
    );
  }
}