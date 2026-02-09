import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/LocalizationProvider.dart';
import '../services/LocalizationService.dart';
import 'HomePage.dart';
import 'AboutPage.dart';
import 'LoginPage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.tr('cancel'),
                style: const TextStyle(color: Color(0xFF999999)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7DD3C0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('logout'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          context.tr('logout_confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(color: Color(0xFF999999)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
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

        // Sign out from Firebase
        await _auth.signOut();

        // Navigate to login page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
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
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF7DD3C0),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: Text(
          context.tr('settings'),
          style: const TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile card at the top
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
                _getRelativesCount(),
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
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
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

            // Logout section
            _buildSectionTitle(context.tr('account'), Icons.exit_to_app),
            _buildPanel([
              _buildLogoutTile(),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _getMedicalInfo(String key) {
    final value = userData?[key];
    if (value == null || value.toString().isEmpty) {
      return context.tr('none_specified');
    }
    return value.toString();
  }

  Future<void> _editMedicalField(String fieldKey, String fieldLabel, String? currentValue) async {
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
            maxLines: 3,
            decoration: InputDecoration(
              labelText: fieldLabel,
              hintText: context.tr('enter_details'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.tr('cancel'),
                style: const TextStyle(color: Color(0xFF999999)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7DD3C0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.tr('save')),
            ),
          ],
        );
      },
    );
    if (result != null) {
      await _updateField(fieldKey, result);
    }
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7DD3C0).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
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
                  "${userData?['firstName'] ?? 'User'} ${userData?['lastName'] ?? ''}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _auth.currentUser?.email ?? "",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
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
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF6B6B),
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        context.tr('logout_subtitle'),
        style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFFFF6B6B),
      ),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
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
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF999999),
      ),
      onTap: onTap,
    );
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

  String _getRelativesCount() {
    final relatives = userData?['relatives'] as List?;
    if (relatives == null || relatives.isEmpty) return context.tr('no_relatives');
    return "${relatives.length} ${relatives.length == 1 ? context.tr('relative') : context.tr('relatives')}";
  }

  String _getCurrentLanguageName() {
    final currentLang = LocalizationService().currentLanguage;
    switch (currentLang) {
      case 'en':
        return context.tr('english');
      case 'ar':
        return context.tr('arabic');
      case 'he':
        return context.tr('hebrew');
      default:
        return context.tr('english');
    }
  }

  String _getInitials() {
    final firstName = userData?['firstName'] ?? "";
    final lastName = userData?['lastName'] ?? "";
    String initials = "";
    if (firstName.isNotEmpty) initials += firstName[0].toUpperCase();
    if (lastName.isNotEmpty) initials += lastName[0].toUpperCase();
    return initials.isEmpty ? "U" : initials;
  }

  void _showEmailWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('cannot_edit_email'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          context.tr('email_change_restriction'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.tr('ok')),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('change_password'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('current_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('new_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('confirm_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(color: Color(0xFF999999)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validate passwords
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('passwords_dont_match')),
                    backgroundColor: const Color(0xFFFF6B6B),
                  ),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('password_min_length')),
                    backgroundColor: const Color(0xFFFF6B6B),
                  ),
                );
                return;
              }

              Navigator.pop(context);
              // TODO: Implement actual password change with Firebase reauthentication
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('password_change_coming_soon')),
                  backgroundColor: const Color(0xFF7DD3C0),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  void _manageRelatives() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('manage_relatives'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          context.tr('relatives_feature_coming_soon'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
        title: Text(
          context.tr('notification_settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          context.tr('notifications_feature_coming_soon'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
        title: Text(
          context.tr('language_settings'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(color: Color(0xFF999999)),
            ),
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
            Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsPage()),
                    );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFA8E6CF).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF7DD3C0) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF7DD3C0) : const Color(0xFF333333),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF7DD3C0)),
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
        title: Text(
          context.tr('terms_conditions'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            context.tr('terms_content'),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
        title: Text(
          context.tr('privacy_policy'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            context.tr('privacy_content'),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.tr('close')),
          ),
        ],
      ),
    );
  }
}