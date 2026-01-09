import 'package:dentist_app/pages/AboutPage.dart';
import 'package:dentist_app/pages/AppointmentPage.dart';
import 'package:dentist_app/pages/ContactClinicPage.dart';
import 'package:dentist_app/pages/CouponPage.dart';
import 'package:dentist_app/pages/LoginPage.dart';
import 'package:dentist_app/pages/MyMedicalReportPage.dart';
import 'package:dentist_app/pages/SettingsPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../CurrentPatient.dart';
import '../Images.dart';
import 'MyDocumentsPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final CurrentPatient currentPatient = CurrentPatient();
  bool loading = true;

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
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      children: [
                        _buildHeroSection(),
                        const SizedBox(height: 30),
                        _buildBookAppointmentButton(),
                        const SizedBox(height: 30),
                        _buildActionCards(),
                        const SizedBox(height: 30),
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
//                 const SizedBox(width: 48), // Spacer for centering
                const Icon(Icons.notifications_outlined,
                    size: 28, color: Colors.white),
                IconButton(
                  icon: const Icon(Icons.settings, size: 28, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacement(
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
                  "Hi ${currentPatient.firstName}! ✨",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your smile matters to us",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),

                // Mascot tooth character
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _buildToothMascot(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToothMascot() {
    return SizedBox(
      width: 70,
      height: 70,
      child: CustomPaint(
        painter: ToothMascotPainter(),
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => AppointmentPage()),
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
            children: const [
              Text(
                "📅",
                style: TextStyle(fontSize: 26),
              ),
              SizedBox(width: 12),
              Text(
                "Book Appointment",
                style: TextStyle(
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
          _buildActionCard(
            icon: "📄",
            title: "Documents",
            subtitle: "View files",
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const MyDocumentsPage()),
              );
            },
          ),
          _buildActionCard(
            icon: "🏷️️",
            title: "Coupons",
            subtitle: "Active deals",
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CouponPage()),
              );
            },
          ),
          _buildActionCard(
            icon: "🗓️",
            title: "Appointments",
            subtitle: "View schedule",
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AppointmentPage()),
              );
            },
          ),
          _buildActionCard(
            icon: "📞",
            title: "Contact Clinic",
            subtitle: "Get in touch",
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const ContactClinicPage()),
              );
            },
          ),
          _buildActionCard(
            icon: "📝",
            title: "Instructions",
            subtitle: "Before or after treatment",
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AppointmentPage()),
              );
            },
          ),
          _buildActionCard(
            icon: "🦷",
            title: "My teeth",
            subtitle: "See the teeth situation",
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const ContactClinicPage()),
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

  Widget _buildEmergencyButton() {
    return Positioned(
      bottom: 30,
      right: 20,
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const ContactClinicPage()),
          );
        },
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
              child: const Text(
                "Emergency",
                style: TextStyle(
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

// Custom painter for tooth mascot
class ToothMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFFA8E6CF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw tooth body (rounded rectangle)
    final toothPath = Path();
    toothPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.2, size.height * 0.1, size.width * 0.6,
            size.height * 0.7),
        const Radius.circular(20),
      ),
    );
    canvas.drawPath(toothPath, paint);
    canvas.drawPath(toothPath, outlinePaint);

    // Draw smile
    final smilePaint = Paint()
      ..color = const Color(0xFFFF8B94)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final smilePath = Path();
    smilePath.moveTo(size.width * 0.3, size.height * 0.5);
    smilePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.6,
      size.width * 0.7,
      size.height * 0.5,
    );
    canvas.drawPath(smilePath, smilePaint);

    // Draw eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.35, size.height * 0.35), 3, eyePaint);
    canvas.drawCircle(
        Offset(size.width * 0.65, size.height * 0.35), 3, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}