import 'package:flutter/material.dart';
import '../Images.dart';
import '../services/LocalizationProvider.dart';
import 'BookAppointmentPage.dart';
import 'HomePage.dart';

class ClinicDealsPage extends StatefulWidget {
  const ClinicDealsPage({super.key});

  @override
  State<ClinicDealsPage> createState() => _ClinicDealsPageState();
}

class _ClinicDealsPageState extends State<ClinicDealsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data - replace with your actual data source
  final List<Coupon> availableCoupons = [
    Coupon(
      id: "1",
      serviceName: "ניקוי אבנית",
      discount: "20%",
      expirationDate: DateTime(2025, 12, 31),
      terms: "תקף למשחת שיניים קולגייט רגילה בלבד. לא ניתן לשלב עם מבצעים אחרים.",
      discountType: DiscountType.percentage,
      imagePath: "images/tooth_cleaning.jpg",
    ),
    Coupon(
      id: "2",
      serviceName: "בוטוקס",
      discount: "₪150",
      expirationDate: DateTime(2025, 11, 30),
      terms: "תקף למשחת שיניים קולגייט רגילה בלבד. לא ניתן לשלב עם מבצעים אחרים.",
      discountType: DiscountType.fixed,
      imagePath: "images/botox.jpg",
    ),
    Coupon(
      id: "3",
      serviceName: "אסתטיקה",
      discount: "₪300",
      expirationDate: DateTime(2025, 1, 15),
      terms: "תקף למשחת שיניים קולגייט רגילה בלבד. לא ניתן לשלב עם מבצעים אחרים.",
      discountType: DiscountType.fixed,
      imagePath: "images/esthetica.png",
    ),
  ];

  final List<Coupon> usedCoupons = [
    Coupon(
      id: "4",
      serviceName: "בוטוקס",
      discount: "10%",
      expirationDate: DateTime(2025, 10, 20),
      terms: "שומש ב־15 באוקטובר 2025",
      discountType: DiscountType.percentage,
      isUsed: true,
    ),
  ];

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
        backgroundColor: const Color(0xFFA8E6CF),
        elevation: 0,
        title: Text(
          context.tr('special_discounts'),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue[600],
          labelColor: Colors.blue[600],
          unselectedLabelColor: Colors.white,
          tabs: [
            Tab(text: context.tr('available')),
            Tab(text: context.tr('used')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Available Coupons Tab
          _buildCouponList(availableCoupons, isUsedTab: false),
          // Used Coupons Tab
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
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isUsedTab ? context.tr('no_used_coupons') : context.tr('no_available_coupons'),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        return _buildCouponCard(coupons[index], isUsedTab: isUsedTab);
      },
    );
  }

  Widget _buildCouponCard(Coupon coupon, {required bool isUsedTab}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with colored stripe based on discount type
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: _getDiscountColor(coupon.discountType),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image (if available)
                if (coupon.imagePath != null)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                          ),
                          child: Image.asset(
                            coupon.imagePath!,
                            fit: BoxFit.contain, // Shows full image without cropping
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Service name and discount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        coupon.serviceName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isUsedTab ? Colors.grey[600] : Colors.blue[900],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getDiscountColor(coupon.discountType).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        coupon.discount,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getDiscountColor(coupon.discountType),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Expiration date
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: _isExpiringSoon(coupon.expirationDate)
                          ? Colors.red
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isUsedTab
                          ? context.tr('used')
                          : "${context.tr('valid_until')} ${_formatDate(coupon.expirationDate)}",
                      style: TextStyle(
                        fontSize: 14,
                        color: _isExpiringSoon(coupon.expirationDate)
                            ? Colors.red
                            : Colors.grey[600],
                        fontWeight: _isExpiringSoon(coupon.expirationDate)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Terms & Conditions (collapsible)
                GestureDetector(
                  onTap: () => _showTermsDialog(context, coupon),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('tap_for_terms'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF629C86),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action button
                if (!isUsedTab)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BookAppointmentPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5FC4AD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.tr('book_appointment'),
                        style: const TextStyle(
                          fontSize: 16,
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

  Color _getDiscountColor(DiscountType type) {
    switch (type) {
      case DiscountType.percentage:
        return const Color(0xFFA8E6CF);
      case DiscountType.fixed:
        return const Color(0xFFFF8B94);
      case DiscountType.free:
        return const Color(0xFF7DD3C0);
    }
  }

  bool _isExpiringSoon(DateTime expirationDate) {
    final daysUntilExpiration = expirationDate.difference(DateTime.now()).inDays;
    return daysUntilExpiration <= 7 && daysUntilExpiration >= 0;
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showTermsDialog(BuildContext context, Coupon coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('terms_conditions')),
        content: Text(coupon.terms),
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

// Data models
enum DiscountType {
  percentage,
  fixed,
  free,
}

class Coupon {
  final String id;
  final String serviceName;
  final String discount;
  final DateTime expirationDate;
  final String terms;
  final DiscountType discountType;
  final bool isUsed;
  final String? imagePath;

  Coupon({
    required this.id,
    required this.serviceName,
    required this.discount,
    required this.expirationDate,
    required this.terms,
    required this.discountType,
    this.isUsed = false,
    this.imagePath,
  });
}