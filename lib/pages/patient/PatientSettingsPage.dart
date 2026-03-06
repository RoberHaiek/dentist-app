import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../services/LocalizationProvider.dart';
import '../../services/LocalizationService.dart';
import '../AboutPage.dart';
import '../LoginPage.dart';

class PatientSettingsPage extends StatefulWidget {
  const PatientSettingsPage({super.key});

  @override
  State<PatientSettingsPage> createState() => _PatientSettingsPageState();
}

class _PatientSettingsPageState extends State<PatientSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snapshot = await _firestore.collection("users").doc(user.uid).get();
    setState(() {
      userData = snapshot.data();
      loading = false;
    });
  }

  Future<void> _updateField(String key, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection("users").doc(user.uid).update({key: value});
    setState(() {
      userData![key] = value;
    });
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
    final controller = TextEditingController(text: currentValue ?? "");
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "${context.tr('edit')} $fieldLabel",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      await _updateField(fieldKey, result);
    }
  }

  Future<void> _editDate(String fieldKey, String fieldLabel, String? currentValue) async {
    DateTime initialDate = DateTime.tryParse(currentValue ?? "") ?? DateTime(2000);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7DD3C0),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await _updateField(fieldKey, picked.toIso8601String());
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
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
        }
      } catch (e) {
        debugPrint('Logout error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${context.tr('logout_failed')}: $e"),
              backgroundColor: const Color(0xFFFF6B6B),
            ),
          );
        }
      }
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
            _buildProfileCard(),
            const SizedBox(height: 20),

            _buildSectionTitle(context.tr('personal_information'), Icons.person),
            _buildPanel([
              _buildSettingTile(
                context.tr('first_name'),
                userData?['firstName'] ?? context.tr('not_set'),
                Icons.badge,
                    () => _editField("firstName", context.tr('first_name'), userData?['firstName']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('last_name'),
                userData?['lastName'] ?? context.tr('not_set'),
                Icons.badge_outlined,
                    () => _editField("lastName", context.tr('last_name'), userData?['lastName']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('date_of_birth'),
                _formatDate(userData?['dateOfBirth']),
                Icons.cake,
                    () => _editDate("dateOfBirth", context.tr('date_of_birth'), userData?['dateOfBirth']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('address'),
                userData?['address'] ?? context.tr('not_set'),
                Icons.home,
                    () => _editField("address", context.tr('address'), userData?['address']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('phone'),
                userData?['phoneNumber'] ?? context.tr('not_set'),
                Icons.phone,
                    () => _editField("phoneNumber", context.tr('phone'), userData?['phoneNumber']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('email'),
                _auth.currentUser?.email ?? context.tr('not_set'),
                Icons.email,
                    () => _showEmailWarning(),
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionTitle(context.tr('medical_history'), Icons.local_hospital),
            _buildPanel([
              _buildSettingTile(
                context.tr('insurance'),
                _getMedicalInfo('insurance'),
                Icons.health_and_safety,
                    () => _selectInsurance(),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('allergies'),
                _getMedicalInfo('allergies'),
                Icons.warning_amber,
                    () => _editMedicalField("allergies", context.tr('allergies'), userData?['allergies']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('current_medications'),
                _getMedicalInfo('medications'),
                Icons.medication,
                    () => _editMedicalField("medications", context.tr('current_medications'), userData?['medications']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('chronic_conditions'),
                _getMedicalInfo('conditions'),
                Icons.favorite,
                    () => _editMedicalField("conditions", context.tr('chronic_conditions'), userData?['conditions']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                context.tr('additional_medical_info'),
                _getMedicalInfo('additionalInfo'),
                Icons.note_add,
                    () => _editMedicalField("additionalInfo", context.tr('additional_medical_info'), userData?['additionalInfo']),
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionTitle(context.tr('security'), Icons.lock),
            _buildPanel([
              _buildSettingTile(
                context.tr('password'),
                "••••••••",
                Icons.lock_outline,
                    () => _changePassword(),
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionTitle(context.tr('family'), Icons.group),
            _buildPanel([
              _buildSettingTile(
                context.tr('manage_relatives'),
                context.tr('view_and_manage'),
                Icons.people_outline,
                    () => _manageRelatives(),
              ),
            ]),
            const SizedBox(height: 20),

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

            _buildSectionTitle(context.tr('account'), Icons.exit_to_app),
            _buildPanel([_buildLogoutTile()]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  String _getMedicalInfo(String key) {
    final value = userData?[key];
    if (value == null || value.toString().isEmpty) return context.tr('none_specified');
    return value.toString();
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return context.tr('not_set');
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return context.tr('not_set');
    }
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

  String _getInitials() {
    final firstName = userData?['firstName'] ?? "";
    final lastName  = userData?['lastName']  ?? "";
    String initials = "";
    if (firstName.isNotEmpty) initials += firstName[0].toUpperCase();
    if (lastName.isNotEmpty)  initials += lastName[0].toUpperCase();
    return initials.isEmpty ? "U" : initials;
  }

  // ── Widgets ──

  Widget _buildProfileCard() {
    return Container(
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
              borderRadius: BorderRadius.circular(35),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF7DD3C0)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${userData?['firstName'] ?? 'User'} ${userData?['lastName'] ?? ''}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _auth.currentUser?.email ?? "",
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.logout, color: Color(0xFFFF6B6B), size: 24),
      ),
      title: Text(
        context.tr('logout'),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B), fontSize: 16),
      ),
      subtitle: Text(
        context.tr('logout_subtitle'),
        style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFFF6B6B)),
      onTap: _handleLogout,
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

  // ── Actions ──

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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _editMedicalField(String fieldKey, String fieldLabel, String? currentValue) async {
    final controller = TextEditingController(text: currentValue ?? "");
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("${context.tr('edit')} $fieldLabel", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: fieldLabel,
            hintText: context.tr('enter_details'),
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
    if (result != null) await _updateField(fieldKey, result);
  }

  void _selectInsurance() {
    final insuranceOptions = ['כללית', 'מכבי', 'לאומית', 'מאוחדת'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('insurance'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...insuranceOptions.map((insurance) {
                final isSelected = userData?['insurance'] == insurance;
                return InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateField('insurance', insurance);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFA8E6CF).withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFF7DD3C0) : Colors.grey.shade300, width: 2),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            insurance,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF7DD3C0) : const Color(0xFF333333),
                            ),
                          ),
                        ),
                        if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF7DD3C0)),
                      ],
                    ),
                  ),
                );
              }),
              if (userData?['insurance'] != null && userData!['insurance'].toString().isNotEmpty)
                InkWell(
                  onTap: () async {
                    Navigator.pop(context);
                    await _updateField('insurance', '');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.clear, color: Colors.red.shade400, size: 20),
                        const SizedBox(width: 8),
                        Text(context.tr('clear_selection'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red.shade400)),
                      ],
                    ),
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

  void _manageRelatives() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('relatives')
        .orderBy('firstName')
        .get();

    final relatives = snap.docs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        'firstName': data['firstName'] ?? '',
        'lastName':  data['lastName']  ?? '',
        'relation':  data['relation']  ?? '',
        'birthDate': data['birthDate'],
      };
    }).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RelativesManagerSheet(
        relatives: relatives,
        userId: user.uid,
        onChanged: () => setState(() {}),
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
            _buildLanguageOption('en', "English"),
            const SizedBox(height: 12),
            _buildLanguageOption('ar', "العربية"),
            const SizedBox(height: 12),
            _buildLanguageOption('he', "עברית"),
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PatientSettingsPage()));
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
              child: Text(
                name,
                style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF7DD3C0) : const Color(0xFF333333)),
              ),
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
}

