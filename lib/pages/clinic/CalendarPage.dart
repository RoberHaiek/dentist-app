import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/LocalizationProvider.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const int    _kOpenHour  = 8;
const int    _kCloseHour = 20;
const double _kHourH     = 64.0;
const double _kHeaderH   = 52.0;
const double _kGutterW   = 56.0;
double get   _kGridH     => (_kCloseHour - _kOpenHour) * _kHourH + 1; // +1 so last border shows

const List<String> _kReasons = [
  'Teeth Cleaning',
  'Filling',
  'Tooth Extraction',
  'Root Canal',
  'Crown / Bridge',
  'Teeth Whitening',
  'Braces / Orthodontics',
  'Dental Implant',
  'X-Ray / Imaging',
  'General Consultation',
  'Follow-up Visit',
  'Emergency',
  'Other',
];

// ─── Color helper ─────────────────────────────────────────────────────────────
int _colorForType(String type) {
  switch (type) {
    case 'shift':   return 0xFF4A90E2;
    case 'holiday': return 0xFFE74C3C;
    case 'break':   return 0xFFF39C12;
    default:        return 0xFF7DD3C0;
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────
class CalendarAppointment {
  final String id, patientId, patientName, clinicId, reason, type, status;
  final DateTime startTime, endTime;
  final String? notes;
  final String? customTag;
  final List<String> teamMembers;
  final int colorValue;

  // Recurrence fields
  final String recurrence;  // 'none', 'weekly', 'custom'
  final List<int>? weekdays; // For weekly: 1=Mon, 7=Sun
  final String? recurrenceId; // Groups recurring appointments together
  final DateTime? recurrenceEnd; // When recurrence stops

  Color get color => Color(colorValue);

  CalendarAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.clinicId,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.type,
    required this.status,
    required this.colorValue,
    this.notes,
    this.customTag,
    List<String>? teamMembers,
    this.recurrence = 'none',
    this.weekdays,
    this.recurrenceId,
    this.recurrenceEnd,
  }) : teamMembers = teamMembers ?? const [];

  factory CalendarAppointment.fromFirestore(DocumentSnapshot doc) {
    final d    = doc.data() as Map<String, dynamic>;
    final type = d['type'] as String? ?? 'appointment';
    return CalendarAppointment(
      id:          doc.id,
      patientId:   d['patientId']   as String? ?? '',
      patientName: d['patientName'] as String? ?? '',
      clinicId:    d['clinicId']    as String? ?? '',
      startTime:   (d['startTime'] as Timestamp).toDate(),
      endTime:     (d['endTime']   as Timestamp).toDate(),
      reason:      d['reason']  as String? ?? '',
      type:        type,
      status:      d['status'] as String? ?? 'confirmed',
      colorValue:  d['color']  as int? ?? _colorForType(type),
      notes:       d['notes']  as String?,
      customTag:   d['customTag'] as String?,
      teamMembers: List<String>.from(d['teamMembers'] as List? ?? []),
      recurrence:  d['recurrence'] as String? ?? 'none',
      weekdays:    d['weekdays'] != null ? List<int>.from(d['weekdays'] as List) : null,
      recurrenceId: d['recurrenceId'] as String?,
      recurrenceEnd: d['recurrenceEnd'] != null ? (d['recurrenceEnd'] as Timestamp).toDate() : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CalendarPage
// ─────────────────────────────────────────────────────────────────────────────
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {

  DateTime    _focus   = DateTime.now();
  Set<String> _filters       = {'appointment', 'shift', 'holiday', 'break'};
  Set<String> _workerFilter  = {};
  String?     _customTagFilter;

  List<CalendarAppointment>  _all      = [];
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _workers  = [];
  bool _loading = false;

  late TabController       _tab;
  final ScrollController   _scroll = ScrollController();

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this, initialIndex: 1);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) _loadAppointments();
    });
    _loadAppointments();
    _loadPatients();
    _loadWorkers();
  }

  @override
  void dispose() {
    _tab.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────
  Future<void> _loadPatients() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('clinicId', isEqualTo: user.uid)
          .get();
      if (mounted) {
        setState(() {
          _patients = snap.docs
              .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
              .toList();
        });
      }
    } catch (e) {
      debugPrint('patients: $e');
    }
  }

  Future<void> _loadWorkers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('workers')
          .where('clinicId', isEqualTo: user.uid)
          .get();
      if (mounted) {
        setState(() {
          _workers = snap.docs
              .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
              .toList();
        });
      }
    } catch (e) {
      debugPrint('workers: $e');
    }
  }

  // FIX #5: Query only by clinicId, filter dates in memory
  // → avoids needing a Firestore composite index
  Future<void> _loadAppointments() async {
    setState(() => _loading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _loading = false); return; }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('clinicId', isEqualTo: user.uid)
          .get();

      final f = _focus;
      final viewIdx = _tab.index; // 0=day,1=week,2=month
      late DateTime s, e;

      if (viewIdx == 0) {
        s = DateTime(f.year, f.month, f.day);
        e = s.add(const Duration(days: 1));
      } else if (viewIdx == 1) {
        s = f.subtract(Duration(days: f.weekday - 1));
        e = s.add(const Duration(days: 7));
      } else {
        s = DateTime(f.year, f.month, 1);
        e = DateTime(f.year, f.month + 1, 1);
      }

      final all = snap.docs.map((d) => CalendarAppointment.fromFirestore(d)).toList();
      final inRange = all.where((a) =>
      a.startTime.isAfter(s.subtract(const Duration(seconds: 1))) &&
          a.startTime.isBefore(e)).toList();

      if (mounted) setState(() { _all = inRange; _loading = false; });
    } catch (e) {
      debugPrint('appointments error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<CalendarAppointment> get _shown => _all.where((a) {
    if (!_filters.contains(a.type)) return false;
    if (_workerFilter.isNotEmpty &&
        !a.teamMembers.any((w) => _workerFilter.contains(w))) return false;
    if (_customTagFilter != null && _customTagFilter!.isNotEmpty &&
        (a.customTag ?? '').toLowerCase() != _customTagFilter!.toLowerCase()) return false;
    return true;
  }).toList();

  // ── Nav ───────────────────────────────────────────────────────────────────
  DateTime get _weekStart =>
      _focus.subtract(Duration(days: _focus.weekday - 1));

  /// Show Today only when NOT already on the current day/week/month
  bool get _showTodayButton {
    final now = DateTime.now();
    final idx = _tab.index;
    if (idx == 0) return !_sameDay(_focus, DateTime.now()); // day view: hide only when already on today
    if (idx == 1) {
      // week view: hide if current week contains today
      final ws = _weekStart;
      final we = ws.add(const Duration(days: 6));
      return !(now.isAfter(ws.subtract(const Duration(days: 1))) && now.isBefore(we.add(const Duration(days: 1))));
    }
    // month view: hide if same month+year
    return !(_focus.year == now.year && _focus.month == now.month);
  }

  String get _titleStr {
    final viewIdx = _tab.index;
    if (viewIdx == 0) return DateFormat('EEEE, d MMM y').format(_focus);
    if (viewIdx == 1) {
      final s = _weekStart;
      return '${DateFormat('d MMM').format(s)} – '
          '${DateFormat('d MMM y').format(s.add(const Duration(days: 6)))}';
    }
    return DateFormat('MMMM y').format(_focus);
  }

  void _go(int dir) {
    final idx = _tab.index;
    setState(() {
      if (idx == 0) _focus = _focus.add(Duration(days: dir));
      if (idx == 1) _focus = _focus.add(Duration(days: 7 * dir));
      if (idx == 2) _focus = DateTime(_focus.year, _focus.month + dir);
    });
    _loadAppointments();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────
  Future<void> _save(Map<String, dynamic> data, {String? id}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    data['clinicId'] = user.uid;

    // Handle recurrence
    final recurrence = data['recurrence'] as String? ?? 'none';
    final weekdays = data['weekdays'] as List<int>?;

    if (id == null && recurrence == 'weekly' && weekdays != null && weekdays.isNotEmpty) {
      // Generate recurring appointments for next 12 weeks (3 months)
      final recurrenceId = DateTime.now().millisecondsSinceEpoch.toString();
      final startTime = (data['startTime'] as Timestamp).toDate();
      final endTime = (data['endTime'] as Timestamp).toDate();
      final duration = endTime.difference(startTime);

      data['recurrenceId'] = recurrenceId;

      final batch = FirebaseFirestore.instance.batch();
      int count = 0;

      // Generate appointments for next 12 weeks
      for (int week = 0; week < 12; week++) {
        for (final weekday in weekdays) {
          // Find the next occurrence of this weekday
          DateTime nextOccurrence = startTime.add(Duration(days: week * 7));
          // Adjust to the target weekday (1=Monday, 7=Sunday)
          final currentWeekday = nextOccurrence.weekday;
          int daysToAdd = (weekday - currentWeekday) % 7;
          if (week == 0 && daysToAdd < 0) daysToAdd += 7;
          nextOccurrence = nextOccurrence.add(Duration(days: daysToAdd));

          final occurrenceStart = DateTime(
            nextOccurrence.year,
            nextOccurrence.month,
            nextOccurrence.day,
            startTime.hour,
            startTime.minute,
          );
          final occurrenceEnd = occurrenceStart.add(duration);

          final docData = Map<String, dynamic>.from(data);
          docData['startTime'] = Timestamp.fromDate(occurrenceStart);
          docData['endTime'] = Timestamp.fromDate(occurrenceEnd);
          docData['recurrenceEnd'] = Timestamp.fromDate(startTime.add(const Duration(days: 84))); // 12 weeks

          final docRef = FirebaseFirestore.instance.collection('appointments').doc();
          batch.set(docRef, docData);
          count++;
        }
      }

      await batch.commit();
      await _loadAppointments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✓ Created $count recurring appointments'),
          backgroundColor: const Color(0xFF7DD3C0),
        ));
      }
    } else {
      // Single appointment
      data['recurrence'] = 'none';
      if (id == null) {
        await FirebaseFirestore.instance.collection('appointments').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('appointments').doc(id).update(data);
      }
      await _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(id == null ? '✓ Appointment created' : '✓ Appointment updated'),
          backgroundColor: const Color(0xFF7DD3C0),
        ));
      }
    }
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance.collection('appointments').doc(id).delete();
    await _loadAppointments();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Appointment deleted'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ── Dialog launchers ──────────────────────────────────────────────────────
  void _openForm({DateTime? at, CalendarAppointment? apt}) {
    showDialog(
      context: context,
      builder: (_) => _FormDialog(
        initialDateTime: at ?? _focus,
        editing: apt,
        patients: _patients,
        workers: _workers,
        onSave: (data) => _save(data, id: apt?.id),
      ),
    );
  }

  void _openDetails(CalendarAppointment apt) {
    showDialog(
      context: context,
      builder: (_) => _DetailsDialog(
        apt: apt,
        onEdit: () { Navigator.pop(context); _openForm(apt: apt); },
        onDelete: () async { Navigator.pop(context); await _delete(apt.id); },
        onStatusChange: (newStatus) async {
          await FirebaseFirestore.instance
              .collection('appointments')
              .doc(apt.id)
              .update({'status': newStatus});
          await _loadAppointments();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Status updated to $newStatus'),
              backgroundColor: const Color(0xFF7DD3C0),
            ));
          }
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      // FIX #1: Explicit AppBar styling so font/color is never wrong
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DD3C0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: null, // use app default font, not system font
        ),
        toolbarTextStyle: const TextStyle(color: Colors.white),
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _FiltersDialog(
                selectedTypes: _filters,
                selectedWorkers: _workerFilter,
                customTagFilter: _customTagFilter,
                workers: _workers,
                onApply: (types, workers, tag) => setState(() {
                  _filters = types;
                  _workerFilter = workers;
                  _customTagFilter = tag;
                }),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _openForm(),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [Tab(text: 'Day'), Tab(text: 'Week'), Tab(text: 'Month')],
        ),
      ),
      body: Column(
        children: [
          // nav bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF333333)),
                onPressed: () => _go(-1),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _focus,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (d != null) { setState(() => _focus = d); _loadAppointments(); }
                  },
                  child: Text(
                    _titleStr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
              if (_showTodayButton)
                TextButton(
                  onPressed: () {
                    setState(() => _focus = DateTime.now());
                    _loadAppointments();
                  },
                  child: const Text('Today',
                      style: TextStyle(color: Color(0xFF7DD3C0), fontWeight: FontWeight.bold)),
                )
              else
                const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF333333)),
                onPressed: () => _go(1),
              ),
            ]),
          ),
          const Divider(height: 1),
          // views
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3C0)))
                : TabBarView(
              controller: _tab,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DayView(date: _focus, apts: _shown,
                    scroll: _scroll, onTap: _openDetails,
                    onSlot: (dt) => _openForm(at: dt)),
                _WeekView(weekStart: _weekStart, apts: _shown,
                    scroll: _scroll, onTap: _openDetails,
                    onSlot: (dt) => _openForm(at: dt)),
                _MonthView(focus: _focus, apts: _shown,
                    onDay: (d) {
                      setState(() => _focus = d);
                      _tab.animateTo(0);
                      _loadAppointments();
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared drawing helpers ───────────────────────────────────────────────────

double _top(DateTime t) =>
    ((t.hour - _kOpenHour) + t.minute / 60.0) * _kHourH;

double _h(DateTime s, DateTime e) =>
    e.difference(s).inMinutes / 60.0 * _kHourH;

// FIX #2: grid is exactly _kGridH tall inside a SingleChildScrollView
//         so it can never overflow the screen
Widget _gutter() => SizedBox(
  width: _kGutterW,
  child: Column(
    children: List.generate(_kCloseHour - _kOpenHour, (i) {
      final h = _kOpenHour + i;
      return SizedBox(
        height: _kHourH,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, top: 3),
            child: Text('${h.toString().padLeft(2, '0')}:00',
                style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
          ),
        ),
      );
    }),
  ),
);

Widget _lines() => Column(
  children: List.generate(_kCloseHour - _kOpenHour, (i) => Container(
    height: _kHourH,
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
    ),
  )),
);

