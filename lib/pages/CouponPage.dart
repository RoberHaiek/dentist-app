import 'package:flutter/material.dart';
import '../Images.dart';
import 'HomePage.dart';

class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data - replace with your actual data source
  final List<Coupon> availableCoupons = [
    Coupon(
      id: "1",
      serviceName: "Colgate toothpaste",
      discount: "20%",
      expirationDate: DateTime(2024, 12, 31),
      terms: "Valid for regular Colgate toothpaste only. Cannot be combined with other offers.",
      discountType: DiscountType.percentage,
      imagePath: "images/coupons/colgate_toothpaste.jpg",
    ),
    Coupon(
      id: "2",
      serviceName: "Electric toothbrush",
      discount: "₪150",
      expirationDate: DateTime(2024, 11, 30),
      terms: "Valid for this brand only. Cannot be combined with other offers.",
      discountType: DiscountType.fixed,
      imagePath: "images/coupons/electric_toothbrush.jpg",
    ),
    Coupon(
      id: "3",
      serviceName: "Dental Checkup",
      discount: "Free",
      expirationDate: DateTime(2025, 1, 15),
      terms: "First-time patients only. Includes basic examination.",
      discountType: DiscountType.free,
    ),
  ];

  final List<Coupon> usedCoupons = [
    Coupon(
      id: "4",
      serviceName: "Root Canal Treatment",
      discount: "10%",
      expirationDate: DateTime(2024, 10, 20),
      terms: "Used on Oct 15, 2024",
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
        title: Text("My Coupons", style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue[900]),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue[900],
          labelColor: Colors.blue[900],
          unselectedLabelColor: Colors.blue[600],
          tabs: const [
            Tab(text: "Available"),
            Tab(text: "Used"),
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
              isUsedTab ? "No used coupons yet" : "No available coupons",
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
                        ? "Used"
                        : "Valid until ${_formatDate(coupon.expirationDate)}",
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
                        "Tap for terms & conditions",
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF629C86),
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
                      onPressed: () => _activateCoupon(coupon),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5FC4AD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Activate Coupon",
                        style: TextStyle(
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
        title: const Text("Terms & Conditions"),
        content: Text(coupon.terms),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _activateCoupon(Coupon coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Activate Coupon?"),
        content: Text(
          "Are you sure you want to activate the coupon for ${coupon.serviceName}?\n\n"
          "Once activated, you'll receive a barcode to use at the clinic."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showBarcodeScreen(coupon);
            },
            child: const Text("Activate"),
          ),
        ],
      ),
    );
  }

  void _showBarcodeScreen(Coupon coupon) {
    // Navigate to barcode screen or show barcode dialog
    // You'll need to implement barcode generation here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Coupon Activated!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Coupon for ${coupon.serviceName}"),
            const SizedBox(height: 16),
            Container(
              height: 100,
              color: Colors.grey[300],
              child: Center(
                child: Images.getImage("images/barcode.png", 200.0, 200.0),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Show this at the store",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
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