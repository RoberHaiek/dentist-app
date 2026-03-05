import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class ColleagueProfilePage extends StatefulWidget {
  final String colleagueId;

  const ColleagueProfilePage({super.key, required this.colleagueId});

  @override
  State<ColleagueProfilePage> createState() => _ColleagueProfilePageState();
}

class _ColleagueProfilePageState extends State<ColleagueProfilePage> {
  bool _loading = true;

  // Colleague info
  String _firstName = '';
  String _lastName = '';
  String _phoneNumber = '';
  String _email = '';
  String _address = '';
  String _expertise = '';
  String _role = '';

  // Calendar
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<ShiftItem>> _shifts = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadColleagueData();
  }

  Future<void> _loadColleagueData() async {
    final clinicUser = FirebaseAuth.instance.currentUser;
    if (clinicUser == null) return;

    try {
      // Load colleague info
      final colleagueDoc = await FirebaseFirestore.instance
          .collection('workers')
          .doc(widget.colleagueId)
          .get();

      if (!colleagueDoc.exists) {
        debugPrint('Colleague not found');
        setState(() => _loading = false);
        return;
      }

      final data = colleagueDoc.data() ?? {};
      _firstName = data['firstName'] as String? ?? '';
      _lastName = data['lastName'] as String? ?? '';
      _phoneNumber = data['phoneNumber'] as String? ?? '';
      _email = data['email'] as String? ?? '';
      _address = data['address'] as String? ?? '';
      _expertise = data['expertise'] as String? ?? '';
      _role = data['role'] as String? ?? '';

      // Load shifts for this colleague
      final shiftsSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicUser.uid)
          .where('type', isEqualTo: 'shift')
          .get();

      Map<DateTime, List<ShiftItem>> shiftsMap = {};

      for (final doc in shiftsSnap.docs) {
        final shiftData = doc.data();
        final teamMembers = shiftData['teamMembers'] as List? ?? [];

        // Only include shifts where this colleague is assigned
        if (!teamMembers.contains(widget.colleagueId)) continue;

        final startTime = (shiftData['startTime'] as Timestamp).toDate();
        final endTime = (shiftData['endTime'] as Timestamp).toDate();
        final reason = shiftData['reason'] as String? ?? '';

        // Use date only (no time) as key
        final dateKey = DateTime(startTime.year, startTime.month, startTime.day);

        final shift = ShiftItem(
          id: doc.id,
          startTime: startTime,
          endTime: endTime,
          reason: reason,
        );

        if (shiftsMap[dateKey] == null) {
          shiftsMap[dateKey] = [];
        }
        shiftsMap[dateKey]!.add(shift);
      }

      setState(() {
        _shifts = shiftsMap;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading colleague data: $e');
      setState(() => _loading = false);
    }
  }

  List<ShiftItem> _getShiftsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _shifts[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: Text(
          '$_firstName $_lastName',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Info Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar and name
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7DD3C0).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7DD3C0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_firstName $_lastName',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7DD3C0).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _role,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7DD3C0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Contact Info
                  const Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 12),

                  if (_phoneNumber.isNotEmpty)
                    _infoRow(Icons.phone, 'Phone', _phoneNumber),
                  if (_email.isNotEmpty)
                    _infoRow(Icons.email, 'Email', _email),
                  if (_address.isNotEmpty)
                    _infoRow(Icons.location_on, 'Address', _address),
                  if (_expertise.isNotEmpty)
                    _infoRow(Icons.star, 'Expertise', _expertise),

                  if (_phoneNumber.isEmpty && _email.isEmpty && _address.isEmpty && _expertise.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No contact information added',
                        style: TextStyle(fontSize: 14, color: Color(0xFF999999), fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Shifts Calendar Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shifts Calendar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 16),

                  // Calendar
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    eventLoader: _getShiftsForDay,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: const Color(0xFF7DD3C0).withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: Color(0xFF7DD3C0),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Selected day shifts
                  if (_selectedDay != null) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Shifts on ${DateFormat('EEEE, MMM d, y').format(_selectedDay!)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),

                    ..._getShiftsForDay(_selectedDay!).map((shift) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EBE2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: Color(0xFF7DD3C0)),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('HH:mm').format(shift.startTime)} - ${DateFormat('HH:mm').format(shift.endTime)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            if (shift.reason.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  shift.reason,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),

                    if (_getShiftsForDay(_selectedDay!).isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No shifts on this day',
                          style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getInitials() {
    final first = _firstName.isNotEmpty ? _firstName[0].toUpperCase() : '';
    final last = _lastName.isNotEmpty ? _lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF7DD3C0)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShiftItem {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String reason;

  ShiftItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.reason,
  });
}