Widget _chip(CalendarAppointment a, VoidCallback onTap) {
  // Clamp so chip never extends past the closing-hour boundary
  final maxH  = (_kGridH - _top(a.startTime)).clamp(20.0, _kGridH);
  final chipH = _h(a.startTime, a.endTime).clamp(20.0, maxH);
  final mins  = a.endTime.difference(a.startTime).inMinutes;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: chipH,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(3),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: a.color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: a.color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(a.patientName,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          if (chipH > 34)
            Flexible(
              child: Text(a.reason,
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          if (chipH > 52)
            Flexible(
              child: Text('${DateFormat('HH:mm').format(a.startTime)} – ${DateFormat('HH:mm').format(a.endTime)}',
                  style: const TextStyle(fontSize: 9, color: Colors.white60),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    ),
  );
}

class _NowLine extends StatelessWidget {
  final DateTime date;
  const _NowLine({required this.date});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    if (now.year != date.year || now.month != date.month || now.day != date.day) {
      return const SizedBox.shrink();
    }
    if (now.hour < _kOpenHour || now.hour >= _kCloseHour) return const SizedBox.shrink();
    return Positioned(
      top: _top(now),
      left: 0, right: 0,
      child: Row(children: [
        Container(width: 8, height: 8,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
        Expanded(child: Container(height: 2, color: Colors.red)),
      ]),
    );
  }
}

// ─── Day View ─────────────────────────────────────────────────────────────────
class _DayView extends StatelessWidget {
  final DateTime date;
  final List<CalendarAppointment> apts;
  final ScrollController scroll;
  final void Function(CalendarAppointment) onTap;
  final void Function(DateTime) onSlot;

  const _DayView({required this.date, required this.apts,
    required this.scroll, required this.onTap, required this.onSlot});

  @override
  Widget build(BuildContext context) {
    final isToday = _sameDay(date, DateTime.now());
    final dayApts = apts.where((a) => _sameDay(a.startTime, date)).toList();

    // FIX #2: Column(children: [header, Expanded(scrollable)])
    return Column(
      children: [
        Expanded(                          // <-- constrains height
          child: SingleChildScrollView(   // <-- scrolls the grid
            controller: scroll,
            child: SizedBox(
              height: _kGridH,            // <-- exact grid height, no overflow
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _gutter(),
                  Expanded(
                    child: GestureDetector(
                      onTapDown: (d) {
                        final h = (_kOpenHour + d.localPosition.dy / _kHourH).floor()
                            .clamp(_kOpenHour, _kCloseHour - 1);
                        final m = ((d.localPosition.dy % _kHourH) / _kHourH * 60).round();
                        onSlot(DateTime(date.year, date.month, date.day, h, m));
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.hardEdge,
                        children: [
                          _lines(),
                          ...dayApts.map((a) => Positioned(
                            top: _top(a.startTime), left: 0, right: 0,
                            child: _chip(a, () => onTap(a)),
                          )),
                          _NowLine(date: date),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Week View ────────────────────────────────────────────────────────────────
class _WeekView extends StatelessWidget {
  final DateTime weekStart;
  final List<CalendarAppointment> apts;
  final ScrollController scroll;
  final void Function(CalendarAppointment) onTap;
  final void Function(DateTime) onSlot;

  const _WeekView({required this.weekStart, required this.apts,
    required this.scroll, required this.onTap, required this.onSlot});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days  = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Column(
      children: [
        // day headers
        Row(children: [
          SizedBox(width: _kGutterW),
          ...days.map((d) {
            final isToday = _sameDay(d, today);
            return Expanded(child: Container(
              height: _kHeaderH,
              color: isToday ? const Color(0xFF7DD3C0).withOpacity(0.12) : Colors.white,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(DateFormat('EEE').format(d),
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: isToday ? const Color(0xFF7DD3C0) : const Color(0xFF666666),
                    )),
                const SizedBox(height: 2),
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: isToday ? const Color(0xFF7DD3C0) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('${d.day}',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : const Color(0xFF333333),
                      ))),
                ),
              ]),
            ));
          }),
        ]),
        const Divider(height: 1),
        // FIX #2: Expanded → SingleChildScrollView → SizedBox(height: _kGridH)
        Expanded(
          child: SingleChildScrollView(
            controller: scroll,
            child: SizedBox(
              height: _kGridH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _gutter(),
                  ...days.map((d) {
                    final da = apts.where((a) => _sameDay(a.startTime, d)).toList();
                    return Expanded(child: Container(
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: GestureDetector(
                        onTapDown: (det) {
                          final h = (_kOpenHour + det.localPosition.dy / _kHourH).floor()
                              .clamp(_kOpenHour, _kCloseHour - 1);
                          final m = ((det.localPosition.dy % _kHourH) / _kHourH * 60).round();
                          onSlot(DateTime(d.year, d.month, d.day, h, m));
                        },
                        child: SizedBox(
                          height: _kGridH,
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              _lines(),
                              ...da.map((a) => Positioned(
                                top: _top(a.startTime), left: 0, right: 0,
                                child: _chip(a, () => onTap(a)),
                              )),
                              _NowLine(date: d),
                            ],
                          ),
                        ),
                      ),
                    ));
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Month View ───────────────────────────────────────────────────────────────
class _MonthView extends StatelessWidget {
  final DateTime focus;
  final List<CalendarAppointment> apts;
  final void Function(DateTime) onDay;

  const _MonthView({required this.focus, required this.apts, required this.onDay});

  @override
  Widget build(BuildContext context) {
    final firstDay    = DateTime(focus.year, focus.month, 1);
    final daysInMonth = DateTime(focus.year, focus.month + 1, 0).day;
    final startWd     = firstDay.weekday; // 1=Mon
    final today       = DateTime.now();
    const hdr         = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    final cells = <Widget>[];
    for (var i = 1; i < startWd; i++) cells.add(const SizedBox.shrink());

    for (var day = 1; day <= daysInMonth; day++) {
      final d       = DateTime(focus.year, focus.month, day);
      final isToday = _sameDay(d, today);
      final da      = apts.where((a) => _sameDay(a.startTime, d)).toList();

      cells.add(GestureDetector(
        onTap: () => onDay(d),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFF7DD3C0).withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isToday ? const Color(0xFF7DD3C0) : Colors.grey.shade200,
              width: isToday ? 2 : 1,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF7DD3C0) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('$day',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: isToday ? Colors.white : const Color(0xFF333333),
                    ))),
              ),
            ),
            ...da.take(2).map((a) => Container(
              margin: const EdgeInsets.fromLTRB(3, 0, 3, 2),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: a.color.withOpacity(0.85),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(a.patientName,
                  style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
            if (da.length > 2)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text('+${da.length - 2} more',
                    style: const TextStyle(fontSize: 9, color: Color(0xFF999999))),
              ),
          ]),
        ),
      ));
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        Row(children: hdr.map((l) => Expanded(child: Center(child: Text(l,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF666666)))))).toList()),
        const SizedBox(height: 4),
        Expanded(child: GridView.count(crossAxisCount: 7, children: cells)),
      ]),
    );
  }
}

// ─── Details dialog ───────────────────────────────────────────────────────────
class _DetailsDialog extends StatelessWidget {
  final CalendarAppointment apt;
  final VoidCallback onEdit, onDelete;
  final void Function(String) onStatusChange;
  const _DetailsDialog({
    required this.apt,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: BoxDecoration(
          color: apt.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(apt.patientName,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(apt.status.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ])),
          IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
        ]),
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _r(Icons.category,         'Type',   apt.type),
        _r(Icons.medical_services, 'Reason', apt.reason),
        _r(Icons.play_arrow,       'Start',  DateFormat('EEE d MMM – HH:mm').format(apt.startTime)),
        _r(Icons.stop,             'End',    DateFormat('EEE d MMM – HH:mm').format(apt.endTime)),
        if (apt.notes?.isNotEmpty ?? false) _r(Icons.note, 'Notes', apt.notes!),
        if (apt.teamMembers.isNotEmpty) _r(Icons.people, 'Team', apt.teamMembers.join(', ')),
        if (apt.customTag?.isNotEmpty ?? false) _r(Icons.label, 'Tag', apt.customTag!),
      ]),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        IconButton(
          icon: const Icon(Icons.folder_open, color: Color(0xFF7DD3C0)),
          tooltip: 'Medical Record',
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening record for ${apt.patientName}…')));
          },
        ),
        Row(mainAxisSize: MainAxisSize.min, children: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF666666)),
            tooltip: 'Change Status',
            onSelected: (s) { onStatusChange(s); Navigator.pop(context); },
            itemBuilder: (_) => [
              _smi('confirmed', 'Confirmed', Colors.green),
              _smi('pending',   'Pending',   Colors.orange),
              _smi('completed', 'Completed', Colors.grey),
              _smi('cancelled', 'Cancelled', Colors.red),
              _smi('no-show',   'No-Show',   Colors.deepOrange),
            ],
          ),
          TextButton.icon(
              icon: const Icon(Icons.edit, color: Color(0xFF7DD3C0)),
              label: const Text('Edit', style: TextStyle(color: Color(0xFF7DD3C0))),
              onPressed: onEdit),
          TextButton.icon(
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete appointment?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                        onPressed: () { Navigator.pop(ctx); onDelete(); },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete')),
                  ],
                ),
              )),
        ]),
      ],
    );
  }

  Widget _r(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: const Color(0xFF7DD3C0)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
        Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
      ])),
    ]),
  );

  PopupMenuItem<String> _smi(String v, String label, Color c) =>
      PopupMenuItem<String>(
        value: v,
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label),
        ]),
      );
}

