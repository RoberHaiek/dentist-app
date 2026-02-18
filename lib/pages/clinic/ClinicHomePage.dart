import 'package:dentist_app/pages/clinic/EditClinicPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../patient/SettingsPage.dart';
import '../../services/LocalizationProvider.dart';
import 'CalendarPage.dart';

class ClinicHomePage extends StatefulWidget {
  const ClinicHomePage({super.key});

  @override
  State<ClinicHomePage> createState() => _ClinicHomePageState();
}

class _ClinicHomePageState extends State<ClinicHomePage> {
  bool loading = true;
  String clinicName = '';

  @override
  void initState() {
    super.initState();
    _loadClinic();
  }

  Future<void> _loadClinic() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('clinics')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            clinicName = doc.data()?['clinicName'] ?? 'Clinic';
            loading = false;
          });
        } else {
          setState(() => loading = false);
        }
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint('Error loading clinic: $e');
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: false,
              floating: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeroSection(),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFFFFF8F0),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildActionCards(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
        ),
      ),
      child: Column(
        children: [
          // Top bar with notifications and settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 28,
                  color: Colors.white,
                ),
                IconButton(
                  icon: const Icon(Icons.settings, size: 28, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Greeting - centered vertically in remaining space
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('welcome_back'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      clinicName,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _buildActionCard(
            icon: "📅",
            title: context.tr('calendar'),
            subtitle: context.tr('manage_schedule'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CalendarPage()),
              );
            },
          ),
          _buildActionCard(
            icon: "✏️",
            title: context.tr('edit_business_page'),
            subtitle: context.tr('update_info'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EditClinicPage()),
              );
            },
          ),
          _buildActionCard(
            icon: "📄",
            title: context.tr('documents'),
            subtitle: context.tr('manage_files'),
            onTap: () {
              // TODO: Navigate to Documents page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('coming_soon'))),
              );
            },
          ),
          _buildActionCard(
            icon: "🎁",
            title: context.tr('special_discounts'),
            subtitle: context.tr('create_offers'),
            onTap: () {
              // TODO: Navigate to Special Discounts page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('coming_soon'))),
              );
            },
          ),
          _buildActionCard(
            icon: "👥",
            title: context.tr('patient_list'),
            subtitle: context.tr('view_patients'),
            onTap: () {
              // TODO: Navigate to Patient List page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('coming_soon'))),
              );
            },
          ),
          _buildActionCard(
            icon: "👨🏻‍⚕️",
            title: context.tr('colleague_list'),
            subtitle: context.tr('view_colleagues'),
            onTap: () {
              // TODO: Navigate to Patient List page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('coming_soon'))),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF999999),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}