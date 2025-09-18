import 'package:flutter/material.dart';
import 'HomePage.dart';
import '../Images.dart';

class UpcomingAppointmentsPage extends StatelessWidget {
  const UpcomingAppointmentsPage({super.key});

  Widget _buildAppointmentCard({
    required String date,
    required String time,
    required String doctorName,
    required String treatment,
    required String patient,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top darker bar
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Icon(Icons.calendar_today, color: Colors.white),
                Text(date,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                const Icon(Icons.access_time, color: Colors.white),
                Text(time,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),

          // Body white background
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column 1: image + doctor name
                Column(
                  children: [
                    Images.getImage("images/dentist_icon.png", 60.0, 60.0),
                    const SizedBox(height: 10),
                    Text(doctorName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(width: 50),

                // Column 2: treatment above patient
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(treatment,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text(patient,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upcoming appointments"),
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
      body: ListView(
        children: [
          _buildAppointmentCard(
            date: "Wednesday, 17 September",
            time: "16:00",
            doctorName: "Dr. Dentist",
            treatment: "Tooth cleaning",
            patient: "Mr. Patient",
          ),
          _buildAppointmentCard(
            date: "Friday, 19 September",
            time: "10:30",
            doctorName: "Dr. Dentist",
            treatment: "General check-up",
            patient: "Mrs. Patient",
          ),
          _buildAppointmentCard(
            date: "Monday, 22 September",
            time: "14:00",
            doctorName: "Dr. Dentist",
            treatment: "Cavity filling",
            patient: "Mr. Patient",
          ),
        ],
      ),
    );
  }
}
