import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../CurrentPatient.dart';
import '../../services/LocalizationService.dart';

class RelativePatient {
  final String? id; // Firestore doc ID if saved
  final String firstName;
  final String lastName;
  final String relation;
  final DateTime birthDate;

  RelativePatient({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.relation,
    required this.birthDate,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() => {
    'firstName': firstName,
    'lastName': lastName,
    'relation': relation,
    'birthDate': Timestamp.fromDate(birthDate),
  };

  factory RelativePatient.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RelativePatient(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      relation: data['relation'] ?? '',
      birthDate: (data['birthDate'] as Timestamp).toDate(),
    );
  }
}

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

  // Patient selection
  List<RelativePatient> _relatives = [];
  RelativePatient? _selectedRelative; // null = self (account owner)

  List<String> get _reasons => [
    localization.get('reason_general_checkup'),
    localization.get('reason_teeth_cleaning'),
    localization.get('reason_tooth_pain'),
    localization.get('reason_filling'),
    localization.get('reason_root_canal'),
    localization.get('reason_extraction'),
    localization.get('reason_crown_bridge'),
    localization.get('reason_whitening'),
    localization.get('reason_orthodontics'),
    localization.get('reason_emergency'),
  ];

  Map<String, dynamic>? _clinicHours;
  List<DateTime> _bookedSlots = [];
  String? _autoAssignColleague;

  String get _selfFullName {
    final first = _currentPatient.firstName ?? '';
    final last = _currentPatient.lastName ?? '';
    return '$first $last'.trim();
  }

  String get _selectedPatientName {
    if (_selectedRelative != null) return _selectedRelative!.fullName;
    return _selfFullName;
  }

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
      final patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      _clinicId = patientDoc.data()?['clinicId'] as String?;

      if (_clinicId == null) {
        setState(() => _loading = false);
        return;
      }

      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(_clinicId)
          .get();
      final clinicData = clinicDoc.data() ?? {};
      _clinicName = clinicData['clinicName'] as String? ?? localization.get('clinic');
      _clinicHours = clinicData['openingHours'] as Map<String, dynamic>?;

      final workersSnap = await FirebaseFirestore.instance
          .collection('workers')
          .where('clinicId', isEqualTo: _clinicId)
          .get();
      if (workersSnap.docs.length == 1) {
        _autoAssignColleague = workersSnap.docs.first.id;
      }

      // Load relatives
      await _loadRelatives(user.uid);

      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRelatives(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('relatives')
        .orderBy('firstName')
        .get();
    _relatives = snap.docs.map((d) => RelativePatient.fromDoc(d)).toList();
  }

  Future<void> _loadBookedSlots(DateTime date) async {
    if (_clinicId == null) return;

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

    final start1 = _parseTime(dayHours['start1'] as String? ?? '09:00');
    final end1 = _parseTime(dayHours['end1'] as String? ?? '17:00');
    final hasBreak = dayHours['hasBreak'] as bool? ?? false;

    _addWholeHourSlots(slots, start1, end1);

    if (hasBreak) {
      final start2 = _parseTime(dayHours['start2'] as String? ?? '16:00');
      final end2 = _parseTime(dayHours['end2'] as String? ?? '20:00');
      _addWholeHourSlots(slots, start2, end2);
    }

    final now = DateTime.now();
    return slots.where((timeStr) {
      final slotTime = _combineDateTime(_selectedDate!, timeStr);
      if (slotTime.isBefore(now)) return false;
      return !_bookedSlots.any((booked) =>
      booked.hour == slotTime.hour && booked.day == slotTime.day);
    }).toList();
  }