// ════════════════════════════════════════════════════════════════
//  Relatives Manager Bottom Sheet
// ════════════════════════════════════════════════════════════════

class _RelativesManagerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> relatives;
  final String userId;
  final VoidCallback onChanged;

  const _RelativesManagerSheet({
    required this.relatives,
    required this.userId,
    required this.onChanged,
  });

  @override
  State<_RelativesManagerSheet> createState() => _RelativesManagerSheetState();
}

class _RelativesManagerSheetState extends State<_RelativesManagerSheet> {
  late List<Map<String, dynamic>> _relatives;

  @override
  void initState() {
    super.initState();
    _relatives = List.from(widget.relatives);
  }

  Future<void> _deleteRelative(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove family member', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to remove this person?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF999999))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('relatives')
          .doc(id)
          .delete();
      setState(() => _relatives.removeWhere((r) => r['id'] == id));
      widget.onChanged();
    }
  }

  void _showAddSheet() {
    final firstNameCtrl = TextEditingController();
    final lastNameCtrl  = TextEditingController();
    final relationCtrl  = TextEditingController();
    DateTime? birthDate;
    String? selectedPreset;
    bool saving = false;

    const presets = ['Son', 'Daughter', 'Mother', 'Father', 'Spouse', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setInner) {
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
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: const Color(0xFFCCCCCC), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text('Add a Family Member', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildField(firstNameCtrl, 'First Name', 'e.g. John')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField(lastNameCtrl, 'Last Name', 'e.g. Smith')),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Relation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: presets.map((p) {
                    final isSel = selectedPreset == p;
                    return GestureDetector(
                      onTap: () => setInner(() {
                        selectedPreset = p;
                        if (p != 'Other') relationCtrl.text = p;
                        else relationCtrl.clear();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF7DD3C0) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSel ? const Color(0xFF7DD3C0) : const Color(0xFFCCCCCC), width: 1.5),
                        ),
                        child: Text(p, style: TextStyle(fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: isSel ? Colors.white : const Color(0xFF666666))),
                      ),
                    );
                  }).toList(),
                ),
                if (selectedPreset == 'Other' || selectedPreset == null) ...[
                  const SizedBox(height: 10),
                  _buildField(relationCtrl, selectedPreset == null ? 'Or type a custom relation' : 'Custom relation', 'e.g. Grandparent, Uncle…'),
                ],
                const SizedBox(height: 16),
                const Text('Date of Birth', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF7DD3C0))),
                        child: child!,
                      ),
                    );
                    if (picked != null) setInner(() => birthDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFCCCCCC))),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined, color: Color(0xFF7DD3C0), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          birthDate == null ? 'Select birth date' : DateFormat('MMMM d, y').format(birthDate!),
                          style: TextStyle(fontSize: 14, color: birthDate == null ? const Color(0xFF999999) : const Color(0xFF333333), fontWeight: birthDate == null ? FontWeight.normal : FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      final fn  = firstNameCtrl.text.trim();
                      final ln  = lastNameCtrl.text.trim();
                      final rel = relationCtrl.text.trim();
                      if (fn.isEmpty || ln.isEmpty || rel.isEmpty || birthDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red));
                        return;
                      }
                      setInner(() => saving = true);
                      try {
                        final docRef = await FirebaseFirestore.instance
                            .collection('users').doc(widget.userId).collection('relatives')
                            .add({'firstName': fn, 'lastName': ln, 'relation': rel, 'birthDate': Timestamp.fromDate(birthDate!)});
                        setState(() => _relatives.add({'id': docRef.id, 'firstName': fn, 'lastName': ln, 'relation': rel, 'birthDate': Timestamp.fromDate(birthDate!)}));
                        widget.onChanged();
                        if (mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setInner(() => saving = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7DD3C0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Add', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF999999), fontSize: 13),
            filled: true, fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCCCCCC))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 1.5)),
          ),
        ),
      ],
    );
  }

  String _formatBirthDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('MMM d, y').format(date);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedRelatives = _relatives.take(5).toList();
    final hasMore = _relatives.length > 5;

    return Container(
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
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: const Color(0xFFCCCCCC), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('Family Members', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 6),
          const Text(
            'Manage the people you can book appointments for.',
            style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
          ),
          const SizedBox(height: 20),

          if (_relatives.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF7DD3C0).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.family_restroom, color: Color(0xFF7DD3C0), size: 36),
                  ),
                  const SizedBox(height: 14),
                  const Text('No family members added yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const SizedBox(height: 8),
                  const Text(
                    'Add a family member to book appointments on their behalf — for example, a child or an elderly parent.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF999999), height: 1.5),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  ...displayedRelatives.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    final isLast = i == displayedRelatives.length - 1 && !hasMore;
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: const Color(0xFF7DD3C0).withOpacity(0.12), shape: BoxShape.circle),
                                child: Center(
                                  child: Text(
                                    (r['firstName'] as String).isNotEmpty ? (r['firstName'] as String)[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7DD3C0)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${r['firstName']} ${r['lastName']}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                                    Text(
                                      '${r['relation']}${_formatBirthDate(r['birthDate']).isNotEmpty ? '  ·  ${_formatBirthDate(r['birthDate'])}' : ''}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B), size: 20),
                                onPressed: () => _deleteRelative(r['id'] as String),
                                splashRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }),
                  if (hasMore) ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('+${_relatives.length - 5} more', style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAddSheet,
              icon: const Icon(Icons.add, color: Color(0xFF7DD3C0)),
              label: const Text('Add a family member', style: TextStyle(color: Color(0xFF7DD3C0), fontWeight: FontWeight.w600, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF7DD3C0), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}