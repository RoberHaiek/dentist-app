import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        const SnackBar(
          content: Text("Updated successfully"),
          backgroundColor: Color(0xFF7DD3C0),
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

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Logout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to logout?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF999999)),
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
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text("Logging out..."),
                ],
              ),
              duration: Duration(seconds: 1),
              backgroundColor: Color(0xFF7DD3C0),
            ),
          );
        }

        // Sign out from Firebase
        await _auth.signOut();

        // Navigate to login page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } catch (e) {
        debugPrint('Logout error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Logout failed: $e"),
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
            // Profile card at the top
            _buildProfileCard(),
            const SizedBox(height: 20),

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

            _buildSectionTitle("Preferences", Icons.tune),
            _buildPanel([
              _buildSettingTile(
                "Notifications",
                "Manage alerts",
                Icons.notifications_outlined,
                () => _manageNotifications(),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                "Language",
                "English",
                Icons.language,
                () => _changeLanguage(),
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
              const Divider(height: 1),
              _buildSettingTile(
                "Terms & Conditions",
                "Legal information",
                Icons.description_outlined,
                () => _showTerms(),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                "Privacy Policy",
                "Data protection",
                Icons.privacy_tip_outlined,
                () => _showPrivacy(),
              ),
            ]),
            const SizedBox(height: 20),

            // Logout section
            _buildSectionTitle("Account", Icons.exit_to_app),
            _buildPanel([
              _buildLogoutTile(),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
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
      title: const Text(
        "Logout",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFFFF6B6B),
          fontSize: 16,
        ),
      ),
      subtitle: const Text(
        "Sign out of your account",
        style: TextStyle(color: Color(0xFF999999), fontSize: 14),
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
            onPressed: () async {
              // Validate passwords
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Passwords don't match!"),
                    backgroundColor: Color(0xFFFF6B6B),
                  ),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Password must be at least 6 characters!"),
                    backgroundColor: Color(0xFFFF6B6B),
                  ),
                );
                return;
              }

              Navigator.pop(context);
              // TODO: Implement actual password change with Firebase reauthentication
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

  void _manageNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Notification Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Notification preferences feature is coming soon! "
          "You'll be able to customize appointment reminders and alerts.",
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

  void _changeLanguage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Language Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Multi-language support is coming soon! "
          "The app will support multiple languages in future updates.",
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

  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            "Terms and conditions will be displayed here. "
            "This section will include all legal terms, user agreements, "
            "and conditions for using the Asnani dental app.",
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
            child: const Text("Close"),
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
        title: const Text(
          "Privacy Policy",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            "Privacy policy information will be displayed here. "
            "This section will detail how user data is collected, stored, "
            "and protected in the Asnani dental app.",
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
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}