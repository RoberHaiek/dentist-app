import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'AppointmentPage.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data - replace with Firebase data
  final List<AppointmentItem> upcomingAppointments = [
    AppointmentItem(
      id: "1",
      date: DateTime(2026, 1, 15, 10, 0),
      reason: "Teeth Cleaning",
      patientName: "John Doe",
      doctorName: "Dr. Dentist",
      isUpcoming: true,
    ),
    AppointmentItem(
      id: "2",
      date: DateTime(2026, 1, 20, 14, 30),
      reason: "General Check-up",
      patientName: "John Doe",
      doctorName: "Dr. Dentist",
      isUpcoming: true,
    ),
    AppointmentItem(
      id: "3",
      date: DateTime(2026, 1, 25, 16, 0),
      reason: "Painful Tooth",
      patientName: "John Doe",
      doctorName: "Dr. Dentist",
      isUpcoming: true,
    ),
  ];

  final List<AppointmentItem> previousAppointments = [
    AppointmentItem(
      id: "4",
      date: DateTime(2025, 12, 10, 11, 0),
      reason: "Root Canal Treatment",
      patientName: "John Doe",
      doctorName: "Dr. Dentist",
      isUpcoming: false,
    ),
    AppointmentItem(
      id: "5",
      date: DateTime(2025, 11, 5, 9, 30),
      reason: "Teeth Cleaning",
      patientName: "John Doe",
      doctorName: "Dr. Dentist",
      isUpcoming: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: const Text(
          "My Appointments",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
            ),
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Previous"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildPreviousTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AppointmentPage()),
          );
        },
        backgroundColor: const Color(0xFF7DD3C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (upcomingAppointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 90,
                color: Color(0xFFBBBBBB),
              ),
              const SizedBox(height: 18),
              const Text(
                "No upcoming appointments",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Tap + to book your next appointment",
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AppointmentPage()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Book Appointment"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7DD3C0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcomingAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(upcomingAppointments[index], true);
      },
    );
  }

  Widget _buildPreviousTab() {
    if (previousAppointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.history,
                size: 90,
                color: Color(0xFFBBBBBB),
              ),
              SizedBox(height: 18),
              Text(
                "No previous appointments",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Your appointment history will appear here",
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: previousAppointments.length,
      itemBuilder: (context, index) {
        return _buildAppointmentCard(previousAppointments[index], false);
      },
    );
  }

  Widget _buildAppointmentCard(AppointmentItem appointment, bool isUpcoming) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUpcoming
              ? const Color(0xFF7DD3C0).withOpacity(0.3)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isUpcoming
                  ? const LinearGradient(
                      colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
                    ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isUpcoming ? Icons.schedule : Icons.check_circle,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isUpcoming ? "Upcoming" : "Completed",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and Time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUpcoming
                            ? const Color(0xFFA8E6CF).withOpacity(0.2)
                            : const Color(0xFFE0E0E0).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: isUpcoming
                            ? const Color(0xFF7DD3C0)
                            : const Color(0xFF999999),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(appointment.date),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isUpcoming
                                  ? const Color(0xFF333333)
                                  : const Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTime(appointment.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: isUpcoming
                                  ? const Color(0xFF7DD3C0)
                                  : const Color(0xFF999999),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Reason
                Row(
                  children: [
                    const Text(
                      "🦷",
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appointment.reason,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUpcoming
                            ? const Color(0xFF333333)
                            : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Divider(),
                const SizedBox(height: 12),

                // Patient and Doctor info
                _buildInfoRow(
                  Icons.person,
                  "Patient",
                  appointment.patientName,
                  isUpcoming,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.medical_services,
                  "Doctor",
                  appointment.doctorName,
                  isUpcoming,
                ),

                // Action buttons
                if (isUpcoming) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelAppointment(appointment),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text("Cancel"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6B6B),
                            side: const BorderSide(color: Color(0xFFFF6B6B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rescheduleAppointment(appointment),
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          label: const Text("Reschedule"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7DD3C0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _bookAgain(appointment),
                      icon: const Icon(Icons.replay, size: 18),
                      label: const Text("Book Again"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7DD3C0),
                        side: const BorderSide(color: Color(0xFF7DD3C0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, bool isUpcoming) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isUpcoming ? const Color(0xFF7DD3C0) : const Color(0xFF999999),
        ),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF999999),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isUpcoming ? const Color(0xFF333333) : const Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return "${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}";
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  void _cancelAppointment(AppointmentItem appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Cancel Appointment?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to cancel the appointment on ${_formatDate(appointment.date)} at ${_formatTime(appointment.date)}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "No",
              style: TextStyle(color: Color(0xFF999999)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                upcomingAppointments.remove(appointment);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Appointment cancelled"),
                  backgroundColor: Color(0xFFFF6B6B),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  void _rescheduleAppointment(AppointmentItem appointment) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AppointmentPage()),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please select a new date and time"),
        backgroundColor: Color(0xFF7DD3C0),
      ),
    );
  }

  void _bookAgain(AppointmentItem appointment) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AppointmentPage()),
    );
  }
}

class AppointmentItem {
  final String id;
  final DateTime date;
  final String reason;
  final String patientName;
  final String doctorName;
  final bool isUpcoming;

  AppointmentItem({
    required this.id,
    required this.date,
    required this.reason,
    required this.patientName,
    required this.doctorName,
    required this.isUpcoming,
  });
}