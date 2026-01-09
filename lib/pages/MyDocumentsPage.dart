import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'HomePage.dart';

class MyDocumentsPage extends StatefulWidget {
  const MyDocumentsPage({Key? key}) : super(key: key);

  @override
  State<MyDocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<MyDocumentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<_DocItem> _documents = [];

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

  bool get docsExist => _documents.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: const Text(
          "My Documents",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Documents"),
            Tab(text: "Images"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDocumentsTab(),
          _buildImagesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: const Color(0xFF7DD3C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    final docs = _documents.where((d) => !d.isImage).toList();
    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.insert_drive_file, size: 90, color: Color(0xFFBBBBBB)),
              SizedBox(height: 18),
              Text(
                "No documents yet",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Tap + to upload your first document",
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (ctx, i) {
        final d = docs[i];
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
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFA8E6CF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.insert_drive_file,
                color: Color(0xFF7DD3C0),
                size: 28,
              ),
            ),
            title: Text(
              d.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
            subtitle: Text(
              _formatDate(d.date),
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF999999),
            ),
            onTap: () => _openDocumentActions(d),
          ),
        );
      },
    );
  }

  Widget _buildImagesTab() {
    final images = _documents.where((d) => d.isImage).toList();
    if (images.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.image, size: 90, color: Color(0xFFBBBBBB)),
              SizedBox(height: 18),
              Text(
                "No images yet",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Tap + to add your first image",
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: images.length,
      itemBuilder: (ctx, i) {
        final d = images[i];
        Widget thumb;
        if (d.path != null) {
          thumb = Image.file(File(d.path!), fit: BoxFit.cover);
        } else if (d.bytes != null) {
          thumb = Image.memory(d.bytes!, fit: BoxFit.cover);
        } else {
          thumb = const Icon(Icons.broken_image, color: Color(0xFF999999));
        }
        return GestureDetector(
          onTap: () => _openDocumentActions(d),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: thumb,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddOptions() async {
    showModalBottomSheet(
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
                  child: const Icon(
                    Icons.insert_drive_file,
                    color: Color(0xFF7DD3C0),
                  ),
                ),
                title: const Text(
                  "Upload document",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _addDocumentFromFilePicker();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA8E6CF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF7DD3C0),
                  ),
                ),
                title: const Text(
                  "Take photo",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _addDocumentFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addDocumentFromFilePicker() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      final name = f.name;
      final bytes = f.bytes;
      final path = f.path;
      final mimeType = lookupMimeType(path ?? name) ?? "application/octet-stream";
      final isImage = mimeType.startsWith("image/");

      final newName = await _showPreviewAndAskUpload(
        titleSuggestion: name,
        previewPath: path,
        previewBytes: bytes,
        isImage: isImage,
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
          ),
        );
      });
    }
  }

  Future<void> _addDocumentFromCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      final path = picked.path;
      final bytes = await picked.readAsBytes();
      final mimeType = lookupMimeType(path) ?? "image/jpeg";

      final newName = await _showPreviewAndAskUpload(
        titleSuggestion: "photo.jpg",
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
          ),
        );
      });
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
          title: const Text(
            "Preview & Name",
            style: TextStyle(fontWeight: FontWeight.bold),
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
                          children: const [
                            Icon(Icons.insert_drive_file, size: 80, color: Color(0xFF7DD3C0)),
                            SizedBox(height: 8),
                            Text(
                              "Preview not available",
                              style: TextStyle(color: Color(0xFF999999)),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Document name",
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
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFF999999)),
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
              child: const Text("Upload"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openDocumentActions(_DocItem doc) async {
    showModalBottomSheet(
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
                  child: const Icon(
                    Icons.visibility,
                    color: Color(0xFF7DD3C0),
                  ),
                ),
                title: const Text(
                  "View",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _viewDocument(doc);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA8E6CF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.share,
                    color: Color(0xFF7DD3C0),
                  ),
                ),
                title: const Text(
                  "Share",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareDocument(doc);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA8E6CF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: Color(0xFF7DD3C0),
                  ),
                ),
                title: const Text(
                  "Download",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _downloadDocument(doc);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8B94).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                title: const Text(
                  "Delete",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(doc);
                },
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
        // Save bytes to temp file and open
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
          content: Text("Could not open file: $e"),
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
        // Save bytes to temp file and share
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${doc.title}');
        await tempFile.writeAsBytes(doc.bytes!);
        await Share.shareXFiles([XFile(tempFile.path)], text: doc.title);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not share file: $e"),
          backgroundColor: const Color(0xFFFF6B6B),
        ),
      );
    }
  }

  Future<void> _downloadDocument(_DocItem doc) async {
    try {
      // For mobile, "download" typically means save to Downloads folder
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not access storage"),
            backgroundColor: Color(0xFFFF6B6B),
          ),
        );
        return;
      }

      // Navigate to Downloads folder (parent directories)
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
          content: Text("Downloaded to ${file.path}"),
          backgroundColor: const Color(0xFF7DD3C0),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not download file: $e"),
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
        title: const Text(
          "Delete Document?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete \"${doc.title}\"?",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF999999)),
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
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _documents.removeWhere((d) => d.id == doc.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Document deleted"),
          backgroundColor: Color(0xFF7DD3C0),
        ),
      );
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
              // Header
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
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: doc.isImage
                        ? (doc.path != null
                            ? Image.file(File(doc.path!), fit: BoxFit.contain)
                            : Image.memory(doc.bytes!, fit: BoxFit.contain))
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
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
                              const Text(
                                "This document cannot be previewed in the app.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "You can download and open it with your device's default app.",
                                style: TextStyle(
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
                                label: const Text("Open Document"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7DD3C0),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
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
      return "Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } else if (dateOnly == yesterday) {
      return "Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}

class _DocItem {
  final String id;
  final String title;
  final DateTime date;
  final String? path;
  final Uint8List? bytes;
  final String mimeType;

  _DocItem({
    required this.id,
    required this.title,
    required this.date,
    this.path,
    this.bytes,
    required this.mimeType,
  });

  bool get isImage => mimeType.startsWith("image/");
}