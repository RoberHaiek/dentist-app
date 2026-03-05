import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ClinicDealsPage extends StatefulWidget {
  final String? clinicId;

  const ClinicDealsPage({super.key, required this.clinicId});

  @override
  State<ClinicDealsPage> createState() => _ClinicDealsPageState();
}

class _ClinicDealsPageState extends State<ClinicDealsPage> {
  bool _loading = true;
  List<DealItem> _deals = [];
  String _clinicName = '';
  String _clinicPhone = '';
  String? _selectedType;

  final List<String> _dealTypes = [
    'All',
    'Flat Discount',
    'Percentage Off',
    '1+1 Deal',
    'Buy X Get Y',
    'Package Deal',
    'Seasonal Offer',
  ];

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    if (widget.clinicId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicId!)
          .get();

      if (!clinicDoc.exists) {
        setState(() => _loading = false);
        return;
      }

      final data = clinicDoc.data() ?? {};
      _clinicName = data['clinicName'] as String? ?? 'Clinic';
      _clinicPhone = data['phoneNumber'] as String? ?? '';

      final dealsData = data['deals'] as List? ?? [];
      final now = DateTime.now();

      setState(() {
        _deals = dealsData
            .map((d) => DealItem.from(d as Map<String, dynamic>))
            .where((deal) {
          // Only show active deals
          if (!deal.isActive) return false;

          // Check validity dates
          if (deal.validFrom != null && now.isBefore(deal.validFrom!)) return false;
          if (deal.validUntil != null && now.isAfter(deal.validUntil!)) return false;

          return true;
        })
            .toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading deals: $e');
      setState(() => _loading = false);
    }
  }

  List<DealItem> get _filteredDeals {
    if (_selectedType == null || _selectedType == 'All') {
      return _deals;
    }

    final typeMap = {
      'Flat Discount': 'flat',
      'Percentage Off': 'percentage',
      '1+1 Deal': '1+1',
      'Buy X Get Y': 'buyXgetY',
      'Package Deal': 'package',
      'Seasonal Offer': 'seasonal',
    };

    final filterType = typeMap[_selectedType];
    return _deals.where((deal) => deal.type == filterType).toList();
  }

  Future<void> _callClinic() async {
    if (_clinicPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    final uri = Uri.parse('tel:$_clinicPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: const Text(
          'Deals & Offers',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)]),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3C0)))
          : Column(
        children: [
          // Filter chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _dealTypes.map((type) {
                  final isSelected = _selectedType == type || (_selectedType == null && type == 'All');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedType = selected ? type : null);
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: const Color(0xFF7DD3C0).withOpacity(0.2),
                      checkmarkColor: const Color(0xFF7DD3C0),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF7DD3C0) : const Color(0xFF666666),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Deals count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF2EBE2),
            child: Text(
              '${_filteredDeals.length} deal${_filteredDeals.length != 1 ? 's' : ''} available',
              style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
          ),

          // Deals list
          Expanded(
            child: _filteredDeals.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _selectedType == null || _selectedType == 'All'
                        ? 'No deals available'
                        : 'No $_selectedType deals',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredDeals.length,
              itemBuilder: (context, index) {
                return _buildDealCard(_filteredDeals[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _deals.isNotEmpty
          ? Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _callClinic,
            icon: const Icon(Icons.phone),
            label: const Text('Call to Book'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7DD3C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildDealCard(DealItem deal) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (deal.photoUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                deal.photoUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Color(0xFF999999)),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7DD3C0).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    deal.typeDisplay,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7DD3C0),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  deal.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                if (deal.description.isNotEmpty)
                  Text(
                    deal.description,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                const SizedBox(height: 16),

                // Deal details
                _buildDealDetails(deal),

                // Validity
                if (deal.validUntil != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Valid until ${DateFormat('MMM d, y').format(deal.validUntil!)}',
                        style: TextStyle(fontSize: 13, color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealDetails(DealItem deal) {
    switch (deal.type) {
      case 'flat':
        return Row(
          children: [
            if (deal.originalPrice != null) ...[
              Text(
                '₪${deal.originalPrice!.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  decoration: TextDecoration.lineThrough,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (deal.newPrice != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7DD3C0).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₪${deal.newPrice!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7DD3C0),
                  ),
                ),
              ),
            if (deal.originalPrice != null && deal.newPrice != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Save ₪${(deal.originalPrice! - deal.newPrice!).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ],
        );

      case 'percentage':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF7DD3C0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${deal.percentOff ?? 0}%',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7DD3C0),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'OFF',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7DD3C0),
                ),
              ),
            ],
          ),
        );

      case '1+1':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF7DD3C0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_shopping_cart, color: Color(0xFF7DD3C0), size: 28),
              SizedBox(width: 12),
              Text(
                'Buy 1 Get 1 FREE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7DD3C0),
                ),
              ),
            ],
          ),
        );

      case 'buyXgetY':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF7DD3C0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.redeem, color: Color(0xFF7DD3C0), size: 28),
              const SizedBox(width: 12),
              Text(
                'Buy ${deal.buyQuantity ?? 1} Get ${deal.getQuantity ?? 1} Free',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7DD3C0),
                ),
              ),
            ],
          ),
        );

      case 'package':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Package includes:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            ...?deal.packageItems?.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Color(0xFF7DD3C0)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                  ),
                ],
              ),
            )),
          ],
        );

      case 'seasonal':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'Limited Time Offer!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }
}

class DealItem {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? photoUrl;
  final bool isActive;
  final double? originalPrice;
  final double? newPrice;
  final int? percentOff;
  final int? buyQuantity;
  final int? getQuantity;
  final List<String>? packageItems;
  final DateTime? validFrom;
  final DateTime? validUntil;

  DealItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.photoUrl,
    this.isActive = true,
    this.originalPrice,
    this.newPrice,
    this.percentOff,
    this.buyQuantity,
    this.getQuantity,
    this.packageItems,
    this.validFrom,
    this.validUntil,
  });

  factory DealItem.from(Map<String, dynamic> m) {
    return DealItem(
      id: m['id'] as String? ?? '',
      title: m['title'] as String? ?? '',
      description: m['description'] as String? ?? '',
      type: m['type'] as String? ?? 'flat',
      photoUrl: m['photoUrl'] as String?,
      isActive: m['isActive'] as bool? ?? true,
      originalPrice: (m['originalPrice'] as num?)?.toDouble(),
      newPrice: (m['newPrice'] as num?)?.toDouble(),
      percentOff: m['percentOff'] as int?,
      buyQuantity: m['buyQuantity'] as int?,
      getQuantity: m['getQuantity'] as int?,
      packageItems: (m['packageItems'] as List?)?.cast<String>(),
      validFrom: (m['validFrom'] as Timestamp?)?.toDate(),
      validUntil: (m['validUntil'] as Timestamp?)?.toDate(),
    );
  }

  String get typeDisplay {
    switch (type) {
      case 'flat':
        return 'Flat Discount';
      case 'percentage':
        return 'Percentage Off';
      case '1+1':
        return '1+1 Deal';
      case 'buyXgetY':
        return 'Buy X Get Y';
      case 'package':
        return 'Package Deal';
      case 'seasonal':
        return 'Seasonal Offer';
      default:
        return type;
    }
  }
}