// ─── Appointment form dialog ──────────────────────────────────────────────────
class _FormDialog extends StatefulWidget {
  final DateTime initialDateTime;
  final CalendarAppointment? editing;
  final List<Map<String, dynamic>> patients;
  final List<Map<String, dynamic>> workers;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _FormDialog({
    required this.initialDateTime,
    required this.patients,
    required this.workers,
    required this.onSave,
    this.editing,
  });


  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _form        = GlobalKey<FormState>();
  final _searchCtrl  = TextEditingController();
  final _notesCtrl   = TextEditingController();

  String? _patientId, _patientName;
  String? _colleagueId, _colleagueName;
  String  _reason = _kReasons.first;
  String  _type   = 'appointment';
  String  _status = 'confirmed';
  Set<String> _selWorkers = {};
  late DateTime _start, _end;
  bool _saving = false;
  List<Map<String, dynamic>> _sugg = [];
  final _customTagCtrl = TextEditingController();

  // Recurrence
  String _recurrence = 'none'; // 'none' or 'weekly'
  Set<int> _weekdays = {};  // 1=Monday, 7=Sunday

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _start  = e?.startTime ?? _roundUpTo15(widget.initialDateTime);
    _end    = e?.endTime   ?? _roundUpTo15(widget.initialDateTime).add(const Duration(hours: 1));
    _reason = (_kReasons.contains(e?.reason)) ? e!.reason : _kReasons.first;
    _type   = e?.type   ?? 'appointment';
    _status = e?.status ?? 'confirmed';
    _notesCtrl.text = e?.notes ?? '';
    if (e != null) {
      if (e.type == 'shift') {
        _colleagueId   = e.patientId;
        _colleagueName = e.patientName;
      } else {
        _patientId   = e.patientId;
        _patientName = e.patientName;
        _searchCtrl.text = e.patientName;
      }
      _selWorkers = Set.from(e.teamMembers);
      _customTagCtrl.text = e.customTag ?? '';
    }
    _searchCtrl.addListener(_search);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _notesCtrl.dispose();
    _customTagCtrl.dispose();
    super.dispose();
  }

  /// Always rounds a DateTime up to the next :00/:15/:30/:45 slot
  static DateTime _roundUpTo15(DateTime dt) {
    final m = dt.minute;
    final snapped = ((m / 15).ceil() * 15);
    if (snapped >= 60) {
      return DateTime(dt.year, dt.month, dt.day, dt.hour + 1, 0);
    }
    return DateTime(dt.year, dt.month, dt.day, dt.hour, snapped);
  }

  // Extract display name from a patient record regardless of field layout
  String _patientDisplayName(Map<String, dynamic> p) {
    if (p['firstName'] != null || p['lastName'] != null) {
      return '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim();
    }
    if (p['name'] != null) return p['name'] as String;
    if (p['displayName'] != null) return p['displayName'] as String;
    if (p['fullName'] != null) return p['fullName'] as String;
    return p['email'] as String? ?? p['id'] as String? ?? '';
  }

  void _search() {
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) {
      setState(() { _sugg = []; });
      // Don't clear _patientId here — user might be re-typing an already-selected name
      return;
    }
    setState(() {
      _sugg = widget.patients.where((p) {
        final n = _patientDisplayName(p).toLowerCase();
        return n.contains(q);
      }).take(8).toList();
    });
  }

  void _pick(Map<String, dynamic> p) {
    final n = _patientDisplayName(p);
    setState(() {
      _patientId   = p['id'] as String;
      _patientName = n;
      _searchCtrl.text = n;
      _sugg = [];
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickTime(bool isStart) async {
    final init = isStart ? _start : _end;

    // Step 1: pick the date
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d == null || !mounted) return;

    // Step 2: pick hour + 15-min slot via custom dialog
    final t = await showDialog<TimeOfDay>(
      context: context,
      builder: (_) => _QuarterHourPickerDialog(initial: init),
    );
    if (t == null || !mounted) return;

    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() {
      if (isStart) {
        _start = dt;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = dt;
      }
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final isShift = _type == 'shift';
    if (isShift && (_colleagueId == null || _colleagueId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a colleague')));
      return;
    }
    if (!isShift && (_patientId == null || _patientId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a patient from the list')));
      return;
    }

    // Validate recurrence
    if (_recurrence == 'weekly' && _weekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one day for weekly recurrence')));
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave({
        'patientId':   _type == 'shift' ? _colleagueId : _patientId,
        'patientName': _type == 'shift' ? _colleagueName : _patientName,
        'reason':      _reason,
        'type':        _type,
        'status':      _status,
        'startTime':   Timestamp.fromDate(_start),
        'endTime':     Timestamp.fromDate(_end),
        'notes':       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'teamMembers': _selWorkers.toList(),
        'customTag':   _customTagCtrl.text.trim().isEmpty ? null : _customTagCtrl.text.trim(),
        'color':       _colorForType(_type),
        'recurrence':  _recurrence,
        'weekdays':    _recurrence == 'weekly' ? _weekdays.toList() : null,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF666666)),
    prefixIcon: Icon(icon, color: const Color(0xFF7DD3C0), size: 20),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    filled: true,
    fillColor: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.editing == null ? 'New Appointment' : 'Edit Appointment',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      content: Form(
        key: _form,
        child: SizedBox(
          width: 380,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [

            // ── Patient (non-shift) or Colleague (shift) ────────────────────
            if (_type == 'shift') ...[
              // Colleague dropdown from workers list
              DropdownButtonFormField<String>(
                value: _colleagueId,
                decoration: _dec('Colleague', Icons.people),
                hint: const Text('Select colleague'),
                dropdownColor: Colors.white,
                validator: (_) => (_colleagueId == null) ? 'Select a colleague' : null,
                items: widget.workers.map((w) {
                  final wId   = w['id'] as String;
                  final wName = ((w['firstName'] ?? '') + ' ' + (w['lastName'] ?? '')).trim();
                  return DropdownMenuItem<String>(value: wId, child: Text(wName));
                }).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  final w = widget.workers.firstWhere((w) => w['id'] == v);
                  setState(() {
                    _colleagueId   = v;
                    _colleagueName = ((w['firstName'] ?? '') + ' ' + (w['lastName'] ?? '')).trim();
                  });
                },
              ),
            ] else ...[
              // Patient typeahead search
              TextFormField(
                controller: _searchCtrl,
                decoration: _dec('Patient', Icons.person_search),
                validator: (_) => (_patientId == null || _patientId!.isEmpty)
                    ? 'Select a patient from the list' : null,
              ),
              if (_sugg.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 2, bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF7DD3C0).withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8)],
                  ),
                  child: Column(children: _sugg.map((p) {
                    final n = _patientDisplayName(p);
                    return InkWell(
                      onTap: () => _pick(p),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(children: [
                          const Icon(Icons.person, size: 16, color: Color(0xFF7DD3C0)),
                          const SizedBox(width: 8),
                          Text(n, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
                        ]),
                      ),
                    );
                  }).toList()),
                ),
            ],
            const SizedBox(height: 12),

            // ── Type ──────────────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _type,
              decoration: _dec('Type', Icons.category),
              dropdownColor: Colors.white,
              items: const [
                DropdownMenuItem(value: 'appointment', child: Text('Appointment')),
                DropdownMenuItem(value: 'shift',       child: Text('Shift')),
                DropdownMenuItem(value: 'holiday',     child: Text('Holiday')),
                DropdownMenuItem(value: 'break',       child: Text('Break')),
              ],
              onChanged: (v) {
                setState(() {
                  _type = v!;
                  // Clear fields that don't apply to the new type
                  if (_type == 'shift') {
                    _patientId = null; _patientName = null; _searchCtrl.clear(); _sugg = [];
                  } else {
                    _colleagueId = null; _colleagueName = null;
                  }
                });
              },
            ),
            const SizedBox(height: 12),

            // ── FIX #4: Reason dropdown ────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _reason,
              decoration: _dec('Reason', Icons.medical_services),
              dropdownColor: Colors.white,
              items: _kReasons.map((r) =>
                  DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) => setState(() => _reason = v!),
            ),
            const SizedBox(height: 12),

            // ── Status ────────────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _status,
              decoration: _dec('Status', Icons.check_circle_outline),
              dropdownColor: Colors.white,
              items: const [
                DropdownMenuItem(value: 'confirmed',  child: Text('Confirmed')),
                DropdownMenuItem(value: 'pending',    child: Text('Pending')),
                DropdownMenuItem(value: 'completed',  child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled',  child: Text('Cancelled')),
                DropdownMenuItem(value: 'no-show',    child: Text('No-Show')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 12),

            // ── Start / End time ──────────────────────────────────────────
            Row(children: [
              Expanded(child: _timeTile('Start', _start, () => _pickTime(true),
                  const Color(0xFF7DD3C0))),
              const SizedBox(width: 8),
              Expanded(child: _timeTile('End', _end, () => _pickTime(false),
                  const Color(0xFFE74C3C))),
            ]),
            const SizedBox(height: 12),

            // ── Recurrence (only for new appointments) ─────────────────────────
            if (widget.editing == null) ...[
              DropdownButtonFormField<String>(
                value: _recurrence,
                decoration: _dec('Repeat', Icons.repeat),
                dropdownColor: Colors.white,
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('Does not repeat')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (v) => setState(() {
                  _recurrence = v ?? 'none';
                  if (_recurrence == 'none') _weekdays.clear();
                }),
              ),

              if (_recurrence == 'weekly') ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Repeat on',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    _dayChip(1, 'Mon'), _dayChip(2, 'Tue'), _dayChip(3, 'Wed'),
                    _dayChip(4, 'Thu'), _dayChip(5, 'Fri'), _dayChip(6, 'Sat'), _dayChip(7, 'Sun'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Creates appointments for the next 12 weeks',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF999999), fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 12),
            ],

            // ── Team members ─────────────────────────────────────────────
            if (widget.workers.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Team Members',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: widget.workers.map((w) {
                  final wId   = w['id'] as String;
                  final wName = ((w['firstName'] ?? '') + ' ' + (w['lastName'] ?? '')).trim();
                  final on    = _selWorkers.contains(wId);
                  return GestureDetector(
                    onTap: () => setState(() => on ? _selWorkers.remove(wId) : _selWorkers.add(wId)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: on ? const Color(0xFF7DD3C0).withOpacity(0.15) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: on ? const Color(0xFF7DD3C0) : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.person, size: 14, color: on ? const Color(0xFF7DD3C0) : Colors.grey),
                        const SizedBox(width: 4),
                        Text(wName, style: TextStyle(
                          fontSize: 13,
                          fontWeight: on ? FontWeight.bold : FontWeight.normal,
                          color: on ? const Color(0xFF7DD3C0) : const Color(0xFF555555),
                        )),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // ── Custom tag ─────────────────────────────────────────────────
            TextFormField(
              controller: _customTagCtrl,
              decoration: _dec('Tag (optional, e.g. VIP / Urgent)', Icons.label_outline),
            ),
            const SizedBox(height: 12),

            // ── Notes ─────────────────────────────────────────────────────────
            TextFormField(
              controller: _notesCtrl,
              decoration: _dec('Notes (optional)', Icons.note_alt),
              maxLines: 3,
            ),
            const SizedBox(height: 4),
          ])),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF999999)))),
        ElevatedButton(
          onPressed: _saving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7DD3C0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _saving
              ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _timeTile(String label, DateTime dt, VoidCallback onTap, Color accent) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCCCCCC)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: accent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(DateFormat('d MMM').format(dt),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          Text(DateFormat('HH:mm').format(dt),
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
        ]),
      ),
    );
  }

  Widget _dayChip(int weekday, String label) {
    final selected = _weekdays.contains(weekday);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) _weekdays.remove(weekday);
        else _weekdays.add(weekday);
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7DD3C0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF7DD3C0) : const Color(0xFFCCCCCC),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

