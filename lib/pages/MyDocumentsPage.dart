import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../services/LocalizationProvider.dart';
import '../CurrentPatient.dart';
import 'SettingsPage.dart';

enum DocumentCategory {
  xrays,
  treatmentPlans,
  beforeAfter,
  receipts,
  other,
}

enum XrayType {
  panoramic,
  periapical,
  bitewing,
  cbct,
  other,
}

class MyDocumentsPage extends StatefulWidget {
  const MyDocumentsPage({Key? key}) : super(key: key);

  @override
  State<MyDocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<MyDocumentsPage> {
  final List<_DocItem> _documents = [];
  final CurrentPatient currentPatient = CurrentPatient();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatient();
    _addDemoDocuments();
  }

  Future<void> _addDemoDocuments() async {
    try {
      // Load the actual images
      final panoramicData = await rootBundle.load('images/panoramic1.jpg');
      final periapicalData = await rootBundle.load('images/panoramic2.jpg');
      final bitewingData = await rootBundle.load('images/panoramic3.jpg');
      final receiptData = await rootBundle.load('images/receipt1.png');
      final otherData = await rootBundle.load('images/insurance1.jpg');

      setState(() {
        _documents.addAll([
          _DocItem(
            id: "demo_1",
            title: "Panoramic X-ray",
            date: DateTime(2026, 1, 15),
            mimeType: "image/jpeg",
            category: DocumentCategory.xrays,
            xrayType: XrayType.panoramic,
            bytes: panoramicData.buffer.asUint8List(), // ← This is the key!
          ),
          _DocItem(
            id: "demo_2",
            title: "Periapical - Upper Right",
            date: DateTime(2026, 1, 20),
            mimeType: "image/jpeg",
            category: DocumentCategory.xrays,
            xrayType: XrayType.periapical,
            bytes: periapicalData.buffer.asUint8List(), // ← Real image data
          ),
          _DocItem(
            id: "demo_3",
            title: "Bitewing - Left Side",
            date: DateTime(2025, 12, 10),
            mimeType: "image/jpeg",
            category: DocumentCategory.xrays,
            xrayType: XrayType.bitewing,
            bytes: bitewingData.buffer.asUint8List(), // ← Real image data
          ),
          _DocItem(
            id: "demo_4",
            title: "Cleaning Receipt - Jan 15.pdf",
            date: DateTime(2026, 1, 15),
            mimeType: "image/jpeg",
            category: DocumentCategory.receipts,
            bytes: receiptData.buffer.asUint8List(),
          ),
          _DocItem(
            id: "demo_5",
            title: "Root Canal Payment.pdf",
            date: DateTime(2025, 12, 5),
            mimeType: "image/jpeg",
            category: DocumentCategory.receipts,
            bytes: receiptData.buffer.asUint8List(),
          ),
          // Add 1 other
          _DocItem(
            id: "demo_6",
            title: "Insurance Form 2026.pdf",
            date: DateTime(2026, 1, 10),
            mimeType: "image/jpeg",
            category: DocumentCategory.other,
            bytes: otherData.buffer.asUint8List(),
          ),
        ]);
      });
    } catch (e) {
      print('Error loading demo images: $e');
    }
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
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: Text(
          context.tr('medical_files'),
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
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7DD3C0)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCategoryList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: const Color(0xFF7DD3C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryList() {
    return Column(
      children: DocumentCategory.values.map((category) {
        return _buildCategoryListItem(category);
      }).toList(),
    );
  }

  Widget _buildCategoryListItem(DocumentCategory category) {
    final categoryData = _getCategoryData(category);
    final count = _getDocumentCount(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openCategory(category),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: categoryData['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryData['icon'],
                    color: categoryData['color'],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Title and count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryData['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$count ${context.tr('files')}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getCategoryData(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.xrays:
        return {
          'title': context.tr('xrays_scans'),
          'icon': Icons.medical_information,
          'color': const Color(0xFF2196F3),
        };
      case DocumentCategory.treatmentPlans:
        return {
          'title': context.tr('treatment_plans'),
          'icon': Icons.assignment,
          'color': const Color(0xFF7DD3C0),
        };
      case DocumentCategory.beforeAfter:
        return {
          'title': context.tr('before_after'),
          'icon': Icons.compare,
          'color': const Color(0xFF9C27B0),
        };
      case DocumentCategory.receipts:
        return {
          'title': context.tr('receipts'),
          'icon': Icons.receipt_long,
          'color': const Color(0xFFFF9800),
        };
      case DocumentCategory.other:
        return {
          'title': context.tr('other_documents'),
          'icon': Icons.folder,
          'color': const Color(0xFF607D8B),
        };
    }
  }

  int _getDocumentCount(DocumentCategory category) {
    return _documents.where((doc) => doc.category == category).length;
  }

  void _openCategory(DocumentCategory category) {
    final categoryDocs = _documents.where((doc) => doc.category == category).toList();
    final categoryData = _getCategoryData(category);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _CategoryViewPage(
          category: category,
          categoryTitle: categoryData['title'],
          categoryColor: categoryData['color'],
          documents: categoryDocs,
          onDocumentAction: (doc, action) => _handleDocumentAction(doc, action),
          onAddDocument: () => _showAddOptionsForCategory(category),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  Future<void> _showAddOptions() async {
    final category = await showModalBottomSheet<DocumentCategory>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('select_category'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 20),
              ...DocumentCategory.values.map((cat) {
                final data = _getCategoryData(cat);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, cat),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: data['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(data['icon'], color: data['color']),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              data['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );

    if (category != null) {
      _showUploadOptions(category);
    }
  }

  Future<void> _showAddOptionsForCategory(DocumentCategory category) async {
    _showUploadOptions(category);
  }

  Future<void> _showUploadOptions(DocumentCategory category) async {
    // If xrays, also ask for xray type
    XrayType? xrayType;
    if (category == DocumentCategory.xrays) {
      xrayType = await showModalBottomSheet<XrayType>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('select_xray_type'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 20),
                ...XrayType.values.map((type) {
                  return ListTile(
                    title: Text(_getXrayTypeName(type)),
                    onTap: () => Navigator.pop(ctx, type),
                  );
                }),
              ],
            ),
          ),
        ),
      );

      if (xrayType == null) return; // User cancelled
    }

    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Wrap(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA8E6CF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF7DD3C0)),
                ),
                title: Text(
                  context.tr('take_photo'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA8E6CF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insert_drive_file, color: Color(0xFF7DD3C0)),
                ),
                title: Text(
                  context.tr('upload_file'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, 'file'),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == 'camera') {
      await _addDocumentFromCamera(category, xrayType: xrayType);
    } else if (source == 'file') {
      await _addDocumentFromFilePicker(category, xrayType: xrayType);
    }
  }

