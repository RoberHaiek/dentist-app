import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class PatientProfilePage extends StatefulWidget {
  final String patientId;

  const PatientProfilePage({super.key, required this.patientId});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  bool _uploading = false;

  // Patient info
  String _firstName = '';
  String _lastName = '';
  String _phoneNumber = '';
  String _email = '';
  String _insurance = '';
  String _allergies = '';
  String _medications = '';
  String _additionalInfo = '';

  // Appointments
  List<AppointmentItem> _pastAppointments = [];
  List<AppointmentItem> _upcomingAppointments = [];

  // Documents
  List<DocumentItem> _documents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    final clinicUser = FirebaseAuth.instance.currentUser;
    if (clinicUser == null) return;

    try {
      // Load patient info
      final patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .get();

      final data = patientDoc.data() ?? {};
      _firstName = data['firstName'] as String? ?? '';
      _lastName = data['lastName'] as String? ?? '';
      _phoneNumber = data['phoneNumber'] as String? ?? '';
      _email = data['email'] as String? ?? '';
      _insurance = data['insurance'] as String? ?? '';
      _allergies = data['allergies'] as String? ?? '';
      _medications = data['medications'] as String? ?? '';
      _additionalInfo = data['additionalInfo'] as String? ?? '';

      // Load appointments
      final appointmentsSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: widget.patientId)
          .where('clinicId', isEqualTo: clinicUser.uid)
          .get();

      debugPrint('Found ${appointmentsSnap.docs.length} appointments for patient ${widget.patientId}');

      final now = DateTime.now();
      List<AppointmentItem> past = [];
      List<AppointmentItem> upcoming = [];

      for (final doc in appointmentsSnap.docs) {
        final apptData = doc.data();
        final type = apptData['type'] as String? ?? 'appointment';

        // Skip shifts, only show actual appointments
        if (type == 'shift') {
          debugPrint('Skipping shift appointment: ${doc.id}');
          continue;
        }

        final startTime = (apptData['startTime'] as Timestamp).toDate();
        final status = apptData['status'] as String? ?? 'confirmed';

        debugPrint('Appointment ${doc.id}: $startTime, status: $status, type: $type');

        // Don't skip cancelled - let them show with cancelled badge
        final item = AppointmentItem(
          id: doc.id,
          date: startTime,
          reason: apptData['reason'] as String? ?? '',
          status: status,
          notes: apptData['notes'] as String?,
        );

        if (startTime.isBefore(now)) {
          past.add(item);
        } else {
          upcoming.add(item);
        }
      }

      debugPrint('Past appointments: ${past.length}, Upcoming: ${upcoming.length}');

      // Sort: past newest first, upcoming closest first
      past.sort((a, b) => b.date.compareTo(a.date));
      upcoming.sort((a, b) => a.date.compareTo(b.date));

      // Load documents
      final documentsSnap = await FirebaseFirestore.instance
          .collection('patientDocuments')
          .where('patientId', isEqualTo: widget.patientId)
          .where('clinicId', isEqualTo: clinicUser.uid)
          .orderBy('uploadedAt', descending: true)
          .get();

      List<DocumentItem> docs = [];
      for (final doc in documentsSnap.docs) {
        final docData = doc.data();
        docs.add(DocumentItem(
          id: doc.id,
          name: docData['name'] as String? ?? 'Document',
          url: docData['url'] as String? ?? '',
          uploadedAt: (docData['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          type: docData['type'] as String? ?? 'file',
          category: docData['category'] as String?,
        ));
      }

      setState(() {
        _pastAppointments = past;
        _upcomingAppointments = upcoming;
        _documents = docs;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading patient data: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadDocument() async {
    // Show options: Camera, Gallery, or File
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF7DD3C0)),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF7DD3C0)),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Color(0xFF7DD3C0)),
              title: const Text('Upload File'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return;

    setState(() => _uploading = true);

    try {
      final clinicUser = FirebaseAuth.instance.currentUser;
      if (clinicUser == null) return;

      File? file;
      String fileName = '';
      String type = 'file';

      if (choice == 'camera' || choice == 'gallery') {
        final picker = ImagePicker();
        final xfile = await picker.pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 85,
        );
        if (xfile == null) {
          setState(() => _uploading = false);
          return;
        }
        file = File(xfile.path);
        fileName = 'Document_${DateTime.now().millisecondsSinceEpoch}.jpg';
        type = 'image';
      } else {
        final result = await FilePicker.platform.pickFiles();
        if (result == null || result.files.isEmpty) {
          setState(() => _uploading = false);
          return;
        }
        file = File(result.files.first.path!);
        fileName = result.files.first.name;
        type = 'file';
      }

      // Upload to Firebase Storage (wrapped properly to fix threading issue)
      final storageRef = FirebaseStorage.instance.ref().child(
          'patientDocuments/${clinicUser.uid}/${widget.patientId}/$fileName');

      // Do the upload completely isolated from Flutter's main thread
      String url;
      try {
        final uploadTask = storageRef.putFile(file);

        // Wait for completion without listening to events
        final snapshot = await uploadTask.whenComplete(() {});
        url = await snapshot.ref.getDownloadURL();
      } catch (e) {
        debugPrint('Upload error: $e');
        rethrow;
      }

      // Ask for category
      if (!mounted) return;
      final category = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _categoryOption(context, 'X-Ray', Icons.medical_services),
              _categoryOption(context, 'Lab Results', Icons.biotech),
              _categoryOption(context, 'Treatment Plan', Icons.description),
              _categoryOption(context, 'Insurance', Icons.health_and_safety),
              _categoryOption(context, 'Other', Icons.folder),
            ],
          ),
        ),
      );

      if (category == null) {
        setState(() => _uploading = false);
        return;
      }

      // Save document metadata to Firestore
      await FirebaseFirestore.instance.collection('patientDocuments').add({
        'patientId': widget.patientId,
        'clinicId': clinicUser.uid,
        'name': fileName,
        'url': url,
        'type': type,
        'category': category,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      // Reload documents
      await _loadPatientData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document sent to $category'),
            backgroundColor: const Color(0xFF7DD3C0),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _categoryOption(BuildContext context, String category, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF7DD3C0)),
      title: Text(category),
      onTap: () => Navigator.pop(context, category),
    );
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
                            if (_phoneNumber.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone, size: 16, color: Color(0xFF999999)),
                                  const SizedBox(width: 4),
                                  Text(_phoneNumber, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
                                ],
                              ),
                            ],
                            if (_email.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.email, size: 16, color: Color(0xFF999999)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _email,
                                      style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Medical Info
                  const Text(
                    'Medical Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 12),

                  if (_insurance.isNotEmpty)
                    _infoRow(Icons.health_and_safety, 'Insurance', _insurance),
                  if (_allergies.isNotEmpty)
                    _infoRow(Icons.warning_amber, 'Allergies', _allergies),
                  if (_medications.isNotEmpty)
                    _infoRow(Icons.medication, 'Medications', _medications),
                  if (_additionalInfo.isNotEmpty)
                    _infoRow(Icons.note_alt, 'Notes', _additionalInfo),

                  if (_insurance.isEmpty && _allergies.isEmpty && _medications.isEmpty && _additionalInfo.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No medical information added',
                        style: TextStyle(fontSize: 14, color: Color(0xFF999999), fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Documents Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Documents',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _uploading ? null : _uploadDocument,
                        icon: _uploading
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Icon(Icons.send, size: 18),
                        label: Text(_uploading ? 'Sending...' : 'Send'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7DD3C0),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_documents.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No documents uploaded',
                          style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _documents.length,
                      itemBuilder: (context, index) => _buildDocumentCard(_documents[index]),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Activity Section (at bottom, smaller when empty)
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        const Text(
                          'Activity',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                        ),
                        const Spacer(),
                        Text(
                          '${_pastAppointments.length + _upcomingAppointments.length} total',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ),
                  if (_pastAppointments.isEmpty && _upcomingAppointments.isEmpty)
                  // Smaller empty state
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No appointments yet',
                          style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                        ),
                      ),
                    )
                  else ...[
                    TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF7DD3C0),
                      labelColor: const Color(0xFF7DD3C0),
                      unselectedLabelColor: const Color(0xFF999999),
                      tabs: [
                        Tab(text: 'Past (${_pastAppointments.length})'),
                        Tab(text: 'Upcoming (${_upcomingAppointments.length})'),
                      ],
                    ),
                    SizedBox(
                      height: 300,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAppointmentsList(_pastAppointments, isPast: true),
                          _buildAppointmentsList(_upcomingAppointments, isPast: false),
                        ],
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

  Widget _buildAppointmentsList(List<AppointmentItem> appointments, {required bool isPast}) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          isPast ? 'No past appointments' : 'No upcoming appointments',
          style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appt = appointments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2EBE2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: _getStatusColor(appt.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEE, MMM d, y · HH:mm').format(appt.date),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appt.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(appt.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(appt.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                appt.reason,
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
              if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  appt.notes!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999), fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentCard(DocumentItem doc) {
    return GestureDetector(
      onTap: () {
        // TODO: Open document in viewer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening ${doc.name}')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2EBE2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              doc.type == 'image' ? Icons.image : Icons.description,
              size: 40,
              color: const Color(0xFF7DD3C0),
            ),
            const SizedBox(height: 8),
            if (doc.category != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7DD3C0).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  doc.category!,
                  style: const TextStyle(fontSize: 9, color: Color(0xFF7DD3C0), fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                doc.name,
                style: const TextStyle(fontSize: 11, color: Color(0xFF333333)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d').format(doc.uploadedAt),
              style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF7DD3C0);
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class AppointmentItem {
  final String id;
  final DateTime date;
  final String reason;
  final String status;
  final String? notes;

  AppointmentItem({
    required this.id,
    required this.date,
    required this.reason,
    required this.status,
    this.notes,
  });
}

class DocumentItem {
  final String id;
  final String name;
  final String url;
  final DateTime uploadedAt;
  final String type;
  final String? category;

  DocumentItem({
    required this.id,
    required this.name,
    required this.url,
    required this.uploadedAt,
    required this.type,
    this.category,
  });
}