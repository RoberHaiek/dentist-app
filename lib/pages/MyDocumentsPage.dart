import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../services/LocalizationProvider.dart';
import 'HomePage.dart';

enum ImageType {
  photo,
  xray,
}

class MyDocumentsPage extends StatefulWidget {
  const MyDocumentsPage({Key? key}) : super(key: key);

  @override
  State<MyDocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<MyDocumentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<_DocItem> _documents = [];

  // Filter state for images tab
  String selectedImageFilter = 'all'; // 'all', 'xray', 'photo'

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
        title: Text(
          context.tr('my_documents'),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: context.tr('documents')),
            Tab(text: context.tr('images')),
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
            children: [
              const Icon(Icons.insert_drive_file, size: 90, color: Color(0xFFBBBBBB)),
              const SizedBox(height: 18),
              Text(
                context.tr('no_documents_yet'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('tap_to_upload_document'),
                style: const TextStyle(
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
    // Get all images
    final allImages = _documents.where((d) => d.isImage).toList();

    // Filter images based on selected filter
    final List<_DocItem> filteredImages;
    if (selectedImageFilter == 'xray') {
      filteredImages = allImages.where((d) => d.imageType == ImageType.xray).toList();
    } else if (selectedImageFilter == 'photo') {
      filteredImages = allImages.where((d) => d.imageType == ImageType.photo).toList();
    } else {
      filteredImages = allImages;
    }

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: context.tr('all'),
                  value: 'all',
                  count: allImages.length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: context.tr('xrays'),
                  value: 'xray',
                  count: allImages.where((d) => d.imageType == ImageType.xray).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: context.tr('photos'),
                  value: 'photo',
                  count: allImages.where((d) => d.imageType == ImageType.photo).length,
                ),
              ],
            ),
          ),
        ),

        // Images grid
        Expanded(
          child: filteredImages.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image, size: 90, color: Color(0xFFBBBBBB)),
                  const SizedBox(height: 18),
                  Text(
                    selectedImageFilter == 'all'
                        ? context.tr('no_images_yet')
                        : selectedImageFilter == 'xray'
                        ? context.tr('no_xrays_yet')
                        : context.tr('no_photos_yet'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('tap_to_add_image'),
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
              : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: filteredImages.length,
            itemBuilder: (ctx, i) {
              final d = filteredImages[i];
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
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: thumb,
                      ),
                      // Badge to show if it's an X-ray
                      if (d.imageType == ImageType.xray)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              context.tr('xray'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required int count,
  }) {
    final isSelected = selectedImageFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedImageFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7DD3C0) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF7DD3C0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF666666),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFFA8E6CF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF7DD3C0),
                ),
              ),
            ),
          ],
        ),
      ),
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
                title: Text(
                  context.tr('upload_document'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                title: Text(
                  context.tr('take_photo'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
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

      final uploadData = await _showPreviewAndAskUpload(
        titleSuggestion: name,
        previewPath: path,
        previewBytes: bytes,
        isImage: isImage,
      );

      if (uploadData == null || uploadData['name'] == null || uploadData['name'].isEmpty) return;

      setState(() {
        _documents.insert(
          0,
          _DocItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: uploadData['name'],
            date: DateTime.now(),
            path: path,
            bytes: bytes,
            mimeType: mimeType,
            imageType: uploadData['imageType'],
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

      final uploadData = await _showPreviewAndAskUpload(
        titleSuggestion: "photo.jpg",
        previewPath: path,
        previewBytes: bytes,
        isImage: true,
      );

      if (uploadData == null || uploadData['name'] == null || uploadData['name'].isEmpty) return;

      setState(() {
        _documents.insert(
          0,
          _DocItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: uploadData['name'],
            date: DateTime.now(),
            path: path,
            bytes: bytes,
            mimeType: mimeType,
            imageType: uploadData['imageType'],
          ),
        );
      });
    }
  }

  Future<Map<String, dynamic>?> _showPreviewAndAskUpload({
    required String titleSuggestion,
    String? previewPath,
    Uint8List? previewBytes,
    required bool isImage,
  }) async {
    final TextEditingController nameCtrl = TextEditingController(text: titleSuggestion);
    ImageType? selectedImageType = isImage ? ImageType.photo : null;

    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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

                    // Image type selection (only for images)
                    if (isImage) ...[
                      const SizedBox(height: 16),
                      Text(
                        context.tr('is_this_xray'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedImageType = ImageType.photo;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selectedImageType == ImageType.photo
                                      ? const Color(0xFFA8E6CF).withOpacity(0.3)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedImageType == ImageType.photo
                                        ? const Color(0xFF7DD3C0)
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.photo_camera,
                                      color: selectedImageType == ImageType.photo
                                          ? const Color(0xFF7DD3C0)
                                          : Colors.grey.shade600,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.tr('photo'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedImageType == ImageType.photo
                                            ? const Color(0xFF7DD3C0)
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedImageType = ImageType.xray;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selectedImageType == ImageType.xray
                                      ? const Color(0xFFA8E6CF).withOpacity(0.3)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedImageType == ImageType.xray
                                        ? const Color(0xFF7DD3C0)
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.local_hospital,
                                      color: selectedImageType == ImageType.xray
                                          ? const Color(0xFF7DD3C0)
                                          : Colors.grey.shade600,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.tr('xray'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: selectedImageType == ImageType.xray
                                            ? const Color(0xFF7DD3C0)
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                  onPressed: () => Navigator.of(ctx).pop({
                    'name': nameCtrl.text.trim(),
                    'imageType': selectedImageType,
                  }),
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
                title: Text(
                  context.tr('view'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                title: Text(
                  context.tr('share'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                title: Text(
                  context.tr('download'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
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
                title: Text(
                  context.tr('delete'),
                  style: const TextStyle(
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
        // Save bytes to temp file and share
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
      // For mobile, "download" typically means save to Downloads folder
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (doc.isImage && doc.imageType == ImageType.xray)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  context.tr('xray'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
      return "${context.tr('today')} ${context.tr('at')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } else if (dateOnly == yesterday) {
      return "${context.tr('yesterday')} ${context.tr('at')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
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
  final ImageType? imageType; // null for documents, Photo/Xray for images

  _DocItem({
    required this.id,
    required this.title,
    required this.date,
    this.path,
    this.bytes,
    required this.mimeType,
    this.imageType,
  });

  bool get isImage => mimeType.startsWith("image/");
}