import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'BookAppointmentPage.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models (mirror exactly what EditClinicPage saves)
// ─────────────────────────────────────────────────────────────────────────────

class _TeamMember {
  final String name, role, experience;
  final List<String> specializations;
  final String? photoUrl;
  const _TeamMember({required this.name, this.role = '', this.experience = '',
    this.specializations = const [], this.photoUrl});
  factory _TeamMember.fromMap(Map<String, dynamic> m) => _TeamMember(
    name: m['name'] as String? ?? '',
    role: m['role'] as String? ?? '',
    experience: m['experience'] as String? ?? '',
    specializations: List<String>.from(m['specializations'] as List? ?? []),
    photoUrl: m['photoUrl'] as String?,
  );
}

class _GalleryCategory {
  final String name;
  final List<String> photoUrls;
  const _GalleryCategory({required this.name, this.photoUrls = const []});
  factory _GalleryCategory.fromMap(Map<String, dynamic> m) => _GalleryCategory(
    name: m['name'] as String? ?? '',
    photoUrls: List<String>.from(m['photoUrls'] as List? ?? []),
  );
}

class _DayHours {
  final bool open, hasBreak;
  final String start1, end1, start2, end2;
  const _DayHours({this.open = true, this.hasBreak = false,
    this.start1 = '09:00', this.end1 = '17:00',
    this.start2 = '16:00', this.end2 = '20:00'});
  factory _DayHours.fromMap(Map<String, dynamic> m) => _DayHours(
    open: m['open'] as bool? ?? true,
    hasBreak: m['hasBreak'] as bool? ?? false,
    start1: m['start1'] as String? ?? '09:00',
    end1:   m['end1']   as String? ?? '17:00',
    start2: m['start2'] as String? ?? '16:00',
    end2:   m['end2']   as String? ?? '20:00',
  );
  String get display {
    if (!open) return 'Closed';
    if (!hasBreak) return '$start1 – $end1';
    return '$start1 – $end1,  $start2 – $end2';
  }
}

const _kDays = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class ClinicProfilePage extends StatefulWidget {
  /// The Firestore document ID of the clinic (= clinic user's UID).
  final String clinicId;

  const ClinicProfilePage({super.key, required this.clinicId});

  @override
  State<ClinicProfilePage> createState() => _ClinicProfilePageState();
}

