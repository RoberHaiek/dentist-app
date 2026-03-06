import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/LocalizationProvider.dart';
import '../../services/LocalizationService.dart';
import '../AboutPage.dart';
import '../LoginPage.dart';

class ClinicSettingsPage extends StatefulWidget {
  const ClinicSettingsPage({super.key});

  @override
  State<ClinicSettingsPage> createState() => _ClinicSettingsPageState();
}

class _ClinicSettingsPageState extends State<ClinicSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? clinicData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  Future<void> _loadClinicData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snapshot = await _firestore.collection('clinics').doc(user.uid).get();
    setState(() {
      clinicData = snapshot.data();
      loading = false;
    });
  }

  Future<void> _updateClinicField(String key, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('clinics').doc(user.uid).update({key: value});
    setState(() => clinicData![key] = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('updated_successfully')),
          backgroundColor: const Color(0xFF7DD3C0),
        ),
      );
    }
  }

  Future<void> _editField(String fieldKey, String fieldLabel, String? currentValue) async {
    final controller = TextEditingController(text: currentValue ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${context.tr('edit')} $fieldLabel', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: fieldLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel'), style: const TextStyle(color: Color(0xFF999999))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _updateClinicField(fieldKey, result);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('logout'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(context.tr('logout_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel'), style: const TextStyle(color: Color(0xFF999999))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text(context.tr('logging_out')),
                ],
              ),
              duration: const Duration(seconds: 1),
              backgroundColor: const Color(0xFF7DD3C0),
            ),
          );
        }
        await _auth.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${context.tr('logout_failed')}: $e'), backgroundColor: const Color(0xFFFF6B6B)),
          );
        }
      }
    }
  }

  void _showQRCode() {
    final clinicId = _auth.currentUser?.uid ?? '';
    final clinicName = clinicData?['clinicName'] as String? ?? '';
    final registrationCode = clinicData?['registrationCode'] as String? ?? '';
    final qrData = 'dentist://register?clinicId=$clinicId&code=$registrationCode';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF2EBE2),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: const Color(0xFFCCCCCC), borderRadius: BorderRadius.circular(2)),
              ),
            ),

            Text(context.tr('clinic_qr_code'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const SizedBox(height: 6),
            Text(
              context.tr('qr_scan_hint'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // QR card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF333333)),
                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF333333)),
                  ),
                  const SizedBox(height: 20),

                  // Clinic name
                  Text(clinicName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const SizedBox(height: 12),

                  // Registration code pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EBE2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.vpn_key, color: Color(0xFF7DD3C0), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          registrationCode,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4, color: Color(0xFF333333)),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: registrationCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.tr('code_copied')), backgroundColor: const Color(0xFF7DD3C0)),
                            );
                          },
                          child: const Icon(Icons.copy, color: Color(0xFF7DD3C0), size: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('or_enter_code_manually'),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Info row
            Row(
              children: [
                Expanded(child: _buildQRInfoTile(Icons.bolt, context.tr('qr_instant'))),
                const SizedBox(width: 12),
                Expanded(child: _buildQRInfoTile(Icons.all_inclusive, context.tr('qr_permanent'))),
                const SizedBox(width: 12),
                Expanded(child: _buildQRInfoTile(Icons.security, context.tr('qr_secure'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRInfoTile(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF7DD3C0), size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF555555)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _changePassword() {
    final oldPasswordController     = TextEditingController();
    final newPasswordController     = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('change_password'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('current_password'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('new_password'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('confirm_password'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel'), style: const TextStyle(color: Color(0xFF999999))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('passwords_dont_match')), backgroundColor: const Color(0xFFFF6B6B)));
                return;
              }
              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('password_min_length')), backgroundColor: const Color(0xFFFF6B6B)));
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('password_change_coming_soon')), backgroundColor: const Color(0xFF7DD3C0)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  void _showEmailWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('cannot_edit_email'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(context.tr('email_change_restriction')),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7DD3C0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }

  void _manageNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('notification_settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(context.tr('notifications_feature_coming_soon')),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7DD3C0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }

  void _changeLanguage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('language_settings'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('en', 'English'),
            const SizedBox(height: 12),
            _buildLanguageOption('ar', 'العربية'),
            const SizedBox(height: 12),
            _buildLanguageOption('he', 'עברית'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel'), style: const TextStyle(color: Color(0xFF999999))),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name) {
    final isSelected = LocalizationService().currentLanguage == code;
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        await context.changeLanguage(code);
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ClinicSettingsPage()));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA8E6CF).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF7DD3C0) : Colors.grey.shade300, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(name, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF7DD3C0) : const Color(0xFF333333))),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF7DD3C0)),
          ],
        ),
      ),
    );
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('terms_conditions'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(context.tr('terms_content'))),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7DD3C0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(context.tr('close')),
          ),
        ],
      ),
    );
  }

  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('privacy_policy'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(child: Text(context.tr('privacy_content'))),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7DD3C0), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(context.tr('close')),
          ),
        ],
      ),
    );
  }

  // ── Widgets ──

  String _getInitials() {
    final name = clinicData?['clinicName'] as String? ?? '';
    final parts = name.trim().split(' ');
    if (parts.isEmpty || name.isEmpty) return 'C';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _getCurrentLanguageName() {
    final currentLang = LocalizationService().currentLanguage;
    switch (currentLang) {
      case 'en': return context.tr('english');
      case 'ar': return context.tr('arabic');
      case 'he': return context.tr('hebrew');
      default:   return context.tr('english');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2EBE2),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF7DD3C0))),
      );
    }

    final clinicName = clinicData?['clinicName'] as String? ?? context.tr('clinic');
    final registrationCode = clinicData?['registrationCode'] as String? ?? '——';
    final patientCount = (clinicData?['patients'] as List?)?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: Text(
          context.tr('settings'),
          style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ── Profile card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF7DD3C0).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 70, height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Center(
                      child: Text(_getInitials(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF7DD3C0))),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(clinicName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          _auth.currentUser?.email ?? '',
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.people, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '$patientCount ${context.tr('patients')}',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Clinic Info ──
            _buildSectionTitle(context.tr('clinic_information'), Icons.business),
            _buildPanel([
              _buildSettingTile(
                context.tr('clinic_name'),
                clinicData?['clinicName'] ?? context.tr('not_set'),
                Icons.business_outlined,
                    () => _editField('clinicName', context.tr('clinic_name'), clinicData?['clinicName']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('address'),
                clinicData?['address'] ?? context.tr('not_set'),
                Icons.location_on_outlined,
                    () => _editField('address', context.tr('address'), clinicData?['address']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('phone'),
                clinicData?['phone'] ?? context.tr('not_set'),
                Icons.phone_outlined,
                    () => _editField('phone', context.tr('phone'), clinicData?['phone']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('email'),
                _auth.currentUser?.email ?? context.tr('not_set'),
                Icons.email_outlined,
                    () => _showEmailWarning(),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Patient Registration ──
            _buildSectionTitle(context.tr('patient_registration'), Icons.qr_code),
            _buildPanel([
              _buildSettingTile(
                context.tr('registration_code'),
                registrationCode,
                Icons.vpn_key_outlined,
                    () {
                  Clipboard.setData(ClipboardData(text: registrationCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('code_copied')), backgroundColor: const Color(0xFF7DD3C0)),
                  );
                },
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('clinic_qr_code'),
                context.tr('qr_scan_hint'),
                Icons.qr_code_2,
                _showQRCode,
              ),
            ]),
            const SizedBox(height: 20),

            // ── Security ──
            _buildSectionTitle(context.tr('security'), Icons.lock),
            _buildPanel([
              _buildSettingTile(
                context.tr('password'),
                '••••••••',
                Icons.lock_outline,
                    () => _changePassword(),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Preferences ──
            _buildSectionTitle(context.tr('preferences'), Icons.tune),
            _buildPanel([
              _buildSettingTile(
                context.tr('notifications'),
                context.tr('manage_alerts'),
                Icons.notifications_outlined,
                    () => _manageNotifications(),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('language'),
                _getCurrentLanguageName(),
                Icons.language,
                    () => _changeLanguage(),
              ),
            ]),
            const SizedBox(height: 20),

            // ── App Info ──
            _buildSectionTitle(context.tr('app_information'), Icons.info),
            _buildPanel([
              _buildSettingTile(
                context.tr('about'),
                context.tr('version'),
                Icons.info_outline,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage())),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('terms_conditions'),
                context.tr('legal_information'),
                Icons.description_outlined,
                    () => _showTerms(),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('privacy_policy'),
                context.tr('data_protection'),
                Icons.privacy_tip_outlined,
                    () => _showPrivacy(),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Logout ──
            _buildSectionTitle(context.tr('account'), Icons.exit_to_app),
            _buildPanel([_buildLogoutTile()]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7DD3C0), size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        ],
      ),
    );
  }

  Widget _buildPanel(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFA8E6CF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF7DD3C0), size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333), fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF999999), fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF999999)),
      onTap: onTap,
    );
  }

  Widget _buildLogoutTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.logout, color: Color(0xFFFF6B6B), size: 24),
      ),
      title: Text(context.tr('logout'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B), fontSize: 16)),
      subtitle: Text(context.tr('logout_subtitle'), style: const TextStyle(color: Color(0xFF999999), fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFFF6B6B)),
      onTap: _handleLogout,
    );
  }
}