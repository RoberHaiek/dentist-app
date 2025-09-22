import 'package:flutter/material.dart';
import '../Images.dart';
import 'HomePage.dart'; // assuming you have a helper for loading images

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App logo
            Center(
              child: Images.getImage("images/tooth_icon_with_bg.png", 120.0, 120.0),
            ),
            const SizedBox(height: 16),

            // App name
            Text(
              "Asnani",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900]
              ),
            ),
            const SizedBox(height: 8),

            // Version
            Text(
              "Version 1.0.0",
              style: TextStyle(fontSize: 16, color: Colors.blue[800]),
            ),
            const SizedBox(height: 24),

            // About text panel
            _infoPanel(
              title: "About this app",
              content:
              "Asnani helps patients and dentists manage appointments, "
                  "reminders, and services with ease. A modern tool to make "
                  "dental care simpler.",
            ),
            const SizedBox(height: 16),

            // Developer info panel
            _infoPanel(
              title: "Developed by",
              content: "Rober Haiek",
            ),
            const SizedBox(height: 16),

            // Contact info panel
            _infoPanel(
              title: "Contact",
              content: "Email: rober.haiek@gmail.com\n"
                  "WhatsApp: 0522965892",
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPanel({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}