  String _getXrayTypeName(XrayType type) {
    switch (type) {
      case XrayType.panoramic:
        return context.tr('panoramic');
      case XrayType.periapical:
        return context.tr('periapical');
      case XrayType.bitewing:
        return context.tr('bitewing');
      case XrayType.cbct:
        return context.tr('cbct');
      case XrayType.other:
        return context.tr('other');
    }
  }

  Future<void> _addDocumentFromFilePicker(DocumentCategory category, {XrayType? xrayType}) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      final name = f.name;
      final bytes = f.bytes;
      final path = f.path;
      final mimeType = lookupMimeType(path ?? name) ?? "application/octet-stream";

      final newName = await _showPreviewAndAskUpload(
        titleSuggestion: name,
        previewPath: path,
        previewBytes: bytes,
        isImage: mimeType.startsWith("image/"),
      );
      if (newName == null || newName.isEmpty) return;

      setState(() {
        _documents.insert(
          0,
          _DocItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: newName,
            date: DateTime.now(),
            path: path,
            bytes: bytes,
            mimeType: mimeType,
            category: category,
            xrayType: xrayType,
          ),
        );
      });

      // Navigate to the category after adding
      _openCategory(category);
    }
  }

  Future<void> _addDocumentFromCamera(DocumentCategory category, {XrayType? xrayType}) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      final path = picked.path;
      final bytes = await picked.readAsBytes();
      final mimeType = lookupMimeType(path) ?? "image/jpeg";

      final newName = await _showPreviewAndAskUpload(
        titleSuggestion: "photo_${DateTime.now().millisecondsSinceEpoch}.jpg",
        previewPath: path,
        previewBytes: bytes,
        isImage: true,
      );
      if (newName == null || newName.isEmpty) return;

      setState(() {
        _documents.insert(
          0,
          _DocItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: newName,
            date: DateTime.now(),
            path: path,
            bytes: bytes,
            mimeType: mimeType,
            category: category,
            xrayType: xrayType,
          ),
        );
      });

      // Navigate to the category after adding
      _openCategory(category);
    }
  }

  Future<String?> _showPreviewAndAskUpload({
    required String titleSuggestion,
    String? previewPath,
    Uint8List? previewBytes,
    required bool isImage,
  }) async {
    final TextEditingController nameCtrl = TextEditingController(text: titleSuggestion);

    return showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            context.tr('preview_and_name'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EBE2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: isImage && (previewPath != null || previewBytes != null)
                      ? SizedBox(
                    height: 180,
                    child: previewPath != null
                        ? Image.file(File(previewPath), fit: BoxFit.contain)
                        : Image.memory(previewBytes!, fit: BoxFit.contain),
                  )
                      : Column(
                    children: [
                      const Icon(Icons.insert_drive_file, size: 80, color: Color(0xFF7DD3C0)),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('preview_not_available'),
                        style: const TextStyle(color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('document_name'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(
                context.tr('cancel'),
                style: const TextStyle(color: Color(0xFF999999)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7DD3C0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(context.tr('upload')),
            ),
          ],
        );
      },
    );
  }

  void _handleDocumentAction(_DocItem doc, String action) {
    switch (action) {
      case 'view':
        _viewDocument(doc);
        break;
      case 'share':
        _shareDocument(doc);
        break;
      case 'download':
        _downloadDocument(doc);
        break;
      case 'delete':
        _confirmDelete(doc);
        break;
    }
  }

  Future<void> _viewDocument(_DocItem doc) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        doc.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: doc.isImage
                        ? (doc.path != null
                        ? Image.file(File(doc.path!), fit: BoxFit.contain)
                        : doc.bytes != null
                        ? Image.memory(doc.bytes!, fit: BoxFit.contain)
                        : const Icon(Icons.broken_image, size: 80))
                        : Column(
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA8E6CF).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.insert_drive_file,
                            size: 80,
                            color: Color(0xFF7DD3C0),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          doc.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2EBE2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getFileExtension(doc.title).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7DD3C0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(doc.date),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          context.tr('cannot_preview_document'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr('can_download_and_open'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF999999),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _openInExternalApp(doc);
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: Text(context.tr('open_document')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7DD3C0),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openInExternalApp(_DocItem doc) async {
    try {
      if (doc.path != null) {
        final result = await OpenFile.open(doc.path!);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFFFF6B6B),
            ),
          );
        }
      } else if (doc.bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${doc.title}');
        await tempFile.writeAsBytes(doc.bytes!);
        final result = await OpenFile.open(tempFile.path);
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: const Color(0xFFFF6B6B),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${context.tr('could_not_open_file')}: $e"),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
    }
  }

  Future<void> _shareDocument(_DocItem doc) async {
    try {
      if (doc.path != null) {
        await Share.shareXFiles([XFile(doc.path!)], text: doc.title);
      } else if (doc.bytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${doc.title}');
        await tempFile.writeAsBytes(doc.bytes!);
        await Share.shareXFiles([XFile(tempFile.path)], text: doc.title);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${context.tr('could_not_share_file')}: $e"),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
    }
  }

  Future<void> _downloadDocument(_DocItem doc) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('could_not_access_storage')),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
        return;
      }

      final downloadsPath = directory.path.split('Android')[0] + 'Download';
      final downloadsDir = Directory(downloadsPath);

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final file = File('${downloadsDir.path}/${doc.title}');

      if (doc.path != null) {
        await File(doc.path!).copy(file.path);
      } else if (doc.bytes != null) {
        await file.writeAsBytes(doc.bytes!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${context.tr('downloaded_to')} ${file.path}"),
          backgroundColor: const Color(0xFF7DD3C0),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${context.tr('could_not_download_file')}: $e"),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
    }
  }

  Future<void> _confirmDelete(_DocItem doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('delete_document_question'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "${context.tr('delete_document_confirm')} \"${doc.title}\"?",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              context.tr('cancel'),
              style: const TextStyle(color: Color(0xFF999999)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _documents.removeWhere((d) => d.id == doc.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('document_deleted')),
          backgroundColor: const Color(0xFF7DD3C0),
        ),
      );
    }
  }

  String _getFileExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last : 'file';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return "${context.tr('today')} ${context.tr('at')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } else if (dateOnly == yesterday) {
      return "${context.tr('yesterday')} ${context.tr('at')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}

