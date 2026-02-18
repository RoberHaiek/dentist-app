import 'package:flutter/material.dart';
import '../../Images.dart';
import '../../services/LocalizationProvider.dart';
import 'BookAppointmentPage.dart';

class ClinicDealsPage extends StatefulWidget {
  const ClinicDealsPage({super.key});

  @override
  State<ClinicDealsPage> createState() => _ClinicDealsPageState();
}

class _ClinicDealsPageState extends State<ClinicDealsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Coupon> availableCoupons = [
    Coupon(
      id: "1",
      campaignName: "מבצע יום האהבה",
      serviceName: "הלבנת שיניים",
      originalPrice: "1200",
      discountedPrice: "750",
      expirationDate: DateTime(2026, 2, 14),
      terms: "המבצע תקף עד 14 בפברואר 2026. יש לתאם פגישה מראש. לא ניתן לשלב עם מבצעים אחרים.",
      imagePath: "images/teeth_whitening.png",
    ),
    Coupon(
      id: "2",
      campaignName: "מבצע ראש השנה",
      serviceName: "1+1 על ניקוי שיניים",
      originalPrice: null,
      discountedPrice: null,
      expirationDate: DateTime(2026, 9, 30),
      terms: "תקף לחודש ספטמבר 2026. הטיפול השני חייב להתבצע תוך 30 יום מהראשון.",
      imagePath: "images/tooth_cleaning.jpg",
    ),
    Coupon(
      id: "3",
      campaignName: "מבצע חורף",
      serviceName: "טיפולי אסתטיקה",
      originalPrice: "1500",
      discountedPrice: "1200",
      expirationDate: DateTime(2026, 3, 31),
      terms: "המבצע תקף עד סוף מרץ 2026. כולל ייעוץ חינם.",
      imagePath: "images/esthetica.png",
    ),
  ];

  final List<Coupon> usedCoupons = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
            ),
          ),
        ),
        elevation: 0,
        title: Text(
          context.tr('special_discounts'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: context.tr('available')),
            Tab(text: context.tr('used')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCouponList(availableCoupons, isUsedTab: false),
          _buildCouponList(usedCoupons, isUsedTab: true),
        ],
      ),
    );
  }

  Widget _buildCouponList(List<Coupon> coupons, {required bool isUsedTab}) {
    if (coupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUsedTab ? Icons.check_circle_outline : Icons.discount_outlined,
              size: 70,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isUsedTab ? context.tr('no_used_coupons') : context.tr('no_available_coupons'),
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        return _buildCompactCouponCard(coupons[index], isUsedTab: isUsedTab);
      },
    );
  }

  Widget _buildCompactCouponCard(Coupon coupon, {required bool isUsedTab}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo - small and compact
          if (coupon.imagePath != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                height: 140,
                color: Colors.grey[100],
                child: Image.asset(
                  coupon.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey[400]),
                      ),
                    );
                  },
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campaign name - smaller font
                Text(
                  coupon.campaignName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7DD3C0),
                  ),
                ),
                const SizedBox(height: 8),

                // Service name and price on SAME LINE
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        coupon.serviceName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    if (coupon.originalPrice != null && coupon.discountedPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        "${coupon.discountedPrice}₪",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7DD3C0),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${coupon.originalPrice}₪",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Terms text
                Text(
                  coupon.terms,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Terms and conditions link
                GestureDetector(
                  onTap: () => _showTermsDialog(context, coupon),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('terms_conditions'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Make appointment button
                if (!isUsedTab)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BookAppointmentPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7DD3C0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        context.tr('book_appointment'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context, Coupon coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('terms_conditions')),
        content: Text(coupon.terms, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('close')),
          ),
        ],
      ),
    );
  }
}

class Coupon {
  final String id;
  final String campaignName;
  final String serviceName;
  final String? originalPrice;
  final String? discountedPrice;
  final DateTime expirationDate;
  final String terms;
  final String? imagePath;

  Coupon({
    required this.id,
    required this.campaignName,
    required this.serviceName,
    this.originalPrice,
    this.discountedPrice,
    required this.expirationDate,
    required this.terms,
    this.imagePath,
  });
}