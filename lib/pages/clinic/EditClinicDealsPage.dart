import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────
class _Deal {
  String id;
  String title;
  String description;
  String type; // 'flat', 'percentage', '1+1', 'buyXgetY', 'package', 'seasonal'
  String? photoUrl;
  File? photoFile;
  bool isActive;

  // Pricing (for flat/percentage)
  double? originalPrice;
  double? newPrice;
  int? percentOff;

  // Buy X Get Y
  int? buyQuantity;
  int? getQuantity;

  // Package deal
  List<String>? packageItems;

  // Validity
  DateTime? validFrom;
  DateTime? validUntil;

  _Deal({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.photoUrl,
    this.photoFile,
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

  factory _Deal.from(Map<String, dynamic> m) {
    return _Deal(
      id: m['id'] as String? ?? UniqueKey().toString(),
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'photoUrl': photoUrl,
      'isActive': isActive,
      if (originalPrice != null) 'originalPrice': originalPrice,
      if (newPrice != null) 'newPrice': newPrice,
      if (percentOff != null) 'percentOff': percentOff,
      if (buyQuantity != null) 'buyQuantity': buyQuantity,
      if (getQuantity != null) 'getQuantity': getQuantity,
      if (packageItems != null) 'packageItems': packageItems,
      if (validFrom != null) 'validFrom': Timestamp.fromDate(validFrom!),
      if (validUntil != null) 'validUntil': Timestamp.fromDate(validUntil!),
    };
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

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class EditClinicDealsPage extends StatefulWidget {
  const EditClinicDealsPage({super.key});
  @override
  State<EditClinicDealsPage> createState() => _EditClinicDealsPageState();
}

class _EditClinicDealsPageState extends State<EditClinicDealsPage> {
  bool _loading = true;
  bool _saving = false;
  List<_Deal> _deals = [];

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('clinics').doc(user.uid).get();
      final data = doc.data() ?? {};
      final dealsData = data['deals'] as List? ?? [];

      setState(() {
        _deals = dealsData.map((d) => _Deal.from(d as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading deals: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveDeals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      // Upload any new photos
      for (var deal in _deals) {
        if (deal.photoFile != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('clinics/${user.uid}/deals/${deal.id}.jpg');

          // Fix threading issue: Read file as bytes, then use putData
          try {
            final bytes = await deal.photoFile!.readAsBytes();
            await ref.putData(
              bytes,
              SettableMetadata(contentType: 'image/jpeg'),
            );
            deal.photoUrl = await ref.getDownloadURL();
            deal.photoFile = null;
          } catch (e) {
            debugPrint('Upload error for deal ${deal.id}: $e');
            rethrow;
          }
        }
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('clinics').doc(user.uid).set({
        'deals': _deals.map((d) => d.toMap()).toList(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deals saved successfully'),
            backgroundColor: Color(0xFF7DD3C0),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addDeal() {
    setState(() {
      _deals.add(_Deal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '',
        description: '',
        type: 'flat',
      ));
    });
  }

  void _removeDeal(int index) {
    setState(() => _deals.removeAt(index));
  }

  void _editDeal(int index) {
    final deal = _deals[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DealEditDialog(
          deal: deal,
          onSave: (updated) {
            setState(() => _deals[index] = updated);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF7DD3C0),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (!_loading)
                TextButton.icon(
                  onPressed: _saving ? null : _saveDeals,
                  icon: _saving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.check, color: Colors.white),
                  label: Text(
                    _saving ? 'Saving...' : 'Save',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Edit Deals',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.local_offer, size: 80, color: Colors.white24),
                ),
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3C0)))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add Deal Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addDeal,
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Deal'),
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
              const SizedBox(height: 20),

              // Deals List
              if (_deals.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'No deals yet',
                          style: TextStyle(fontSize: 16, color: Color(0xFF999999)),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap "Add New Deal" to create your first offer',
                          style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(_deals.length, (index) {
                  return _buildDealCard(index);
                }),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDealCard(int index) {
    final deal = _deals[index];

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
          if (deal.photoFile != null || deal.photoUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: deal.photoFile != null
                  ? Image.file(
                deal.photoFile!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Image.network(
                deal.photoUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge and type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: deal.isActive
                            ? const Color(0xFF7DD3C0).withOpacity(0.15)
                            : Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        deal.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: deal.isActive ? const Color(0xFF7DD3C0) : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        deal.typeDisplay,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  deal.title.isEmpty ? 'Untitled Deal' : deal.title,
                  style: const TextStyle(
                    fontSize: 18,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),

                // Deal details
                _buildDealDetails(deal),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editDeal(index),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7DD3C0),
                          side: const BorderSide(color: Color(0xFF7DD3C0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _removeDeal(index),
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealDetails(_Deal deal) {
    switch (deal.type) {
      case 'flat':
        return Row(
          children: [
            if (deal.originalPrice != null) ...[
              Text(
                '₪${deal.originalPrice!.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.lineThrough,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (deal.newPrice != null)
              Text(
                '₪${deal.newPrice!.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7DD3C0),
                ),
              ),
          ],
        );

      case 'percentage':
        return Text(
          '${deal.percentOff ?? 0}% OFF',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7DD3C0),
          ),
        );

      case '1+1':
        return const Text(
          'Buy 1 Get 1 Free',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7DD3C0),
          ),
        );

      case 'buyXgetY':
        return Text(
          'Buy ${deal.buyQuantity ?? 1} Get ${deal.getQuantity ?? 1} Free',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7DD3C0),
          ),
        );

      case 'package':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Package includes:',
              style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 4),
            ...?deal.packageItems?.take(3).map((item) => Text(
              '• $item',
              style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
            )),
            if ((deal.packageItems?.length ?? 0) > 3)
              Text(
                '  +${(deal.packageItems!.length - 3)} more',
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
          ],
        );

      case 'seasonal':
        if (deal.validUntil != null) {
          return Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF999999)),
              const SizedBox(width: 4),
              Text(
                'Valid until ${DateFormat('MMM d, y').format(deal.validUntil!)}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
              ),
            ],
          );
        }
        return const SizedBox();

      default:
        return const SizedBox();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deal Edit Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _DealEditDialog extends StatefulWidget {
  final _Deal deal;
  final Function(_Deal) onSave;

  const _DealEditDialog({required this.deal, required this.onSave});

  @override
  State<_DealEditDialog> createState() => _DealEditDialogState();
}

class _DealEditDialogState extends State<_DealEditDialog> {
  late _Deal _deal;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _origPriceController = TextEditingController();
  final _newPriceController = TextEditingController();
  final _percentController = TextEditingController();
  final _buyQtyController = TextEditingController();
  final _getQtyController = TextEditingController();
  final _packageItemController = TextEditingController();
  List<String> _packageItems = [];

  @override
  void initState() {
    super.initState();
    _deal = widget.deal;
    _titleController.text = _deal.title;
    _descController.text = _deal.description;
    _origPriceController.text = _deal.originalPrice?.toStringAsFixed(0) ?? '';
    _newPriceController.text = _deal.newPrice?.toStringAsFixed(0) ?? '';
    _percentController.text = _deal.percentOff?.toString() ?? '';
    _buyQtyController.text = _deal.buyQuantity?.toString() ?? '';
    _getQtyController.text = _deal.getQuantity?.toString() ?? '';
    _packageItems = List.from(_deal.packageItems ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _origPriceController.dispose();
    _newPriceController.dispose();
    _percentController.dispose();
    _buyQtyController.dispose();
    _getQtyController.dispose();
    _packageItemController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final xfile = await picker.pickImage(source: result, imageQuality: 85);
      if (xfile != null) {
        setState(() {
          _deal.photoFile = File(xfile.path);
          _deal.photoUrl = null;
        });
      }
    }
  }

  void _save() {
    _deal.title = _titleController.text.trim();
    _deal.description = _descController.text.trim();

    switch (_deal.type) {
      case 'flat':
        _deal.originalPrice = double.tryParse(_origPriceController.text);
        _deal.newPrice = double.tryParse(_newPriceController.text);
        break;
      case 'percentage':
        _deal.percentOff = int.tryParse(_percentController.text);
        break;
      case 'buyXgetY':
        _deal.buyQuantity = int.tryParse(_buyQtyController.text);
        _deal.getQuantity = int.tryParse(_getQtyController.text);
        break;
      case 'package':
        _deal.packageItems = _packageItems;
        break;
    }

    widget.onSave(_deal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: const Text('Edit Deal', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  image: _deal.photoFile != null
                      ? DecorationImage(image: FileImage(_deal.photoFile!), fit: BoxFit.cover)
                      : _deal.photoUrl != null
                      ? DecorationImage(image: NetworkImage(_deal.photoUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: _deal.photoFile == null && _deal.photoUrl == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 48, color: Color(0xFF999999)),
                    SizedBox(height: 8),
                    Text('Tap to add photo', style: TextStyle(color: Color(0xFF999999))),
                  ],
                )
                    : const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, color: Color(0xFF7DD3C0)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Deal Title *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Deal Type
            DropdownButtonFormField<String>(
              value: _deal.type,
              decoration: InputDecoration(
                labelText: 'Deal Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'flat', child: Text('Flat Discount')),
                DropdownMenuItem(value: 'percentage', child: Text('Percentage Off')),
                DropdownMenuItem(value: '1+1', child: Text('1+1 Deal')),
                DropdownMenuItem(value: 'buyXgetY', child: Text('Buy X Get Y')),
                DropdownMenuItem(value: 'package', child: Text('Package Deal')),
                DropdownMenuItem(value: 'seasonal', child: Text('Seasonal Offer')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _deal.type = value);
                }
              },
            ),
            const SizedBox(height: 20),

            // Type-specific fields
            ..._buildTypeSpecificFields(),

            const SizedBox(height: 20),

            // Active toggle
            SwitchListTile(
              title: const Text('Active', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_deal.isActive ? 'Deal is visible to patients' : 'Deal is hidden'),
              value: _deal.isActive,
              activeColor: const Color(0xFF7DD3C0),
              onChanged: (value) {
                setState(() => _deal.isActive = value);
              },
            ),

            const SizedBox(height: 20),

            // Validity dates
            _buildDateField('Valid From', _deal.validFrom, (date) {
              setState(() => _deal.validFrom = date);
            }),
            const SizedBox(height: 16),
            _buildDateField('Valid Until', _deal.validUntil, (date) {
              setState(() => _deal.validUntil = date);
            }),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTypeSpecificFields() {
    switch (_deal.type) {
      case 'flat':
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _origPriceController,
                  decoration: InputDecoration(
                    labelText: 'Original Price (₪)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _newPriceController,
                  decoration: InputDecoration(
                    labelText: 'New Price (₪)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ];

      case 'percentage':
        return [
          TextField(
            controller: _percentController,
            decoration: InputDecoration(
              labelText: 'Percentage Off (%)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
        ];

      case '1+1':
        return [
          const Text(
            'Buy 1 Get 1 Free',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF7DD3C0)),
          ),
          const SizedBox(height: 8),
          const Text('No additional configuration needed', style: TextStyle(color: Color(0xFF999999))),
        ];

      case 'buyXgetY':
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _buyQtyController,
                  decoration: InputDecoration(
                    labelText: 'Buy Quantity',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _getQtyController,
                  decoration: InputDecoration(
                    labelText: 'Get Quantity',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ];

      case 'package':
        return [
          const Text(
            'Package Items',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 8),
          ..._packageItems.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                Expanded(child: Text(item)),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: () {
                    setState(() => _packageItems.remove(item));
                  },
                ),
              ],
            ),
          )),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _packageItemController,
                  decoration: InputDecoration(
                    labelText: 'Add item',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  if (_packageItemController.text.trim().isNotEmpty) {
                    setState(() {
                      _packageItems.add(_packageItemController.text.trim());
                      _packageItemController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.add_circle, color: Color(0xFF7DD3C0), size: 32),
              ),
            ],
          ),
        ];

      case 'seasonal':
        return [
          const Text(
            'Seasonal offer - set validity dates below',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ];

      default:
        return [];
    }
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime?) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Color(0xFF7DD3C0)),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF7DD3C0)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                  const SizedBox(height: 4),
                  Text(
                    date != null ? DateFormat('MMM d, y').format(date) : 'Not set',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
                  ),
                ],
              ),
            ),
            if (date != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onChanged(null),
              ),
          ],
        ),
      ),
    );
  }
}