// ─── Quarter-hour time picker ─────────────────────────────────────────────────
/// A custom time picker that only allows :00 / :15 / :30 / :45 minute slots.
class _QuarterHourPickerDialog extends StatefulWidget {
  final DateTime initial;
  const _QuarterHourPickerDialog({required this.initial});
  @override
  State<_QuarterHourPickerDialog> createState() => _QuarterHourPickerDialogState();
}

class _QuarterHourPickerDialogState extends State<_QuarterHourPickerDialog> {
  late int _hour;
  late int _minute; // always 0, 15, 30, or 45

  static const _slots = [0, 15, 30, 45];

  // Text-entry controllers
  late TextEditingController _hourCtrl;
  late TextEditingController _minCtrl;

  // Scroll wheel controllers — recreated when wheels need to jump to a new position
  late FixedExtentScrollController _hourWheel;
  late FixedExtentScrollController _minWheel;

  @override
  void initState() {
    super.initState();
    _initFromDateTime(widget.initial);
  }

  void _initFromDateTime(DateTime dt) {
    final m       = dt.minute;
    final snapped = ((m / 15).ceil() * 15);
    if (snapped >= 60) {
      _hour   = (dt.hour + 1) % 24;
      _minute = 0;
    } else {
      _hour   = dt.hour;
      _minute = snapped;
    }
    _hourCtrl = TextEditingController(text: _hour.toString().padLeft(2, '0'));
    _minCtrl  = TextEditingController(text: _minute.toString().padLeft(2, '0'));
    _hourWheel = FixedExtentScrollController(initialItem: _hour);
    _minWheel  = FixedExtentScrollController(initialItem: _slots.indexOf(_minute));
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    _hourWheel.dispose();
    _minWheel.dispose();
    super.dispose();
  }

