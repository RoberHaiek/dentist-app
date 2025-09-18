import 'package:flutter/material.dart';

import '../Images.dart';
import 'Homepage.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => AppointmentPageState();
}

class AppointmentPageState extends State<AppointmentPage> {

  // 0 = choose patient, 1 = choose reason, 2 = choose time
  int activePanel = 0;
  bool showConfirmation = false;

  // always dispose controllers to prevent memory leaks
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _topPanel(),
              const SizedBox(height: 20),

              // Step 0
              if (activePanel == 0) ...[
                _middleText("Who is this appointment for?"),
                const SizedBox(height: 20),
                _floatingPanel([
                  GestureDetector(
                    onTap: () => setState(() => activePanel = 1),
                    child: const Text(
                      "Mr. Patient",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 32, color: Colors.blue),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      const Text("Add a relative", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ]),
              ],

              // Step 1
              if (activePanel == 1) ...[
                _middleText("What is the reason for visit?"),
                const SizedBox(height: 20),
                _floatingPanel([
                  GestureDetector(
                    onTap: () => setState(() => activePanel = 2),
                    child: const Text(
                      "Teeth cleaning",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => activePanel = 2),
                    child: const Text(
                      "Painful tooth",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => activePanel = 2),
                    child: const Text(
                      "General check-up",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setState(() => activePanel = 2),
                    child: const Text(
                      "Other",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ]),
              ],

              // Step 2
              if (activePanel == 2) ...[
                _middleText("When would you like to have the appointment?"),
                const SizedBox(height: 20),
                _floatingPanel([
                  GestureDetector(
                    onTap: () => setState(() => showConfirmation = true),
                    child: const Text(
                      "Monday at 11:00",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ]),
              ],
            ],

            // End Column
          ),

          // Confirmation overlay panel
          if (showConfirmation)
            Center(
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button at top right
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HomePage()),
                          );
                        },
                        child: const Icon(Icons.close, size: 24),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "An appointment has been set!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Top panel (back button + image + texts)
  Widget _topPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                if (activePanel > 0) {
                  activePanel -= 1; // go back a step
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                }
              });
            },
          ),
          Images.getImage("images/dentist_icon.png", 60.0, 60.0),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Make an appointment",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                "Dr. Dentist",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Middle text above floating panel
  Widget _middleText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
    );
  }

  // Floating panel with children widgets
  Widget _floatingPanel(List<Widget> children) {
    return Expanded(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}
