import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/category.dart';
import '../../models/collection_item.dart';
import '../../services/category_service.dart';
import '../../services/collection_service.dart';
import '../../services/notification_service.dart';
import 'collection_form.dart';

class CollectionDetail extends StatefulWidget {
  final String itemId;
  const CollectionDetail({super.key, required this.itemId});

  @override
  State<CollectionDetail> createState() => _CollectionDetailState();
}

class _CollectionDetailState extends State<CollectionDetail> {
  final _service = CollectionService();
  final _categories = CategoryService();
  CollectionItem? _item;
  Category? _category;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final item = await _service.getById(widget.itemId);
    Category? cat;
    if (item != null) {
      cat = await _categories.getById(item.categoryId);
    }
    if (!mounted) return;
    setState(() {
      _item = item;
      _category = cat;
      _loading = false;
    });
  }

  Future<void> _delete() async {
    final item = _item;
    if (item == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete collection?'),
        content: Text('Delete "${item.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _service.delete(item);
    await NotificationService.instance.showCrudToast(
      'Collection deleted',
      '"${item.name}" was removed.',
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final item = _item;
    if (item == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Not found')),
      );
    }

    final dateFmt = DateFormat.yMMMd().add_jm();
    final hasImage = item.imagePath != null &&
        item.imagePath!.isNotEmpty &&
        File(item.imagePath!).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CollectionForm(existing: item),
                ),
              );
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.file(
                    File(item.imagePath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            if (_category != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.label_outline, size: 16),
                  const SizedBox(width: 4),
                  Text(_category!.name),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (item.description.isNotEmpty)
              Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
            const Divider(height: 32),
            Text(
              'Created ${dateFmt.format(item.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Updated ${dateFmt.format(item.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
