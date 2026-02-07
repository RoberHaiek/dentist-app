import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Images.dart';
import '../services/LocalizationProvider.dart';
import 'BookAppointmentPage.dart';

class ClinicProfilePage extends StatefulWidget {
  const ClinicProfilePage({super.key});

  @override
  State<ClinicProfilePage> createState() => _ClinicProfilePageState();
}

class _ClinicProfilePageState extends State<ClinicProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchPhone(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/972522965892');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('whatsapp_error')),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _showNavigationOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.map, color: Color(0xFF7DD3C0)),
                  title: Text(context.tr('google_maps')),
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri uri = Uri.parse('https://maps.google.com/?q=עפרוני 38, עכו');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.navigation, color: Color(0xFF7DD3C0)),
                  title: Text(context.tr('waze')),
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri uri = Uri.parse('https://waze.com/ul?q=עפרוני 38, עכו');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 340,
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
                    // TODO: Share clinic profile
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeroSection(),
              ),
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
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(text: context.tr('about')),
                      Tab(text: context.tr('team')),
                      Tab(text: context.tr('services')),
                      Tab(text: context.tr('gallery')),
                      Tab(text: context.tr('contact')),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
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

  Widget _buildHeroSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
              width: 100,
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Images.getImage("images/clients/alfred/clinic_logo.jpg", 80, 80),
              ),
            ),
            const SizedBox(height: 16),

            // Clinic Name
            Text(
              context.tr('clinic_name'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              context.tr('dental_specialist'),
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Quick Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.phone,
                      label: context.tr('call'),
                      onTap: () => _launchPhone('04-9916245'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButtonWithImage(
                      imagePath: "images/whatsapp_icon.png",
                      label: 'WhatsApp',
                      onTap: () => _launchWhatsApp(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.calendar_today,
                      label: context.tr('book'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BookAppointmentPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.map,
                      label: context.tr('map'),
                      onTap: () => _showNavigationOptions(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF7DD3C0), size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
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

  Widget _buildQuickActionButtonWithImage({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Images.getImage(imagePath, 24, 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
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

  // TAB 1: About
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Text
          _buildSectionTitle(context.tr('about_us'), Icons.info_outline),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              context.tr('clinic_about_description'),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF666666),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Technology
          _buildSectionTitle(context.tr('technology_equipment'), Icons.computer_outlined),
          const SizedBox(height: 12),
          ...['digital_xrays', '3d_imaging', 'laser_dentistry', 'cad_cam'].map((tech) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
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
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA8E6CF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getTechIcon(tech),
                      color: const Color(0xFF7DD3C0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr(tech),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 24),

          // Certifications
          _buildSectionTitle(context.tr('certifications_awards'), Icons.workspace_premium_outlined),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  // TODO: Open full-size certificate view
                },
                child: Container(
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Images.getImage(
                      "images/clients/alfred/certificate_${index + 1}.jpeg",
                      double.infinity,
                      double.infinity,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Insurance & Payment
          _buildSectionTitle(context.tr('insurance_payment'), Icons.account_balance_wallet),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context.tr('insurance_accepted'), context.tr('insurance_list')),
                const Divider(height: 20),
                _buildInfoRow(context.tr('payment_methods'), context.tr('payment_methods_list')),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Languages
          _buildSectionTitle(context.tr('languages_spoken'), Icons.language),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildLanguageChip(context.tr('hebrew')),
                _buildLanguageChip(context.tr('arabic')),
                _buildLanguageChip(context.tr('english')),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Parking & Accessibility
          _buildSectionTitle(context.tr('parking_accessibility'), Icons.local_parking),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(context.tr('parking'), context.tr('parking_info')),
                const Divider(height: 20),
                _buildInfoRow(context.tr('accessibility'), context.tr('wheelchair_accessible')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // TAB 2: Team
  Widget _buildTeamTab() {
    final teamMembers = [
      {
        'name': context.tr('example_doctor_1'),
        'role': context.tr('doctor_description_1'),
        'experience': context.tr('15_years_experience'),
        'specializations': [
          context.tr('cosmetic_dentistry'),
          context.tr('implants'),
        ],
      },
      {
        'name': context.tr('example_doctor_2'),
        'role': context.tr('doctor_description_2'),
        'experience': context.tr('10_years_experience'),
        'specializations': [
          context.tr('braces'),
          context.tr('aligners'),
        ],
      },
      {
        'name': context.tr('example_doctor_3'),
        'role': context.tr('doctor_description_3'),
        'experience': context.tr('8_years_experience'),
        'specializations': [
          context.tr('braces'),
          context.tr('aligners'),
        ],
      },
      {
        'name': context.tr('example_doctor_4'),
        'role': context.tr('doctor_description_4'),
        'experience': context.tr('8_years_experience'),
        'specializations': [
          context.tr('braces'),
          context.tr('aligners'),
        ],
      },
      {
        'name': context.tr('example_doctor_5'),
        'role': context.tr('doctor_description_5'),
        'experience': context.tr('10_years_experience'),
        'specializations': [
          context.tr('teeth_cleaning'),
          context.tr('prevention'),
        ],
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: teamMembers.length,
      itemBuilder: (context, index) {
        final member = teamMembers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Photo placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFA8E6CF).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: Color(0xFF7DD3C0),
                ),
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member['role'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7DD3C0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member['experience'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (member['specializations'] as List<String>)
                          .map((spec) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA8E6CF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            spec,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF666666),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 3: Services
  Widget _buildServicesTab() {
    final services = [
      {'name': context.tr('general_checkup'), 'icon': Icons.medical_services},
      {'name': context.tr('teeth_cleaning'), 'icon': Icons.cleaning_services},
      {'name': context.tr('teeth_whitening'), 'icon': Icons.auto_awesome},
      {'name': context.tr('dental_implant'), 'icon': Icons.construction},
      {'name': context.tr('root_canal'), 'icon': Icons.healing},
      {'name': context.tr('veneers'), 'icon': Icons.diamond},
      {'name': context.tr('braces'), 'icon': Icons.straighten},
      {'name': context.tr('botox'), 'icon': Icons.face_retouching_natural},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFA8E6CF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  service['icon'] as IconData,
                  color: const Color(0xFF7DD3C0),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                service['name'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

// TAB 4: Gallery
  Widget _buildGalleryTab() {
    // Categories for organizing photos
    final categories = [
      {
        'name': context.tr('teeth_whitening'),
        'count': 3,
        'startIndex': 1, // Uses images 1, 2, 3
      },
      {
        'name': 'עיצוב שפתיים',
        'count': 3,
        'startIndex': 4, // Uses images 4, 5, 6
      },
      {
        'name': 'שיקם - כתרים זירקוניה',
        'count': 3,
        'startIndex': 7, // Uses images 7, 8, 9
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: categories.length,
      itemBuilder: (context, catIndex) {
        final category = categories[catIndex];
        final count = category['count'] as int;
        final startIndex = category['startIndex'] as int;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      category['name'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA8E6CF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count ${context.tr('photos')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7DD3C0),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Photo Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: count,
              itemBuilder: (context, photoIndex) {
                // Calculate actual image number based on category start index
                final imageNumber = startIndex + photoIndex;

                return GestureDetector(
                  onTap: () {
                    // TODO: Open full image viewer
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Images.getImage(
                        "images/clients/alfred/before_after_$imageNumber.jpeg",
                        double.infinity,
                        double.infinity,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // TAB 5: Contact (simplified - removed extra info)
  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Opening Hours
          _buildSectionTitle(context.tr('opening_hours'), Icons.access_time),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHoursRow(context.tr('sunday'), "10:00 - 16:00"),
                _buildHoursRow(context.tr('monday'), "10:00 - 13:00, 14:00 - 17:00"),
                _buildHoursRow(context.tr('tuesday'), "10:00 - 13:00"),
                _buildHoursRow(context.tr('wednesday'), "10:00 - 13:00"),
                _buildHoursRow(context.tr('thursday'), "10:00 - 13:00, 14:00 - 17:00"),
                _buildHoursRow(context.tr('friday'), "10:00 - 13:00"),
                _buildHoursRow(context.tr('saturday'), context.tr('closed')),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact Info
          _buildSectionTitle(context.tr('contact_info'), Icons.contact_mail),
          const SizedBox(height: 12),
          _buildContactRow(
            icon: Icons.location_on,
            label: context.tr('address'),
            value: "עפרוני 38, עכו",
            onTap: () => _showNavigationOptions(context),
          ),
          const SizedBox(height: 12),
          _buildContactRow(
            icon: Icons.phone,
            label: context.tr('phone'),
            value: "04-9916245",
            onTap: () => _launchPhone('04-9916245'),
          ),
          const SizedBox(height: 12),
          _buildContactRow(
            icon: Icons.email,
            label: context.tr('email'),
            value: "a049916245@gmail.com",
            onTap: () => _launchEmail('a049916245@gmail.com'),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7DD3C0), size: 22),
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
    );
  }

  Widget _buildHoursRow(String day, String hours) {
    final isToday = _isToday(day);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? const Color(0xFF7DD3C0) : const Color(0xFF666666),
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
              color: isToday ? const Color(0xFF7DD3C0) : const Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(String day) {
    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final today = DateTime.now().weekday - 1;
    final dayIndex = weekdays.indexOf(day.toLowerCase());
    return dayIndex == today;
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFA8E6CF).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF7DD3C0), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF7DD3C0)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF999999),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageChip(String language) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFA8E6CF).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        language,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF7DD3C0),
        ),
      ),
    );
  }

  IconData _getTechIcon(String tech) {
    switch (tech) {
      case 'digital_xrays':
        return Icons.camera_alt;
      case '3d_imaging':
        return Icons.view_in_ar;
      case 'laser_dentistry':
        return Icons.lightbulb;
      case 'cad_cam':
        return Icons.precision_manufacturing;
      default:
        return Icons.computer;
    }
  }
}