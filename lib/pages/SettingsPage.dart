import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'HomePage.dart';

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
  }

  // Dialog to edit a string field
  Future<void> _editField(String fieldKey, String fieldLabel, String? currentValue) async {
    final controller = TextEditingController(text: currentValue ?? "");
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit $fieldLabel"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: fieldLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
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

  // Date picker for Date of birth
  Future<void> _editDate(String fieldKey, String fieldLabel, String? currentValue) async {
    DateTime initialDate = DateTime.tryParse(currentValue ?? "") ?? DateTime(2000);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await _updateField(fieldKey, picked.toIso8601String());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings",
            style: TextStyle(
            fontSize: 24,
            color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSectionTitle("Personal Information"),
            _buildPanel([
              _buildSettingTile(
                "Full Name",
                "${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}",
                Icons.person,
                    () => _editField("firstName", "First Name", userData?['firstName']),
              ),
              _buildSettingTile(
                "Date of birth",
                userData?['dateOfBirth'] ?? "Not set",
                Icons.cake,
                    () => _editDate("dateOfBirth", "Date of birth", userData?['dateOfBirth']),
              ),
              _buildSettingTile(
                "Address",
                userData?['address'] ?? "Not set",
                Icons.home,
                    () => _editField("address", "Address", userData?['address']),
              ),
              _buildSettingTile(
                "Phone",
                userData?['phoneNumber'] ?? "Not set",
                Icons.phone,
                    () => _editField("phoneNumber", "phoneNumber", userData?['phoneNumber']),
              ),
              _buildSettingTile(
                "Email",
                _auth.currentUser?.email ?? "Not set",
                Icons.email,
                    () => _editField("email", "Email", _auth.currentUser?.email),
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionTitle("Security"),
            _buildPanel([
              _buildSettingTile(
                "Password",
                "********",
                Icons.lock,
                    () => _editField("password", "Password", ""),
              ),
            ]),
            const SizedBox(height: 20),

            _buildSectionTitle("Family"),
            _buildPanel([
              _buildSettingTile(
                "Relatives",
                (userData?['relatives'] ?? []).toString(),
                Icons.group,
                    () => _editField("relatives", "Relatives", userData?['relatives']?.join(", ")),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
      ),
    );
  }

  Widget _buildPanel(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
