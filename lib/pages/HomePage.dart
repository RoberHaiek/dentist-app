import 'package:dentist_app/pages/AppointmentPage.dart';
import 'package:dentist_app/pages/BookAppointmentPage.dart';
import 'package:dentist_app/pages/ContactClinicPage.dart';
import 'package:dentist_app/pages/ClinicProfilePage.dart';
import 'package:dentist_app/pages/CouponPage.dart';
import 'package:dentist_app/pages/InstructionsPage.dart';
import 'package:dentist_app/pages/SettingsPage.dart';
import 'package:dentist_app/pages/ClinicDealsPage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../CurrentPatient.dart';
import '../Images.dart';
import 'package:dentist_app/services/LocalizationProvider.dart';
import 'MyDocumentsPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final CurrentPatient currentPatient = CurrentPatient();
  bool loading = true;
  int numberOfAppointments = 1; // TODO: Configure this based on actual appointments
  bool showInstructions = false;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    await currentPatient.loadFromFirestore();
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  // Parallax scrolling content
                  NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollUpdateNotification) {
                        setState(() {});
                      }
                      return false;
                    },
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
                                const SizedBox(height: 20),
                                _buildAppointmentStatusCard(),
                                const SizedBox(height: 30),
                                _buildBookAppointmentButton(),
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
                  _buildEmergencyButton(),
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
          // Top bar with settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.notifications_outlined,
                    size: 28, color: Colors.white),
                IconButton(
                  icon: const Icon(Icons.settings, size: 28, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Greeting and mascot
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                Text(
//                   "${context.tr('welcome')} ${currentPatient.firstName}!",
                "היי מר. מטופל!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('your_smile_matters'),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAppointmentStatusCard() {
    Color borderColor;
    Color backgroundColor;
    String icon;
    String title;
    String subtitle;
    String instructionsTitle;
    List<String> instructions;

    if (numberOfAppointments == 0) {
      // Checkup due
      borderColor = const Color(0xFFFFB74D);
      backgroundColor = const Color(0xFFFFF3E0);
      icon = "📅";
      title = context.tr('time_for_checkup');
      subtitle = context.tr('last_checkup_6_months');
      instructionsTitle = "";
      instructions = [];
    } else if (numberOfAppointments < 0) {
      // Post-surgery care
      borderColor = const Color(0xFFFF6B6B);
      backgroundColor = const Color(0xFFFFEBEE);
      icon = "❤️";
      title = "Post-Surgery Care"; // Not in strings.json yet
      subtitle = "Hope you're feeling well after the surgery!";
      instructionsTitle = "Important Instructions:";
      instructions = [
        "Don't eat for 1 hour after the surgery",
        "If pain occurs, take Ibuprofen 400mg",
        "Avoid hot drinks for 24 hours",
        "Rest and take it easy today",
      ];
    } else {
      // Upcoming appointment
      borderColor = const Color(0xFF7DD3C0);
      backgroundColor = const Color(0xFFE8F5F1);
      icon = "🎯";
      title = context.tr('upcoming_appointment');
      subtitle = context.tr('next_appointment_on');
      instructionsTitle = "לפני הטיפול";
      instructions = [
        "מומלץ לא לאכול שעה לפני הפגישה",
        "לצחצח שיניים ולנקות בחוט דנטלי היטב",
        "להגיע 10 דקות מוקדם יותר",
        "להביא את כרטיס קופת החולים שלך",
      ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with icon and color
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(13),
                  topRight: Radius.circular(13),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Instructions section (if applicable)
            if (instructions.isNotEmpty)
              Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        showInstructions = !showInstructions;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            showInstructions ? context.tr('hide_instructions') : context.tr('view_instructions'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: borderColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            showInstructions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: borderColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showInstructions)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 12),
                          Text(
                            instructionsTitle,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...instructions.map((instruction) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: borderColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        instruction,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF666666),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildBookAppointmentButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF618779), Color(0xFF7DD3C0)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7DD3C0).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const BookAppointmentPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "📅",
                style: TextStyle(fontSize: 26),
              ),
              const SizedBox(width: 12),
              Text(
                context.tr('book_appointment'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
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
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 1.1,
        children: [
          _buildActionCardWithImage(
            icon: Images.getImage("images/discount.jpg", 36.0, 36.0),
            title: context.tr('special_discounts'),
            subtitle: context.tr('clinic_deals'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ClinicDealsPage()),
              );
            },
          ),
          _buildActionCard(
            icon: "🗓️",
            title: context.tr('my_appointments'),
            subtitle: context.tr('view_schedule'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppointmentPage()),
              );
            },
          ),
          _buildActionCardWithImage(
            icon: Images.getImage("images/medical_record.png", 36.0, 36.0),
            title: context.tr('my_medical_record'),
            subtitle: context.tr('view_documents'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyDocumentsPage()),
              );
            },
          ),
          _buildActionCard(
            icon: "📞",
            title: context.tr('contact_clinic'),
            subtitle: context.tr('get_in_touch'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ClinicProfilePage()),
              );
            },
          ),
          _buildActionCard(
            icon: "📋",
            title: context.tr('instructions'),
            subtitle: "לפני ואחרי הטיפול",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const InstructionsPage()),
              );
            },
          ),
          _buildActionCardWithImage(
            icon: Images.getImage("images/coupon.png", 36.0, 36.0),
            title: context.tr('coupons'),
            subtitle: context.tr('active_deals'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CouponPage()),
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

  Widget _buildActionCardWithImage({
    required Widget icon,
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
            icon,  // Now directly using the Widget
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

  Future<void> _callEmergency() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '100');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Widget _buildEmergencyButton() {
    return Positioned(
      bottom: 30,
      right: 20,
      child: GestureDetector(
        onTap: _callEmergency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8B94), Color(0xFFFF6B6B)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "🚨",
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              child: Text(
                context.tr('emergency'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B6B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}