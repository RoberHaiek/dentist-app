import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'BookAppointmentPage.dart';
import '../../services/LocalizationProvider.dart';

class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key});

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;

  List<AppointmentItem> _upcoming = [];
  List<AppointmentItem> _previous = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final now = DateTime.now();

      // Query all appointments for this patient (simplified to avoid index)
      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .get();

      final List<AppointmentItem> upcoming = [];
      final List<AppointmentItem> previous = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Skip shifts - filter in code instead of query
        final type = data['type'] as String? ?? 'appointment';
        if (type != 'appointment') continue;

        final startTime = (data['startTime'] as Timestamp).toDate();
        final isUpcoming = startTime.isAfter(now);

        final item = AppointmentItem(
          id: doc.id,
          date: startTime,
          reason: data['reason'] as String? ?? '',
          patientName: data['patientName'] as String? ?? '',
          doctorName: '', // We'll fetch clinic name separately if needed
          isUpcoming: isUpcoming,
          status: data['status'] as String? ?? 'confirmed',
          notes: data['notes'] as String?,
        );

        if (isUpcoming) {
          upcoming.add(item);
        } else {
          previous.add(item);
        }
      }

      // Sort appointments since we removed orderBy from query
      upcoming.sort((a, b) => a.date.compareTo(b.date));
      previous.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _upcoming = upcoming;
        _previous = previous;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: Text(
          context.tr('my_appointments'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: context.tr('upcoming')),
            Tab(text: context.tr('previous')),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3C0)))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList(_upcoming, true),
          _buildAppointmentList(_previous, false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookAppointmentPage()),
          );
          // Reload after booking
          _loadAppointments();
        },
        backgroundColor: const Color(0xFF7DD3C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          context.tr('book_appointment'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAppointmentList(List<AppointmentItem> appointments, bool isUpcoming) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.calendar_today : Icons.history,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming
                  ? context.tr('no_upcoming_appointments')
                  : context.tr('no_previous_appointments'),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isUpcoming) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BookAppointmentPage()),
                  );
                  _loadAppointments();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7DD3C0),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  context.tr('book_appointment'),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: const Color(0xFF7DD3C0),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          return _buildAppointmentCard(appointments[index]);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentItem appointment) {
    final isPast = !appointment.isUpcoming;
    final statusColor = _getStatusColor(appointment.status);
    final statusText = _getStatusText(appointment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAppointmentDetails(appointment),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Status Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA8E6CF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF7DD3C0),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMM d, y').format(appointment.date),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('HH:mm').format(appointment.date),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF7DD3C0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Reason
                Row(
                  children: [
                    const Icon(Icons.medical_services, color: Color(0xFF7DD3C0), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.reason,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // Notes if available
                if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes, color: Color(0xFF999999), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          appointment.notes!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF666666),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Removed cancel/reschedule buttons - appointments managed by clinic
              ],
            ),
          ),
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
      case 'no-show':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'confirmed':
        return context.tr('confirmed');
      case 'pending':
        return context.tr('pending');
      case 'completed':
        return context.tr('completed');
      case 'cancelled':
        return context.tr('cancelled');
      case 'no-show':
        return 'No-Show';
      default:
        return status;
    }
  }

  void _showAppointmentDetails(AppointmentItem appointment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA8E6CF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: Color(0xFF7DD3C0),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('appointment_details'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMM d, y · HH:mm').format(appointment.date),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _detailRow(Icons.medical_services, context.tr('reason'), appointment.reason),
              const SizedBox(height: 12),
              _detailRow(Icons.info_outline, context.tr('status'), _getStatusText(appointment.status)),
              if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _detailRow(Icons.notes, context.tr('notes'), appointment.notes!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7DD3C0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.tr('close'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF7DD3C0), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
  final String status;
  final String? notes;

  AppointmentItem({
    required this.id,
    required this.date,
    required this.reason,
    required this.patientName,
    required this.doctorName,
    required this.isUpcoming,
    this.status = 'confirmed',
    this.notes,
  });
}