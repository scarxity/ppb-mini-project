import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/category.dart';
import '../../models/collection_item.dart';
import '../../services/category_service.dart';
import '../../services/collection_service.dart';
import '../../services/notification_service.dart';

class CollectionForm extends StatefulWidget {
  final CollectionItem? existing;
  const CollectionForm({super.key, this.existing});

  @override
  State<CollectionForm> createState() => _CollectionFormState();
}

class _CollectionFormState extends State<CollectionForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _collections = CollectionService();
  final _categories = CategoryService();
  final _picker = ImagePicker();

  String? _categoryId;
  File? _newImage;
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _name.text = widget.existing!.name;
      _description.text = widget.existing!.description;
      _categoryId = widget.existing!.categoryId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1280,
    );
    if (picked != null) {
      setState(() => _newImage = File(picked.path));
    }
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a category')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      if (_isEdit) {
        await _collections.update(
          id: widget.existing!.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          categoryId: _categoryId!,
          newImage: _newImage,
          existingImagePath: widget.existing!.imagePath,
        );
        await NotificationService.instance.showCrudToast(
          'Collection updated',
          '"${_name.text.trim()}" was updated.',
        );
      } else {
        await _collections.create(
          name: _name.text.trim(),
          description: _description.text.trim(),
          categoryId: _categoryId!,
          image: _newImage,
        );
        await NotificationService.instance.showCrudToast(
          'Collection created',
          '"${_name.text.trim()}" was added.',
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit collection' : 'New collection'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ImagePreview(
                  newImage: _newImage,
                  existingPath: widget.existing?.imagePath,
                  onTap: _showImageSourceSheet,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Category>>(
                  stream: _categories.watchAll(),
                  builder: (context, snap) {
                    final cats = snap.data ?? const <Category>[];
                    return DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final c in cats)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Pick a category' : null,
                    );
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEdit ? 'Save changes' : 'Create'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final File? newImage;
  final String? existingPath;
  final VoidCallback onTap;

  const _ImagePreview({
    required this.newImage,
    required this.existingPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (newImage != null) {
      child = Image.file(newImage!, fit: BoxFit.cover);
    } else if (existingPath != null &&
        existingPath!.isNotEmpty &&
        File(existingPath!).existsSync()) {
      child = Image.file(File(existingPath!), fit: BoxFit.cover);
    } else {
      child = const ColoredBox(
        color: Color(0xFFEEEEEE),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 48),
              SizedBox(height: 8),
              Text('Tap to add a photo'),
            ],
          ),
        ),
      );
    }
    return InkWell(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      ),
    );
  }
}