  /// Round any minute value UP to the nearest 15-min slot (0/15/30/45).
  int _roundMinUp(int m) {
    if (m <= 0)  return 0;
    if (m <= 15) return 15;
    if (m <= 30) return 30;
    if (m <= 45) return 45;
    return 60; // caller must carry over to next hour
  }

  /// Called when user finishes typing in the hour field.
  void _commitHour() {
    final v = int.tryParse(_hourCtrl.text.trim()) ?? _hour;
    setState(() {
      _hour = v.clamp(0, 23);
      _hourCtrl.text = _hour.toString().padLeft(2, '0');
    });
    _hourWheel.jumpToItem(_hour);
  }

  /// Called when user finishes typing in the minute field.
  void _commitMinute() {
    final raw     = int.tryParse(_minCtrl.text.trim()) ?? _minute;
    final snapped = _roundMinUp(raw.clamp(0, 59));
    if (snapped >= 60) {
      // Roll over to next hour
      setState(() {
        _hour   = (_hour + 1) % 24;
        _minute = 0;
        _hourCtrl.text = _hour.toString().padLeft(2, '0');
        _minCtrl.text  = '00';
      });
      _hourWheel.jumpToItem(_hour);
      _minWheel.jumpToItem(0);
    } else {
      setState(() {
        _minute       = snapped;
        _minCtrl.text = _minute.toString().padLeft(2, '0');
      });
      _minWheel.jumpToItem(_slots.indexOf(_minute));
    }
  }

