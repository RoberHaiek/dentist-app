import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Images.dart';
import '../services/LocalizationProvider.dart';
import 'AppointmentPage.dart';
import 'BookAppointmentPage.dart';
import 'HomePage.dart';

class ContactClinicPage extends StatelessWidget {
  const ContactClinicPage({super.key});

  Future<void> _showPhoneOptions(BuildContext context, String number) async {
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
                  leading: const Icon(Icons.phone, color: Color(0xFF7DD3C0)),
                  title: Text(context.tr('call')),
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri uri = Uri(scheme: "tel", path: number);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy, color: Color(0xFF7DD3C0)),
                  title: Text(context.tr('copy_number')),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: number));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('phone_copied')),
                        backgroundColor: const Color(0xFF7DD3C0),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEmailOptions(BuildContext context, String email) async {
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
                  leading: const Icon(Icons.email, color: Color(0xFF7DD3C0)),
                  title: Text(context.tr('send_email')),
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri uri = Uri(scheme: "mailto", path: email);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy, color: Color(0xFF7DD3C0)),
                  title: Text(context.tr('copy_email')),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: email));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('email_copied')),
                        backgroundColor: const Color(0xFF7DD3C0),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchWaze(BuildContext context) async {
    final Uri wazeUri = Uri.parse('https://waze.com/ul/hsvbgqm1we');
    try {
      if (await canLaunchUrl(wazeUri)) {
        await launchUrl(wazeUri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('could_not_open_waze')),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('error')}: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const clinicAddress = "עפרוני 38, עכו";
    const phoneNumber = "04-9916245";
    const email = "a049916245@gmail.com";

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: Text(
          context.tr('contact_clinic'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        child: Column(
          children: [
            // Top panel with doctor info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Images.getImage("images/dentist_icon.png", 100, 100),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    context.tr('example_doctor_1'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('dental_specialist'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const BookAppointmentPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF7DD3C0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      context.tr('book_appointment'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info panel
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Opening hours
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF7DD3C0), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('opening_hours'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHoursRow(context, context.tr('monday'), "09:00 - 17:00", true),
                  _buildHoursRow(context, context.tr('tuesday'), "09:00 - 17:00", false),
                  _buildHoursRow(context, context.tr('wednesday'), "09:00 - 17:00", true),
                  _buildHoursRow(context, context.tr('thursday'), "09:00 - 17:00", false),
                  _buildHoursRow(context, context.tr('friday'), "09:00 - 13:00", true),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Address with copy button
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFF7DD3C0), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('address'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EBE2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            clinicAddress,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Color(0xFF7DD3C0)),
                          tooltip: context.tr('copy_address'),
                          onPressed: () {
                            Clipboard.setData(
                                const ClipboardData(text: clinicAddress));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.tr('address_copied')),
                                backgroundColor: const Color(0xFF7DD3C0),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Waze Navigation Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF33CCFF), Color(0xFF00B8D4)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00B8D4).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _launchWaze(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'images/waze_icon.jpg',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                context.tr('navigate_with_waze'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Phone clickable
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Color(0xFF7DD3C0), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('phone'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showPhoneOptions(context, phoneNumber),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EBE2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text(
                              phoneNumber,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF7DD3C0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Color(0xFF7DD3C0),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Email clickable
                  Row(
                    children: [
                      const Icon(Icons.email, color: Color(0xFF7DD3C0), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('email'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showEmailOptions(context, email),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EBE2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF7DD3C0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Color(0xFF7DD3C0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursRow(BuildContext context, String day, String hours, bool isAlternate) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isAlternate ? const Color(0xFFF2EBE2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            hours,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}