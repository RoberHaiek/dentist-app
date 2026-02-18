import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../CurrentPatient.dart';

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  bool _loading = true;
  bool _saving = false;

  final CurrentPatient _currentPatient = CurrentPatient();
  String? _clinicId;
  String _clinicName = '';

  String _selectedReason = '';
  DateTime? _selectedDate;
  String? _selectedTime;

  final List<String> _reasons = [
    'General Checkup',
    'Teeth Cleaning',
    'Tooth Pain',
    'Filling',
    'Root Canal',
    'Extraction',
    'Crown/Bridge',
    'Whitening',
    'Orthodontics',
    'Emergency',
  ];

  Map<String, dynamic>? _clinicHours; // Opening hours from clinic
  List<DateTime> _bookedSlots = []; // Already booked times
  String? _autoAssignColleague; // If only 1 colleague, auto-assign

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _currentPatient.loadFromFirestore();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Get patient's clinic ID
      final patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      _clinicId = patientDoc.data()?['clinicId'] as String?;

      if (_clinicId == null) {
        setState(() => _loading = false);
        return;
      }

      // Load clinic info
      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(_clinicId)
          .get();
      final clinicData = clinicDoc.data() ?? {};
      _clinicName = clinicData['clinicName'] as String? ?? 'Clinic';
      _clinicHours = clinicData['openingHours'] as Map<String, dynamic>?;

      // Check if there's only 1 worker to auto-assign
      final workersSnap = await FirebaseFirestore.instance
          .collection('workers')
          .where('clinicId', isEqualTo: _clinicId)
          .get();
      if (workersSnap.docs.length == 1) {
        _autoAssignColleague = workersSnap.docs.first.id;
      }

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadBookedSlots(DateTime date) async {
    if (_clinicId == null) return;

    // Query appointments for the selected date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('clinicId', isEqualTo: _clinicId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    setState(() {
      _bookedSlots = snapshot.docs
          .map((doc) => (doc.data()['startTime'] as Timestamp).toDate())
          .toList();
    });
  }

  List<String> _getAvailableTimes() {
    if (_selectedDate == null || _clinicHours == null) return [];

    final dayName = _getDayName(_selectedDate!);
    final dayHours = _clinicHours![dayName] as Map<String, dynamic>?;

    if (dayHours == null || dayHours['open'] != true) return [];

    final List<String> slots = [];

    // Parse opening hours
    final start1 = _parseTime(dayHours['start1'] as String? ?? '09:00');
    final end1 = _parseTime(dayHours['end1'] as String? ?? '17:00');
    final hasBreak = dayHours['hasBreak'] as bool? ?? false;

    // Generate whole-hour slots for first period
    _addWholeHourSlots(slots, start1, end1);

    // If there's a break, add second period
    if (hasBreak) {
      final start2 = _parseTime(dayHours['start2'] as String? ?? '16:00');
      final end2 = _parseTime(dayHours['end2'] as String? ?? '20:00');
      _addWholeHourSlots(slots, start2, end2);
    }

    // Filter out already booked slots
    final now = DateTime.now();
    return slots.where((timeStr) {
      final slotTime = _combineDateTime(_selectedDate!, timeStr);
      // Don't show past times
      if (slotTime.isBefore(now)) return false;
      // Don't show if already booked
      return !_bookedSlots.any((booked) =>
      booked.hour == slotTime.hour && booked.day == slotTime.day);
    }).toList();
  }

  void _addWholeHourSlots(List<String> slots, TimeOfDay start, TimeOfDay end) {
    // Only add whole hours (10:00, 11:00, not 10:30)
    int currentHour = start.minute == 0 ? start.hour : start.hour + 1;
    while (currentHour < end.hour || (currentHour == end.hour && end.minute > 0)) {
      slots.add('${currentHour.toString().padLeft(2, '0')}:00');
      currentHour++;
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  DateTime _combineDateTime(DateTime date, String time) {
    final parts = time.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  Future<void> _bookAppointment() async {
    if (_selectedReason.isEmpty || _selectedDate == null || _selectedTime == null) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _clinicId == null) return;

    setState(() => _saving = true);

    try {
      final startTime = _combineDateTime(_selectedDate!, _selectedTime!);
      final endTime = startTime.add(const Duration(hours: 1)); // Default 1-hour appointments

      final appointmentData = {
        'patientId': user.uid,
        'patientName': _currentPatient.firstName ?? 'Patient',
        'clinicId': _clinicId,
        'reason': _selectedReason,
        'type': 'appointment',
        'status': 'pending', // Pending until clinic confirms
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'notes': null,
        'teamMembers': _autoAssignColleague != null ? [_autoAssignColleague!] : [],
        'customTag': null,
        'color': 0xFF7DD3C0,
        'recurrence': 'none',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('appointments')
          .add(appointmentData);

      if (mounted) {
        // Show success and navigate back
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF7DD3C0), size: 32),
                SizedBox(width: 12),
                Text('Appointment Requested'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your appointment request has been sent to the clinic.',
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EBE2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(_selectedDate!),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'at $_selectedTime',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF7DD3C0), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedReason,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The clinic will confirm your appointment soon.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7DD3C0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking appointment: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: const Text('Book Appointment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)]),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3C0)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clinic name
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: Color(0xFF7DD3C0), size: 28),
                  const SizedBox(width: 12),
                  Text(_clinicName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reason
            const Text('Reason for Visit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons.map((reason) {
                final selected = _selectedReason == reason;
                return GestureDetector(
                  onTap: () => setState(() => _selectedReason = reason),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF7DD3C0) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? const Color(0xFF7DD3C0) : const Color(0xFFCCCCCC), width: 1.5),
                    ),
                    child: Text(reason, style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected ? Colors.white : const Color(0xFF666666),
                    )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Date picker
            const Text('Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: Color(0xFF7DD3C0)),
                    ),
                    child: child!,
                  ),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                    _selectedTime = null; // Reset time when date changes
                  });
                  await _loadBookedSlots(date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF7DD3C0)),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'Choose a date'
                          : DateFormat('EEEE, MMMM d, y').format(_selectedDate!),
                      style: TextStyle(
                        fontSize: 15,
                        color: _selectedDate == null ? const Color(0xFF999999) : const Color(0xFF333333),
                        fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Time slots
            if (_selectedDate != null) ...[
              const Text('Select Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              const SizedBox(height: 12),
              _getAvailableTimes().isEmpty
                  ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No available time slots for this date',
                    style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  ),
                ),
              )
                  : Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _getAvailableTimes().map((time) {
                  final selected = _selectedTime == time;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTime = time),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF7DD3C0) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? const Color(0xFF7DD3C0) : const Color(0xFFCCCCCC),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          color: selected ? Colors.white : const Color(0xFF666666),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 32),

            // Book button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedReason.isNotEmpty && _selectedDate != null && _selectedTime != null && !_saving)
                    ? _bookAppointment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7DD3C0),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  'Book Appointment',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}