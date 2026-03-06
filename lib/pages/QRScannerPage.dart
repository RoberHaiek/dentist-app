import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final raw = barcode!.rawValue!;

    // Parse the QR: dentist://register?clinicId=XXX&code=YYY
    if (!raw.startsWith('dentist://register')) {
      _showError('This QR code is not a valid clinic code.');
      return;
    }

    try {
      final uri = Uri.parse(raw);
      final clinicId = uri.queryParameters['clinicId'];
      final code = uri.queryParameters['code'];

      if (clinicId == null || code == null) {
        _showError('Invalid QR code format.');
        return;
      }

      setState(() => _hasScanned = true);
      _controller.stop();

      // Return both values to the caller
      Navigator.pop(context, {'clinicId': clinicId, 'code': code});
    } catch (e) {
      _showError('Could not read QR code.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFFF6B6B)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  ),
                  const Text(
                    'Scan Clinic QR',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _torchOn = !_torchOn);
                      _controller.toggleTorch();
                    },
                    icon: Icon(
                      _torchOn ? Icons.flash_on : Icons.flash_off,
                      color: _torchOn ? const Color(0xFF7DD3C0) : Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom hint
          Positioned(
            bottom: 60,
            left: 0, right: 0,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Point your camera at the clinic\'s QR code',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Draws the dark overlay with a clear square cutout in the center
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cutoutSize = 260.0;
    const radius = 16.0;

    final cutoutRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 - 40),
        width: cutoutSize,
        height: cutoutSize,
      ),
      const Radius.circular(radius),
    );

    // Dark overlay
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutoutRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    // Teal border around cutout
    final borderPaint = Paint()
      ..color = const Color(0xFF7DD3C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(cutoutRect, borderPaint);

    // Corner accents
    final cornerPaint = Paint()
      ..color = const Color(0xFF7DD3C0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    final left   = cutoutRect.left;
    final top    = cutoutRect.top;
    final right  = cutoutRect.right;
    final bottom = cutoutRect.bottom;

    // Top-left
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top + radius), cornerPaint);
    canvas.drawLine(Offset(left + radius, top), Offset(left + cornerLength, top), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(right - cornerLength, top), Offset(right - radius, top), cornerPaint);
    canvas.drawLine(Offset(right, top + radius), Offset(right, top + cornerLength), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom - radius), cornerPaint);
    canvas.drawLine(Offset(left + radius, bottom), Offset(left + cornerLength, bottom), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(right - cornerLength, bottom), Offset(right - radius, bottom), cornerPaint);
    canvas.drawLine(Offset(right, bottom - radius), Offset(right, bottom - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}