  InputDecoration _fieldDec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    counterText: '',
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Select Time',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Type-in row ─────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hourCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    textAlign: TextAlign.center,
                    decoration: _fieldDec('HH'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                    onSubmitted: (_) => _commitHour(),
                    onTapOutside: (_) => _commitHour(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                ),
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    textAlign: TextAlign.center,
                    decoration: _fieldDec('MM'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                    onSubmitted: (_) => _commitMinute(),
                    onTapOutside: (_) => _commitMinute(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Minutes snap to :00  :15  :30  :45',
              style: TextStyle(fontSize: 10, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 16),
            // ── Scroll wheels ───────────────────────────────────────────────
            Row(
              children: [
                // Hour wheel
                Expanded(
                  child: Column(
                    children: [
                      const Text('Hour',
                          style: TextStyle(fontSize: 11, color: Color(0xFF999999), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          perspective: 0.003,
                          diameterRatio: 1.5,
                          physics: const FixedExtentScrollPhysics(),
                          controller: _hourWheel,
                          onSelectedItemChanged: (i) {
                            setState(() {
                              _hour = i;
                              _hourCtrl.text = _hour.toString().padLeft(2, '0');
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 24,
                            builder: (ctx, i) => Center(
                              child: Text(
                                i.toString().padLeft(2, '0'),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: _hour == i ? FontWeight.bold : FontWeight.normal,
                                  color: _hour == i
                                      ? const Color(0xFF7DD3C0)
                                      : const Color(0xFF333333),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 22),
                  child: Text(':',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                ),
                const SizedBox(width: 8),
                // Minute wheel — only 4 items
                Expanded(
                  child: Column(
                    children: [
                      const Text('Minute',
                          style: TextStyle(fontSize: 11, color: Color(0xFF999999), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListWheelScrollView(
                          itemExtent: 40,
                          perspective: 0.003,
                          diameterRatio: 1.5,
                          physics: const FixedExtentScrollPhysics(),
                          controller: _minWheel,
                          onSelectedItemChanged: (i) {
                            setState(() {
                              _minute       = _slots[i];
                              _minCtrl.text = _minute.toString().padLeft(2, '0');
                            });
                          },
                          children: _slots
                              .map((m) => Center(
                            child: Text(
                              m.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight:
                                _minute == m ? FontWeight.bold : FontWeight.normal,
                                color: _minute == m
                                    ? const Color(0xFF7DD3C0)
                                    : const Color(0xFF333333),
                              ),
                            ),
                          ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Color(0xFF999999))),
        ),
        ElevatedButton(
          onPressed: () {
            // Commit any pending typed values before confirming
            _commitHour();
            _commitMinute();
            Navigator.pop(context, TimeOfDay(hour: _hour, minute: _minute));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7DD3C0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Confirm',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ─── Filters dialog ───────────────────────────────────────────────────────────
class _FiltersDialog extends StatefulWidget {
  final Set<String> selectedTypes;
  final Set<String> selectedWorkers;
  final String?     customTagFilter;
  final List<Map<String, dynamic>> workers;
  final void Function(Set<String> types, Set<String> workers, String? tag) onApply;

  const _FiltersDialog({
    required this.selectedTypes,
    required this.selectedWorkers,
    required this.customTagFilter,
    required this.workers,
    required this.onApply,
  });

  @override
  State<_FiltersDialog> createState() => _FiltersDialogState();
}

class _FiltersDialogState extends State<_FiltersDialog> {
  late Set<String> _types;
  late Set<String> _workers;
  late TextEditingController _tagCtrl;

  @override
  void initState() {
    super.initState();
    _types   = Set.from(widget.selectedTypes);
    _workers = Set.from(widget.selectedWorkers);
    _tagCtrl = TextEditingController(text: widget.customTagFilter ?? '');
  }

  @override
  void dispose() { _tagCtrl.dispose(); super.dispose(); }

  Widget _typeChip(String v, String label, Color c) {
    final on = _types.contains(v);
    return GestureDetector(
      onTap: () => setState(() => on ? _types.remove(v) : _types.add(v)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: on ? c.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? c : Colors.grey.shade300, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            fontWeight: on ? FontWeight.bold : FontWeight.normal,
            color: on ? c : const Color(0xFF666666),
          )),
        ]),
      ),
    );
  }

  Widget _workerChip(Map<String, dynamic> w) {
    final wId   = w['id'] as String;
    final wName = ((w['firstName'] ?? '') + ' ' + (w['lastName'] ?? '')).trim();
    final on    = _workers.contains(wId);
    return GestureDetector(
      onTap: () => setState(() => on ? _workers.remove(wId) : _workers.add(wId)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: on ? const Color(0xFF4A90E2).withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? const Color(0xFF4A90E2) : Colors.grey.shade300, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.person, size: 14, color: on ? const Color(0xFF4A90E2) : Colors.grey),
          const SizedBox(width: 4),
          Text(wName, style: TextStyle(
            fontSize: 13,
            fontWeight: on ? FontWeight.bold : FontWeight.normal,
            color: on ? const Color(0xFF4A90E2) : const Color(0xFF555555),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Filter Calendar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Show',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _typeChip('appointment', 'Appointments', const Color(0xFF7DD3C0)),
                _typeChip('shift',       'Shifts',       const Color(0xFF4A90E2)),
                _typeChip('holiday',     'Holidays',     const Color(0xFFE74C3C)),
                _typeChip('break',       'Breaks',       const Color(0xFFF39C12)),
              ]),
              if (widget.workers.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Team Member',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                const SizedBox(height: 4),
                const Text('Empty = show all',
                    style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: widget.workers.map(_workerChip).toList()),
              ],
              const SizedBox(height: 16),
              const Text('Custom Tag',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              const SizedBox(height: 4),
              const Text('Leave empty to show all',
                  style: TextStyle(fontSize: 11, color: Color(0xFF999999))),
              const SizedBox(height: 8),
              TextField(
                controller: _tagCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. VIP, Urgent…',
                  prefixIcon: const Icon(Icons.label_outline, size: 18, color: Color(0xFF7DD3C0)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _types = {'appointment','shift','holiday','break'};
            _workers = {};
            _tagCtrl.clear();
          }),
          child: const Text('Reset All'),
        ),
        ElevatedButton(
          onPressed: () {
            final tag = _tagCtrl.text.trim().isEmpty ? null : _tagCtrl.text.trim();
            widget.onApply(_types, _workers, tag);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7DD3C0)),
          child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ─── Util ─────────────────────────────────────────────────────────────────────
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;