  void _addWholeHourSlots(List<String> slots, TimeOfDay start, TimeOfDay end) {
    int currentHour = start.minute == 0 ? start.hour : start.hour + 1;
    while (currentHour < end.hour || (currentHour == end.hour && end.minute > 0)) {
      slots.add('${currentHour.toString().padLeft(2, '0')}:00');
      currentHour++;
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  DateTime _combineDateTime(DateTime date, String time) {
    final parts = time.split(':');
    return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  void _showAddRelativeSheet() {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    DateTime? birthDate;
    String? selectedPreset;
    bool savingRelative = false;

    const presets = ['Son', 'Daughter', 'Mother', 'Father', 'Spouse', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF2EBE2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCCCCC),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Add a Family Member',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 20),

                  // First + Last name row
                  Row(
                    children: [
                      Expanded(
                        child: _buildSheetField(
                          controller: firstNameCtrl,
                          label: 'First Name',
                          hint: 'e.g. John',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSheetField(
                          controller: lastNameCtrl,
                          label: 'Last Name',
                          hint: 'e.g. Smith',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Relation presets
                  Text(
                    'Relation',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((p) {
                      final isSelected = selectedPreset == p;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            selectedPreset = p;
                            if (p != 'Other') relationCtrl.text = p;
                            else relationCtrl.clear();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF7DD3C0) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF7DD3C0) : const Color(0xFFCCCCCC),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF666666),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Custom relation text (shown when Other is selected or no preset)
                  if (selectedPreset == 'Other' || selectedPreset == null)
                    _buildSheetField(
                      controller: relationCtrl,
                      label: selectedPreset == null ? 'Or type a custom relation' : 'Custom relation',
                      hint: 'e.g. Grandparent, Uncle…',
                    ),
                  const SizedBox(height: 16),

                  // Birth date
                  Text(
                    'Date of Birth',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(primary: Color(0xFF7DD3C0)),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setSheetState(() => birthDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCCCCCC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cake_outlined, color: Color(0xFF7DD3C0), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            birthDate == null
                                ? 'Select birth date'
                                : DateFormat('MMMM d, y').format(birthDate!),
                            style: TextStyle(
                              fontSize: 14,
                              color: birthDate == null ? const Color(0xFF999999) : const Color(0xFF333333),
                              fontWeight: birthDate == null ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: savingRelative
                          ? null
                          : () async {
                        final fn = firstNameCtrl.text.trim();
                        final ln = lastNameCtrl.text.trim();
                        final rel = relationCtrl.text.trim();

                        if (fn.isEmpty || ln.isEmpty || rel.isEmpty || birthDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please fill in all fields'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setSheetState(() => savingRelative = true);
                        try {
                          final user = FirebaseAuth.instance.currentUser!;
                          final newRelative = RelativePatient(
                            firstName: fn,
                            lastName: ln,
                            relation: rel,
                            birthDate: birthDate!,
                          );
                          final docRef = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('relatives')
                              .add(newRelative.toMap());

                          final saved = RelativePatient(
                            id: docRef.id,
                            firstName: fn,
                            lastName: ln,
                            relation: rel,
                            birthDate: birthDate!,
                          );

                          setState(() {
                            _relatives.add(saved);
                            _selectedRelative = saved;
                          });

                          if (mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setSheetState(() => savingRelative = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7DD3C0),
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: savingRelative
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Add', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildSheetField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 1.5)),
          ),
        ),
      ],
    );
  }

  Future<void> _bookAppointment() async {
    if (_selectedReason.isEmpty || _selectedDate == null || _selectedTime == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _clinicId == null) return;

    setState(() => _saving = true);

    try {
      final startTime = _combineDateTime(_selectedDate!, _selectedTime!);
      final endTime = startTime.add(const Duration(hours: 1));

      final appointmentData = {
        'patientId': user.uid,
        'patientName': _selectedPatientName,
        'isRelative': _selectedRelative != null,
        'relativeId': _selectedRelative?.id,
        'relativeRelation': _selectedRelative?.relation,
        'clinicId': _clinicId,
        'reason': _selectedReason,
        'type': 'appointment',
        'status': 'pending',
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'notes': null,
        'teamMembers': _autoAssignColleague != null ? [_autoAssignColleague!] : [],
        'customTag': null,
        'color': 0xFF7DD3C0,
        'recurrence': 'none',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('appointments').add(appointmentData);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF7DD3C0), size: 32),
                const SizedBox(width: 12),
                Text(localization.get('appointment_requested')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localization.get('appointment_request_sent'), style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF2EBE2), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPatientName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF333333)),
                      ),
                      if (_selectedRelative != null)
                        Text(
                          _selectedRelative!.relation,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('EEEE, MMMM d, y').format(_selectedDate!),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${localization.get('at')} $_selectedTime',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF7DD3C0), fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(_selectedReason, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(localization.get('clinic_will_confirm'), style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7DD3C0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(localization.get('done'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${localization.get('error_booking_appointment')}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: Text(
          localization.get('book_appointment'),
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
                  Text(
                    _clinicName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── PATIENT SELECTOR ──
            Text(
              'Who is this appointment for?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  // Self option
                  _PatientTile(
                    name: _selfFullName.isNotEmpty ? _selfFullName : 'Me',
                    subtitle: 'Account holder',
                    isSelected: _selectedRelative == null,
                    onTap: () => setState(() => _selectedRelative = null),
                    icon: Icons.person,
                  ),

                  // Relatives
                  ..._relatives.map((r) => Column(
                    children: [
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _PatientTile(
                        name: r.fullName,
                        subtitle: r.relation,
                        isSelected: _selectedRelative?.id == r.id,
                        onTap: () => setState(() => _selectedRelative = r),
                        icon: Icons.family_restroom,
                      ),
                    ],
                  )),

                  // Add new button
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  InkWell(
                    onTap: _showAddRelativeSheet,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7DD3C0).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Color(0xFF7DD3C0), size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add a family member',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7DD3C0)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reason
            Text(
              localization.get('reason_for_visit_label'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
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
                      border: Border.all(
                        color: selected ? const Color(0xFF7DD3C0) : const Color(0xFFCCCCCC),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        color: selected ? Colors.white : const Color(0xFF666666),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Date picker
            Text(
              localization.get('select_date_label'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
            ),
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
                    _selectedTime = null;
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
                          ? localization.get('choose_a_date')
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
              Text(
                localization.get('select_time_label'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 12),
              _getAvailableTimes().isEmpty
                  ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(localization.get('no_available_slots'), style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
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
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                  localization.get('book_appointment'),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable tile widget ──
class _PatientTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const _PatientTile({
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7DD3C0) : const Color(0xFF7DD3C0).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF7DD3C0), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF7DD3C0), size: 22),
          ],
        ),
      ),
    );
  }
}