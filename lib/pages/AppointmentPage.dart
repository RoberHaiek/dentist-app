import 'package:dentist_app/CurrentPatient.dart';
import 'package:flutter/material.dart';
import '../Images.dart';
import 'Homepage.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => AppointmentPageState();
}

class AppointmentPageState extends State<AppointmentPage> {
  // Panels: 0 = patient, 1 = reason, 2 = time
  int activePanel = 0;
  bool showConfirmation = false;

  String selectedReason = "";
  String selectedDay = "";
  String selectedTime = "";
  final CurrentPatient currentPatient = CurrentPatient();
  bool loading = true;

  Map<String, bool> expandedDays = {
    "Monday": false,
    "Tuesday": false,
    "Wednesday": false,
  };

  final Map<String, List<String>> availableTimes = {
    "Monday": ["10:00", "12:00", "16:00", "17:30", "18:30"],
    "Tuesday": ["09:30", "11:00", "12:00"],
    "Wednesday": ["09:00", "10:00", "11:00", "12:00", "16:00", "17:00"],
  };

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

  void _selectReason(String reason) {
    setState(() {
      selectedReason = reason;
      activePanel = 2;
    });
  }

  void _selectDay(String day) {
    setState(() {
      expandedDays.forEach((key, value) {
        expandedDays[key] = key == day ? !expandedDays[key]! : false;
      });
    });
  }

  void _selectTime(String time) {
    setState(() {
      selectedTime = time;
    });
  }

  void _confirmAppointment() {
    if (selectedDay.isNotEmpty && selectedTime.isNotEmpty) {
      setState(() {
        showConfirmation = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the loading flag from _AppointmentPageState
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _topPanel(),
                const SizedBox(height: 20),
                if (activePanel == 0) _patientPanel(),
                if (activePanel == 1) _reasonPanel(),
                if (activePanel == 2) _timePanel(),
              ],
            ),
          ),

          if (showConfirmation)
            Stack(
              children: [
                // semi-transparent background that blocks taps
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {}, // absorb taps
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                ),

                // overlay content
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
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const HomePage()),
                              );
                            },
                            child: const Icon(Icons.close, size: 24),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "An appointment has been set for ${currentPatient.fullName} at $selectedDay, $selectedTime",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }


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
                  activePanel -= 1;
                } else {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomePage()));
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

  Widget _patientPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => setState(() => activePanel = 1),
              child: Text(
                currentPatient.fullName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
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
          ],
        ),
      ),
    );
  }

  Widget _reasonPanel() {
    List<String> reasons = [
      "Teeth cleaning",
      "Painful tooth",
      "General check-up",
      "Other",
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: reasons
              .map(
                (reason) => Column(
              children: [
                GestureDetector(
                  onTap: () => _selectReason(reason),
                  child: Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Divider(),
              ],
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  Widget _timePanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              "When would you like to have the appointment?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            for (var day in expandedDays.keys) _buildDayTile(day),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: (selectedDay.isNotEmpty && selectedTime.isNotEmpty)
                  ? _confirmAppointment
                  : null,
              child: const Text("Make an appointment"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTile(String day) {
    final times = availableTimes[day]!;
    final isExpanded = expandedDays[day]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _selectDay(day),
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue[100],
            width: double.infinity,
            child: Row(
              children: [
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.arrow_right, size: 20),
                ),
                const SizedBox(width: 8),
                Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var time in times)
                  ElevatedButton(
                    onPressed: () {
                      _selectTime(time);
                      selectedDay = day; // assign day when time selected
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      selectedTime == time ? Colors.blueAccent : Colors.blue,
                    ),
                    child: Text(time),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
