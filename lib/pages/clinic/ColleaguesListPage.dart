import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ColleagueProfilePage.dart';

class ColleaguesListPage extends StatefulWidget {
  const ColleaguesListPage({super.key});

  @override
  State<ColleaguesListPage> createState() => _ColleaguesListPageState();
}

class _ColleaguesListPageState extends State<ColleaguesListPage> {
  bool _loading = true;
  List<ColleagueItem> _allColleagues = [];
  List<ColleagueItem> _filteredColleagues = [];

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadColleagues();
    _searchController.addListener(_filterColleagues);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadColleagues() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final colleaguesSnapshot = await FirebaseFirestore.instance
          .collection('workers')
          .where('clinicId', isEqualTo: user.uid)
          .get();

      List<ColleagueItem> colleagues = [];

      for (final doc in colleaguesSnapshot.docs) {
        final data = doc.data();
        colleagues.add(ColleagueItem(
          id: doc.id,
          firstName: data['firstName'] as String? ?? '',
          lastName: data['lastName'] as String? ?? '',
          role: data['role'] as String? ?? '',
          expertise: data['expertise'] as String? ?? '',
        ));
      }

      // Sort A-Z by default
      colleagues.sort((a, b) {
        final nameA = '${a.firstName} ${a.lastName}'.toLowerCase();
        final nameB = '${b.firstName} ${b.lastName}'.toLowerCase();
        return nameA.compareTo(nameB);
      });

      setState(() {
        _allColleagues = colleagues;
        _filteredColleagues = List.from(colleagues);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading colleagues: $e');
      setState(() => _loading = false);
    }
  }

  void _filterColleagues() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredColleagues = List.from(_allColleagues);
      } else {
        _filteredColleagues = _allColleagues.where((colleague) {
          final fullName = '${colleague.firstName} ${colleague.lastName}'.toLowerCase();
          return fullName.contains(query);
        }).toList();
      }
    });
  }

  void _showAddColleagueDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final expertiseController = TextEditingController();
    String selectedRole = 'Dentist';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Colleague',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expertiseController,
                decoration: InputDecoration(
                  labelText: 'Expertise/Specialization',
                  hintText: 'e.g., Orthodontics, Hygienist',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setStateDialog) {
                  return DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                      ),
                    ),
                    items: ['Dentist', 'Hygienist', 'Assistant', 'Receptionist', 'Technician', 'Other']
                        .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => selectedRole = value);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF999999))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (firstNameController.text.isEmpty || lastNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('First name and last name are required'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              await _addColleague(
                firstNameController.text.trim(),
                lastNameController.text.trim(),
                phoneController.text.trim(),
                emailController.text.trim(),
                addressController.text.trim(),
                expertiseController.text.trim(),
                selectedRole,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _addColleague(
      String firstName,
      String lastName,
      String phone,
      String email,
      String address,
      String expertise,
      String role,
      ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('workers').add({
        'clinicId': user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phone,
        'email': email,
        'address': address,
        'expertise': expertise,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Colleague added successfully'),
            backgroundColor: Color(0xFF7DD3C0),
          ),
        );
      }

      // Reload list
      await _loadColleagues();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: const Text('Colleagues', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)]),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: _showAddColleagueDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3C0)))
          : Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search colleagues...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7DD3C0)),
                filled: true,
                fillColor: const Color(0xFFF2EBE2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Colleague count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF2EBE2),
            child: Text(
              '${_filteredColleagues.length} colleague${_filteredColleagues.length != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
          ),

          // Colleagues list
          Expanded(
            child: _filteredColleagues.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'No colleagues yet'
                        : 'No colleagues found',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
                  ),
                  if (_searchController.text.isEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddColleagueDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Colleague'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7DD3C0),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredColleagues.length,
              itemBuilder: (context, index) {
                return _buildColleagueCard(_filteredColleagues[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColleagueCard(ColleagueItem colleague) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ColleagueProfilePage(colleagueId: colleague.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7DD3C0).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(colleague.firstName, colleague.lastName),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7DD3C0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${colleague.firstName} ${colleague.lastName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7DD3C0).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              colleague.role,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7DD3C0),
                              ),
                            ),
                          ),
                          if (colleague.expertise.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              colleague.expertise,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF999999)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String firstName, String lastName) {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }
}

class ColleagueItem {
  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final String expertise;

  ColleagueItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.expertise,
  });
}