class _ClinicProfilePageState extends State<ClinicProfilePage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  bool _loading = true;

  // Loaded fields
  String _clinicName  = '';
  String _subtitle    = '';   // e.g. "Dental Specialist"
  String? _logoUrl;
  String _about       = '';
  String _address     = '';
  String _phone       = '';
  String _email       = '';

  List<String>          _technologies   = [];
  List<String>          _certUrls       = [];
  List<String>          _insurances     = [];
  List<String>          _paymentMethods = [];
  List<String>          _languages      = [];
  List<String>          _parking        = [];
  List<String>          _services       = [];
  List<_TeamMember>     _team           = [];
  List<_GalleryCategory>_gallery        = [];
  Map<String, _DayHours>_hours          = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicId)
          .get();
      final d = doc.data() ?? {};

      final hoursMap = d['openingHours'] as Map<String, dynamic>? ?? {};
      final Map<String, _DayHours> hours = {};
      for (final day in _kDays) {
        if (hoursMap.containsKey(day)) {
          hours[day] = _DayHours.fromMap(
              Map<String, dynamic>.from(hoursMap[day] as Map));
        } else {
          hours[day] = const _DayHours(open: false);
        }
      }

      setState(() {
        _clinicName     = d['clinicName']   as String? ?? '';
        _subtitle       = d['subtitle']     as String? ?? 'Dental Clinic';
        _logoUrl        = d['logoUrl']      as String?;
        _about          = d['about']        as String? ?? '';
        _address        = d['address']      as String? ?? '';
        _phone          = d['phone']        as String? ?? '';
        _email          = d['email']        as String? ?? '';
        _technologies   = List<String>.from(d['technologies']   as List? ?? []);
        _certUrls       = List<String>.from(d['certificates']   as List? ?? []);
        _insurances     = List<String>.from(d['insurances']     as List? ?? []);
        _paymentMethods = List<String>.from(d['paymentMethods'] as List? ?? []);
        _languages      = List<String>.from(d['languages']      as List? ?? []);
        _parking        = List<String>.from(d['parking']        as List? ?? []);
        _services       = List<String>.from(d['services']       as List? ?? []);
        _team    = (d['team']    as List? ?? []).map((e) => _TeamMember.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        _gallery = (d['gallery'] as List? ?? []).map((e) => _GalleryCategory.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        _hours   = hours;
        _loading = false;
      });
    } catch (e) {
      debugPrint('ClinicProfilePage load error: $e');
      setState(() => _loading = false);
    }
  }

  // ── URL launchers ──────────────────────────────────────────────────────────

  Future<void> _launchPhone(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/972$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp not available'), backgroundColor: Color(0xFFFF6B6B)));
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _showNavOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Wrap(children: [
            ListTile(
              leading: const Icon(Icons.map, color: Color(0xFF7DD3C0)),
              title: const Text('Google Maps'),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(_address)}');
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation, color: Color(0xFF7DD3C0)),
              title: const Text('Waze'),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse('https://waze.com/ul?q=${Uri.encodeComponent(_address)}');
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          ]),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3C0)))
          : NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: const Color(0xFF7DD3C0),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _clinicName));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Clinic name copied')));
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _buildHeroSection()),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: const Color(0xFFF2EBE2),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xFF7DD3C0),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF7DD3C0),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [
                    Tab(text: 'About'),
                    Tab(text: 'Team'),
                    Tab(text: 'Services'),
                    Tab(text: 'Gallery'),
                    Tab(text: 'Contact'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAboutTab(),
            _buildTeamTab(),
            _buildServicesTab(),
            _buildGalleryTab(),
            _buildContactTab(),
          ],
        ),
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHeroSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            // Logo
            Container(
              width: 100, height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _logoUrl != null
                    ? Image.network(_logoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 48, color: Color(0xFF7DD3C0)))
                    : const Icon(Icons.business, size: 48, color: Color(0xFF7DD3C0)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _clinicName.isNotEmpty ? _clinicName : 'Clinic',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              _subtitle,
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: _quickBtn(Icons.phone, 'Call',
                        () => _launchPhone(_phone))),
                const SizedBox(width: 12),
                Expanded(child: _quickBtn(Icons.chat, 'WhatsApp',
                        () => _launchWhatsApp(_phone))),
                const SizedBox(width: 12),
                Expanded(child: _quickBtn(Icons.calendar_today, 'Book', () {
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const BookAppointmentPage()));
                })),
                const SizedBox(width: 12),
                Expanded(child: _quickBtn(Icons.map, 'Map',
                        () => _showNavOptions())),
              ]),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _quickBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: const Color(0xFF7DD3C0), size: 24),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon) => Row(children: [
    Icon(icon, color: const Color(0xFF7DD3C0), size: 22),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
  ]);

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
    child: child,
  );

  Widget _infoRow(String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF999999)))),
      Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333)))),
    ],
  );

  // ── TAB 1: About ───────────────────────────────────────────────────────────

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // About text
        if (_about.isNotEmpty) ...[
          _sectionTitle('About Us', Icons.info_outline),
          const SizedBox(height: 12),
          _card(Text(_about, style: const TextStyle(fontSize: 15, color: Color(0xFF666666), height: 1.6))),
          const SizedBox(height: 24),
        ],

        // Technology — show each selected tech as an icon card
        if (_technologies.isNotEmpty) ...[
          _sectionTitle('Technology & Equipment', Icons.computer_outlined),
          const SizedBox(height: 12),
          ..._technologies.map((tech) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFA8E6CF).withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Icon(_techIcon(tech), color: const Color(0xFF7DD3C0), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(tech, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333)))),
            ]),
          )),
          const SizedBox(height: 24),
        ],

        // Certificates
        if (_certUrls.isNotEmpty) ...[
          _sectionTitle('Certifications & Awards', Icons.workspace_premium_outlined),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1),
            itemCount: _certUrls.length,
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => showDialog(context: context, builder: (_) => Dialog(
                  child: InteractiveViewer(child: Image.network(_certUrls[i])))),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
                child: ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: Image.network(_certUrls[i], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.workspace_premium, color: Color(0xFF7DD3C0)))),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Insurance & Payment
        if (_insurances.isNotEmpty || _paymentMethods.isNotEmpty) ...[
          _sectionTitle('Insurance & Payment', Icons.account_balance_wallet),
          const SizedBox(height: 12),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_insurances.isNotEmpty) ...[
              _infoRow('Insurance', _insurances.join(', ')),
              if (_paymentMethods.isNotEmpty) const Divider(height: 20),
            ],
            if (_paymentMethods.isNotEmpty)
              _infoRow('Payment', _paymentMethods.join(', ')),
          ])),
          const SizedBox(height: 24),
        ],

        // Languages
        if (_languages.isNotEmpty) ...[
          _sectionTitle('Languages Spoken', Icons.language),
          const SizedBox(height: 12),
          _card(Wrap(spacing: 8, runSpacing: 8,
            children: _languages.map((lang) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFFA8E6CF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16)),
              child: Text(lang, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7DD3C0))),
            )).toList(),
          )),
          const SizedBox(height: 24),
        ],

        // Parking & Accessibility
        if (_parking.isNotEmpty) ...[
          _sectionTitle('Parking & Accessibility', Icons.local_parking),
          const SizedBox(height: 12),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: _parking.asMap().entries.map((e) => Column(children: [
              _infoRow(e.key == 0 ? 'Features' : '', e.value),
              if (e.key < _parking.length - 1) const Divider(height: 16),
            ])).toList(),
          )),
          const SizedBox(height: 20),
        ],

        if (_about.isEmpty && _technologies.isEmpty && _certUrls.isEmpty &&
            _insurances.isEmpty && _languages.isEmpty && _parking.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text('No information added yet.', style: TextStyle(color: Color(0xFF999999))),
          )),
      ]),
    );
  }

  IconData _techIcon(String t) {
    if (t.contains('X-Ray'))           return Icons.camera_alt;
    if (t.contains('3D') || t.contains('CBCT')) return Icons.view_in_ar;
    if (t.contains('Laser'))           return Icons.lightbulb;
    if (t.contains('CAD'))             return Icons.precision_manufacturing;
    if (t.contains('Camera'))          return Icons.videocam;
    if (t.contains('Impres'))          return Icons.fingerprint;
    if (t.contains('Abras'))           return Icons.air;
    if (t.contains('Piezo'))           return Icons.electric_bolt;
    if (t.contains('Ozone'))           return Icons.bubble_chart;
    return Icons.computer;
  }

  // ── TAB 2: Team ────────────────────────────────────────────────────────────

  Widget _buildTeamTab() {
    if (_team.isEmpty) {
      return const Center(child: Text('No team members added yet.',
          style: TextStyle(color: Color(0xFF999999))));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _team.length,
      itemBuilder: (context, i) {
        final m = _team[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
          child: Row(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFA8E6CF).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                image: m.photoUrl != null
                    ? DecorationImage(image: NetworkImage(m.photoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: m.photoUrl == null
                  ? const Icon(Icons.person, size: 40, color: Color(0xFF7DD3C0))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              const SizedBox(height: 4),
              if (m.role.isNotEmpty) Text(m.role, style: const TextStyle(fontSize: 14, color: Color(0xFF7DD3C0), fontWeight: FontWeight.w600)),
              if (m.experience.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(m.experience, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ],
              if (m.specializations.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6,
                  children: m.specializations.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFA8E6CF).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                  )).toList(),
                ),
              ],
            ])),
          ]),
        );
      },
    );
  }

  // ── TAB 3: Services ────────────────────────────────────────────────────────

  Widget _buildServicesTab() {
    if (_services.isEmpty) {
      return const Center(child: Text('No services added yet.',
          style: TextStyle(color: Color(0xFF999999))));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2),
      itemCount: _services.length,
      itemBuilder: (context, i) {
        final s = _services[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFA8E6CF).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Icon(_svcIcon(s), color: const Color(0xFF7DD3C0), size: 32),
            ),
            const SizedBox(height: 12),
            Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        );
      },
    );
  }

  IconData _svcIcon(String s) {
    if (s.contains('Clean'))           return Icons.cleaning_services;
    if (s.contains('Whiten'))          return Icons.auto_awesome;
    if (s.contains('Impl'))            return Icons.construction;
    if (s.contains('Root'))            return Icons.healing;
    if (s.contains('Veneer'))          return Icons.diamond;
    if (s.contains('Ortho') || s.contains('Invis')) return Icons.straighten;
    if (s.contains('Pediat'))          return Icons.child_care;
    if (s.contains('Emerg'))           return Icons.emergency;
    if (s.contains('Sedat'))           return Icons.bedtime;
    return Icons.medical_services;
  }

  // ── TAB 4: Gallery ─────────────────────────────────────────────────────────

  Widget _buildGalleryTab() {
    if (_gallery.isEmpty) {
      return const Center(child: Text('No photos added yet.',
          style: TextStyle(color: Color(0xFF999999))));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _gallery.length,
      itemBuilder: (context, catIndex) {
        final cat = _gallery[catIndex];
        if (cat.photoUrls.isEmpty) return const SizedBox.shrink();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text(cat.name, style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFA8E6CF).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text('${cat.photoUrls.length} photos',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7DD3C0))),
              ),
            ]),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1),
            itemCount: cat.photoUrls.length,
            itemBuilder: (context, photoIndex) => GestureDetector(
              onTap: () => showDialog(context: context, builder: (_) => Dialog(
                  child: InteractiveViewer(child: Image.network(cat.photoUrls[photoIndex])))),
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
                child: ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: Image.network(cat.photoUrls[photoIndex], fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey))),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]);
      },
    );
  }

  // ── TAB 5: Contact ─────────────────────────────────────────────────────────

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Opening hours
        _sectionTitle('Opening Hours', Icons.access_time),
        const SizedBox(height: 12),
        _card(Column(children: _kDays.map((day) {
          final h = _hours[day] ?? const _DayHours(open: false);
          final isToday = _isToday(day);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(day, style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? const Color(0xFF7DD3C0) : const Color(0xFF666666),
              )),
              Text(h.display, style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                color: isToday ? const Color(0xFF7DD3C0) : const Color(0xFF333333),
              )),
            ]),
          );
        }).toList())),
        const SizedBox(height: 24),

        // Contact info
        _sectionTitle('Contact Info', Icons.contact_mail),
        const SizedBox(height: 12),
        if (_address.isNotEmpty) ...[
          _contactRow(Icons.location_on, 'Address', _address, () => _showNavOptions()),
          const SizedBox(height: 12),
        ],
        if (_phone.isNotEmpty) ...[
          _contactRow(Icons.phone, 'Phone', _phone, () => _launchPhone(_phone)),
          const SizedBox(height: 12),
        ],
        if (_email.isNotEmpty)
          _contactRow(Icons.email, 'Email', _email, () => _launchEmail(_email)),
        const SizedBox(height: 20),
      ]),
    );
  }

  bool _isToday(String day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days.indexOf(day) == DateTime.now().weekday - 1;
  }

  Widget _contactRow(IconData icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFA8E6CF).withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFF7DD3C0), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          ])),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF7DD3C0)),
        ]),
      ),
    );
  }
}