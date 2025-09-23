import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

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
      appBar: AppBar(
        title: const Text("Documents & Images"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        bottom: TabBar(
          controller: _tabController,
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
        child: const Icon(Icons.add),
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
              Icon(Icons.insert_drive_file, size: 90, color: Colors.grey),
              SizedBox(height: 18),
              Text(
                "There are currently no documents",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Here you can find all of your uploaded documents",
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (ctx, i) {
        final d = docs[i];
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(d.title),
          subtitle: Text(d.date.toLocal().toString().split(".").first),
          onTap: () => _openDocumentActions(d),
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
              Icon(Icons.image, size: 90, color: Colors.grey),
              SizedBox(height: 18),
              Text(
                "There are currently no images",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Here you can find all of your uploaded images",
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
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
          thumb = const Icon(Icons.broken_image);
        }
        return GestureDetector(
          onTap: () => _openDocumentActions(d),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: thumb,
          ),
        );
      },
    );
  }

  Future<void> _showAddOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text("Upload document"),
              onTap: () {
                Navigator.pop(ctx);
                _addDocumentFromFilePicker();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take photo"),
              onTap: () {
                Navigator.pop(ctx);
                _addDocumentFromCamera();
              },
            ),
          ],
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
          title: const Text("Preview & name"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isImage && (previewPath != null || previewBytes != null))
                  SizedBox(
                    height: 180,
                    child: previewPath != null
                        ? Image.file(File(previewPath), fit: BoxFit.contain)
                        : Image.memory(previewBytes!, fit: BoxFit.contain),
                  )
                else
                  Column(
                    children: const [
                      Icon(Icons.insert_drive_file, size: 80, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Preview not available for this file type"),
                    ],
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Document name"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()),
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
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text("View"),
              onTap: () {
                Navigator.pop(ctx);
                _viewDocument(doc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete"),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _documents.removeWhere((d) => d.id == doc.id);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewDocument(_DocItem doc) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (doc.isImage)
                  (doc.path != null
                      ? Image.file(File(doc.path!), fit: BoxFit.contain)
                      : Image.memory(doc.bytes!, fit: BoxFit.contain))
                else
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Icon(Icons.insert_drive_file, size: 80),
                  ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(doc.title),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Close"),
                )
              ],
            ),
          ),
        ),
      ),
    );
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
