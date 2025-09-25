import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- add this
import '../Images.dart';
import 'AppointmentPage.dart';
import 'HomePage.dart';

class ContactClinicPage extends StatelessWidget {
  const ContactClinicPage({super.key});

  Future<void> _showPhoneOptions(BuildContext context, String number) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.blue),
                title: const Text("Call"),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri uri = Uri(scheme: "tel", path: number);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.blue),
                title: const Text("Copy number"),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: number));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Phone number copied")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEmailOptions(BuildContext context, String email) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text("Send email"),
                onTap: () async {
                  Navigator.pop(context);
                  final Uri uri = Uri(scheme: "mailto", path: email);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.blue),
                title: const Text("Copy email"),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: email));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Email copied")),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const clinicAddress = "Bab el der 11 street\n2020000 Shefaamr";
    const phoneNumber = "+49 123 456 7890";
    const email = "dr.dentist@email.com";

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Doctor Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top panel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Images.getImage("images/dentist_icon.png", 100, 100),
                  const SizedBox(height: 15),
                  const Text(
                    "Dr. Dentist",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AppointmentPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text("Book an appointment",
                        style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info panel
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Opening hours
                  const Text(
                    "Opening Hours",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1),
                    },
                    children: const [
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text("Monday"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text("09:00 - 17:00"),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text("Tuesday"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text("09:00 - 17:00"),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text("Wednesday"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text("09:00 - 17:00"),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text("Thursday"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text("09:00 - 17:00"),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text("Friday"),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text("09:00 - 13:00"),
                        ),
                      ]),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Address with copy button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.blue, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          clinicAddress,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.blue),
                        tooltip: "Copy address",
                        onPressed: () {
                          Clipboard.setData(
                              const ClipboardData(text: clinicAddress));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Address copied to clipboard")),
                          );
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Phone clickable
                  InkWell(
                    onTap: () => _showPhoneOptions(context, phoneNumber),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.blue, size: 24),
                        const SizedBox(width: 10),
                        Text(phoneNumber, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Email clickable
                  InkWell(
                    onTap: () => _showEmailOptions(context, email),
                    child: Row(
                      children: [
                        const Icon(Icons.email, color: Colors.blue, size: 24),
                        const SizedBox(width: 10),
                        Text(email, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}