import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/collection_item.dart';
import '../../services/category_service.dart';
import '../../services/collection_service.dart';
import 'collection_detail.dart';
import 'collection_form.dart';

class CollectionsTab extends StatefulWidget {
  const CollectionsTab({super.key});

  @override
  State<CollectionsTab> createState() => _CollectionsTabState();
}

class _CollectionsTabState extends State<CollectionsTab> {
  final _collections = CollectionService();
  final _categories = CategoryService();
  String? _filterCategoryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _CategoryFilterBar(
            categoryService: _categories,
            selectedId: _filterCategoryId,
            onChanged: (id) => setState(() => _filterCategoryId = id),
          ),
          Expanded(
            child: StreamBuilder<List<CollectionItem>>(
              stream: _collections.watchAll(categoryId: _filterCategoryId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No collections yet. Tap + to add one.'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: _Thumbnail(path: item.imagePath),
                        title: Text(item.name),
                        subtitle: item.description.isEmpty
                            ? null
                            : Text(
                                item.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CollectionDetail(itemId: item.id),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CollectionForm()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? path;
  const _Thumbnail({required this.path});

  @override
  Widget build(BuildContext context) {
    final file = (path != null && path!.isNotEmpty) ? File(path!) : null;
    if (file == null || !file.existsSync()) {
      return const CircleAvatar(child: Icon(Icons.image_not_supported));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final CategoryService categoryService;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _CategoryFilterBar({
    required this.categoryService,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Category>>(
      stream: categoryService.watchAll(),
      builder: (context, snap) {
        final cats = snap.data ?? const <Category>[];
        return SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: selectedId == null,
                onSelected: (_) => onChanged(null),
              ),
              const SizedBox(width: 8),
              for (final c in cats) ...[
                ChoiceChip(
                  label: Text(c.name),
                  selected: selectedId == c.id,
                  onSelected: (_) => onChanged(c.id),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}