// Category View Page with Filter for X-rays
class _CategoryViewPage extends StatefulWidget {
  final DocumentCategory category;
  final String categoryTitle;
  final Color categoryColor;
  final List<_DocItem> documents;
  final Function(_DocItem, String) onDocumentAction;
  final VoidCallback onAddDocument;

  const _CategoryViewPage({
    required this.category,
    required this.categoryTitle,
    required this.categoryColor,
    required this.documents,
    required this.onDocumentAction,
    required this.onAddDocument,
  });

  @override
  State<_CategoryViewPage> createState() => _CategoryViewPageState();
}

class _CategoryViewPageState extends State<_CategoryViewPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  XrayType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    if (widget.category == DocumentCategory.xrays) {
      _tabController = TabController(length: XrayType.values.length + 1, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<_DocItem> _getFilteredDocuments() {
    if (widget.category != DocumentCategory.xrays || _selectedFilter == null) {
      return widget.documents;
    }
    return widget.documents.where((doc) => doc.xrayType == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDocs = _getFilteredDocuments();

    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.categoryColor.withOpacity(0.8), widget.categoryColor],
            ),
          ),
        ),
        elevation: 0,
        bottom: widget.category == DocumentCategory.xrays && _tabController != null
            ? TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            setState(() {
              if (index == 0) {
                _selectedFilter = null;
              } else {
                _selectedFilter = XrayType.values[index - 1];
              }
            });
          },
          tabs: [
            Tab(text: context.tr('all')),
            ...XrayType.values.map((type) => Tab(text: _getXrayTypeName(type))),
          ],
        )
            : null,
      ),
      body: filteredDocs.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                context.tr('no_documents_in_category'),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredDocs.length,
        itemBuilder: (ctx, i) {
          final doc = filteredDocs[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: doc.isImage && (doc.path != null || doc.bytes != null)
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: doc.path != null
                      ? Image.file(File(doc.path!), fit: BoxFit.cover)
                      : doc.bytes != null
                      ? Image.memory(doc.bytes!, fit: BoxFit.cover)
                      : const Icon(Icons.broken_image),
                ),
              )
                  : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insert_drive_file,
                  color: widget.categoryColor,
                  size: 28,
                ),
              ),
              title: Text(
                doc.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF333333),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(doc.date),
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 14,
                    ),
                  ),
                  if (doc.xrayType != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getXrayTypeName(doc.xrayType!),
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.categoryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Color(0xFF999999)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (action) => widget.onDocumentAction(doc, action),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        const Icon(Icons.visibility, color: Color(0xFF7DD3C0)),
                        const SizedBox(width: 12),
                        Text(context.tr('view')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share, color: Color(0xFF7DD3C0)),
                        const SizedBox(width: 12),
                        Text(context.tr('share')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        const Icon(Icons.download, color: Color(0xFF7DD3C0)),
                        const SizedBox(width: 12),
                        Text(context.tr('download')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Color(0xFFFF6B6B)),
                        const SizedBox(width: 12),
                        Text(
                          context.tr('delete'),
                          style: const TextStyle(color: Color(0xFFFF6B6B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => widget.onDocumentAction(doc, 'view'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAddDocument,
        backgroundColor: widget.categoryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getXrayTypeName(XrayType type) {
    switch (type) {
      case XrayType.panoramic:
        return context.tr('panoramic');
      case XrayType.periapical:
        return context.tr('periapical');
      case XrayType.bitewing:
        return context.tr('bitewing');
      case XrayType.cbct:
        return context.tr('cbct');
      case XrayType.other:
        return context.tr('other');
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}

// Document Item Model
class _DocItem {
  final String id;
  final String title;
  final DateTime date;
  final String? path;
  final Uint8List? bytes;
  final String mimeType;
  final DocumentCategory category;
  final XrayType? xrayType;

  _DocItem({
    required this.id,
    required this.title,
    required this.date,
    this.path,
    this.bytes,
    required this.mimeType,
    required this.category,
    this.xrayType,
  });

  bool get isImage => mimeType.startsWith("image/");
}