import 'package:flutter/material.dart';

class MyMedicalReportPage extends StatelessWidget {
  const MyMedicalReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My medical report page"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const Center(
        child: Text("Here you see your medical report"),
      ),
    );
  }
}

