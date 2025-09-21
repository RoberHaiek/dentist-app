import 'package:dentist_app/pages/AppointmentPage.dart';
import 'package:dentist_app/pages/ContactClinicPage.dart';
import 'package:dentist_app/pages/LoginPage.dart';
import 'package:dentist_app/pages/MyMedicalReportPage.dart';
import 'package:dentist_app/pages/PreviousAppointmentsPage.dart';
import 'package:dentist_app/pages/SettingsPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../CurrentPatient.dart';
import '../Images.dart';
import 'UpcomingAppointmentsPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage>{
  final CurrentPatient currentPatient = CurrentPatient();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    await currentPatient.loadFromFirestore();
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Images.getImage("images/tooth_icon.png", 90, 90),
                  const SizedBox(width: 2),
                  const Text(
                    "Asnani",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text("Homepage"),
              onTap: () {},
            ),
            ListTile(
              title: const Text("Upcoming appointments"),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const UpcomingAppointmentsPage()));
              },
            ),
            ListTile(
              title: const Text("Schedule a new appointment"),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AppointmentPage()));
              },
            ),
            ListTile(
              title: const Text("My medical record"),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MyMedicalReportPage()));
              },
            ),
            ListTile(
              title: const Text("Previous appointments"),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PreviousAppointmentsPage()));
              },
            ),
            ListTile(
              title: const Text("Contact clinic"),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ContactClinicPage()));
              },
            ),
            ListTile(
              title: const Text("Settings"),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsPage()));
              },
            )
          ],
        ),
      ),
      body: loading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top bar (burger + language)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, size: 40, color: Colors.white),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.language, size: 40, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  // Logo and welcome text, pushed higher
                  Padding(
                    padding: const EdgeInsets.only(top: 0.0, bottom: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Images.getImage("images/tooth_icon.png", 120.0, 120.0),
                        Text(
                          "Welcome " + currentPatient.fullName + " to Asnani",
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sliding cards
                  SizedBox(
                    height: 200,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildCard("Visit your dentist regularly (usually every 6 months) for check-ups and professional cleaning"),
                        _buildCard("Brush your teeth twice a day, once in the morning and once before sleep"),
                        _buildCard("Floss daily to remove plaque and food particles between your teeth that brushing can’t reach"),
                        _buildCard("Limit sugary and acidic foods and drinks to protect your enamel and prevent cavities"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Next appointment panel
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      "Next appointment:\nMonday at 11:00",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Make an appointment button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppointmentPage(),
                        ),
                      );
                    },
                    child: const Text("Make a new appointment"),
                  ),

                  const SizedBox(height: 15),

                  // Logout button
                  ElevatedButton(
                    onPressed: () async {
                      // Sign out from Firebase
                      await FirebaseAuth.instance.signOut();

                      // Navigate to login page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text("Logout"),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCard(String title) {
    return Container(
      height: 200,
      width: 350,
      margin: const EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
