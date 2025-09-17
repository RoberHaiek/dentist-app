import 'package:dentist_app/screens/AppointmentPage.dart';
import 'package:dentist_app/screens/FirstPage.dart';
import 'package:flutter/material.dart';
import '../Images.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      drawer: Drawer(
        child: Column(
          children: [
            // Top header with X
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Images.getImage("images/tooth_icon.png", 90, 90),
                  const SizedBox(width: 2),
                  Text("Asnani",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Spacer(), // pushes the X button to the far right
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).pop(); // closes the drawer
                    },
                  ),
                ],
              ),
            ),

            // Other items
            const ListTile(title: Text("Homepage")),
            const ListTile(title: Text("My appointments")),
            const ListTile(title: Text("Schedule a new appointment")),
            const ListTile(title: Text("My medical record")),
            const ListTile(title: Text("Previous appointments")),
            const ListTile(title: Text("Contact clinic")),
            const ListTile(title: Text("Settings")),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
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

            // Icon above Welcome
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Images.getImage("images/tooth_icon.png", 200.0, 200.0),
                const SizedBox(height: 10),
                const Text(
                  "Welcome Mr. Name to Asnani",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Sliding cards
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCard("Did you know that you need to clean your teeth once every 6 months?"),
                  _buildCard("Teeth must be brushed 3 times a day, once in the morning, once at noon after lunch, and once before sleep"),
                  _buildCard("Card 3"),
                  _buildCard("Card 4"),
                ],
              ),
            ),

            const Spacer(),

            // Floating appointment panel
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                "Next appointment: \n Monday at 11:00",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),

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
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FirstPage(),
                  ),
                );
              },
              child: const Text("Logout"),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // helper for cards
  static Widget _buildCard(String title) {
    return Container(
      height: 200,
      width: 350,
      margin: const EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16), // adds space around the text
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center, // optional: center inside padding
            ),
          ),
        ),
      ),
    );
  }

}