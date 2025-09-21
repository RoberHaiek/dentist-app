import 'package:flutter/material.dart';

import 'HomePage.dart';

class MyDocumentsPage extends StatelessWidget {
  const MyDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My documents page"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
      ),
      body: const Center(
        child: Text("Here you see your documents"),
      ),
    );
  }
}

