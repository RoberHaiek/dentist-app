import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ClinicQRPage extends StatelessWidget {
  final String clinicId;
  final String clinicName;
  final String registrationCode;

  const ClinicQRPage({
    super.key,
    required this.clinicId,
    required this.clinicName,
    required this.registrationCode,
  });

  @override
  Widget build(BuildContext context) {
    // The QR encodes a deep-link style string the scanner will parse
    final qrData = 'dentist://register?clinicId=$clinicId&code=$registrationCode';

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: const Text('Clinic QR Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)]),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              clinicName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Patients can scan this code to connect to your clinic',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // QR Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF333333),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EBE2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.vpn_key, color: Color(0xFF7DD3C0), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          registrationCode,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Or use the code above to register manually',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Info tiles
            _buildInfoTile(Icons.security, 'Secure', 'Each scan is verified against your clinic ID'),
            const SizedBox(height: 12),
            _buildInfoTile(Icons.bolt, 'Instant', 'Patient is connected immediately after scanning'),
            const SizedBox(height: 12),
            _buildInfoTile(Icons.refresh, 'Permanent', 'This QR code never expires'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7DD3C0).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF7DD3C0), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}