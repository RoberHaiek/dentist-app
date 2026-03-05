import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'PatientProfilePage.dart';

class PatientsListPage extends StatefulWidget {
  const PatientsListPage({super.key});

  @override
  State<PatientsListPage> createState() => _PatientsListPageState();
}

class _PatientsListPageState extends State<PatientsListPage> {
  bool _loading = true;
  List<PatientItem> _allPatients = [];
  List<PatientItem> _filteredPatients = [];

  final _searchController = TextEditingController();
  String _sortBy = 'name'; // 'name', 'latest', 'closest'

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // Get all patients for this clinic
      final patientsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('clinicId', isEqualTo: user.uid)
          .get();

      List<PatientItem> patients = [];

      for (final doc in patientsSnapshot.docs) {
        final data = doc.data();
        final firstName = data['firstName'] as String? ?? '';
        final lastName = data['lastName'] as String? ?? '';

        if (firstName.isEmpty && lastName.isEmpty) continue;

        // Get appointments for this patient
        final appointmentsSnap = await FirebaseFirestore.instance
            .collection('appointments')
            .where('patientId', isEqualTo: doc.id)
            .where('clinicId', isEqualTo: user.uid)
            .get();

        DateTime? latestDate;
        DateTime? closestDate;
        final now = DateTime.now();

        for (final apptDoc in appointmentsSnap.docs) {
          final apptData = apptDoc.data();
          final status = apptData['status'] as String? ?? '';
          if (status == 'cancelled') continue;

          final startTime = (apptData['startTime'] as Timestamp).toDate();

          // Latest (most recent past appointment)
          if (startTime.isBefore(now)) {
            if (latestDate == null || startTime.isAfter(latestDate)) {
              latestDate = startTime;
            }
          }

          // Closest (nearest future appointment)
          if (startTime.isAfter(now)) {
            if (closestDate == null || startTime.isBefore(closestDate)) {
              closestDate = startTime;
            }
          }
        }

        patients.add(PatientItem(
          id: doc.id,
          firstName: firstName,
          lastName: lastName,
          latestAppointment: latestDate,
          closestAppointment: closestDate,
        ));
      }

      setState(() {
        _allPatients = patients;
        _filteredPatients = List.from(patients);
        _sortPatients();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading patients: $e');
      setState(() => _loading = false);
    }
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPatients = List.from(_allPatients);
      } else {
        _filteredPatients = _allPatients.where((patient) {
          final fullName = '${patient.firstName} ${patient.lastName}'.toLowerCase();
          return fullName.contains(query);
        }).toList();
      }
      _sortPatients();
    });
  }

  void _sortPatients() {
    switch (_sortBy) {
      case 'name':
        _filteredPatients.sort((a, b) {
          final nameA = '${a.firstName} ${a.lastName}'.toLowerCase();
          final nameB = '${b.firstName} ${b.lastName}'.toLowerCase();
          return nameA.compareTo(nameB);
        });
        break;
      case 'latest':
        _filteredPatients.sort((a, b) {
          if (a.latestAppointment == null && b.latestAppointment == null) return 0;
          if (a.latestAppointment == null) return 1;
          if (b.latestAppointment == null) return -1;
          return b.latestAppointment!.compareTo(a.latestAppointment!);
        });
        break;
      case 'closest':
        _filteredPatients.sort((a, b) {
          if (a.closestAppointment == null && b.closestAppointment == null) return 0;
          if (a.closestAppointment == null) return 1;
          if (b.closestAppointment == null) return -1;
          return a.closestAppointment!.compareTo(b.closestAppointment!);
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: const Text('Patients', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          : Column(
        children: [
          // Search and sort header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search patients...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF7DD3C0)),
                    filled: true,
                    fillColor: const Color(0xFFF2EBE2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Sort dropdown
                Row(
                  children: [
                    const Text(
                      'Sort by:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EBE2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF7DD3C0)),
                          items: const [
                            DropdownMenuItem(value: 'name', child: Text('A-Z')),
                            DropdownMenuItem(value: 'latest', child: Text('Latest Appointment')),
                            DropdownMenuItem(value: 'closest', child: Text('Closest Appointment')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortBy = value;
                                _sortPatients();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Patient count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF2EBE2),
            child: Text(
              '${_filteredPatients.length} patient${_filteredPatients.length != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
          ),

          // Patients list
          Expanded(
            child: _filteredPatients.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'No patients yet'
                        : 'No patients found',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                return _buildPatientCard(_filteredPatients[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(PatientItem patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientProfilePage(patientId: patient.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7DD3C0).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(patient.firstName, patient.lastName),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7DD3C0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name
                Expanded(
                  child: Text(
                    '${patient.firstName} ${patient.lastName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),

                // Arrow
                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF999999)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String firstName, String lastName) {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }
}

class PatientItem {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime? latestAppointment;
  final DateTime? closestAppointment;

  PatientItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.latestAppointment,
    this.closestAppointment,
  });
}