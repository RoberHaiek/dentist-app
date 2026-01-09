import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'HomePage.dart';
import 'AboutPage.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Updated successfully"),
        backgroundColor: Color(0xFF7DD3C0),
      ),
    );
  }

  Future<void> _editField(String fieldKey, String fieldLabel, String? currentValue) async {
    final controller = TextEditingController(text: currentValue ?? "");
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Edit $fieldLabel",
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
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFF999999)),
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
              child: const Text("Save"),
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
        title: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
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
            _buildSectionTitle("Personal Information", Icons.person),
            _buildPanel([
              _buildSettingTile(
                "First Name",
                userData?['firstName'] ?? "Not set",
                Icons.badge,
                () => _editField("firstName", "First Name", userData?['firstName']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                "Last Name",
                userData?['lastName'] ?? "Not set",
                Icons.badge_outlined,
                () => _editField("lastName", "Last Name", userData?['lastName']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                "Date of Birth",
                _formatDate(userData?['dateOfBirth']),
                Icons.cake,
                () => _editDate("dateOfBirth", "Date of Birth", userData?['dateOfBirth']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                "Address",
                userData?['address'] ?? "Not set",
                Icons.home,
                () => _editField("address", "Address", userData?['address']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                "Phone",
                userData?['phoneNumber'] ?? "Not set",
                Icons.phone,
                () => _editField("phoneNumber", "Phone Number", userData?['phoneNumber']),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                "Email",
                _auth.currentUser?.email ?? "Not set",
                Icons.email,
                () => _showEmailWarning(),
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionTitle("Security", Icons.lock),
            _buildPanel([
              _buildSettingTile(
                "Password",
                "••••••••",
                Icons.lock_outline,
                () => _changePassword(),
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionTitle("Family", Icons.group),
            _buildPanel([
              _buildSettingTile(
                "Manage Relatives",
                _getRelativesCount(),
                Icons.people_outline,
                () => _manageRelatives(),
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionTitle("App Information", Icons.info),
            _buildPanel([
              _buildSettingTile(
                "About Asnani",
                "Version 1.0.0",
                Icons.info_outline,
                () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
            ]),
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
    if (dateString == null || dateString.isEmpty) return "Not set";
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "Not set";
    }
  }

  String _getRelativesCount() {
    final relatives = userData?['relatives'] as List?;
    if (relatives == null || relatives.isEmpty) return "No relatives added";
    return "${relatives.length} relative${relatives.length == 1 ? '' : 's'}";
  }

  void _showEmailWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Cannot Edit Email",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Email address is linked to your account and cannot be changed from here. "
          "Please contact support if you need to update your email.",
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
            child: const Text("OK"),
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
        title: const Text(
          "Change Password",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Current Password",
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
                  labelText: "New Password",
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
                  labelText: "Confirm Password",
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
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF999999)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement password change logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Password change feature coming soon!"),
                  backgroundColor: Color(0xFF7DD3C0),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Save"),
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
        title: const Text(
          "Manage Relatives",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Relatives management feature is coming soon! "
          "You'll be able to add family members to book appointments for them.",
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
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}