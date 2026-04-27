import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionItem {
  final String id;
  final String name;
  final String description;
  final String categoryId;

  /// Absolute path to the image on the local device filesystem.
  /// May be null when no image was captured.
  final String? imagePath;

  final DateTime createdAt;
  final DateTime updatedAt;

  CollectionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollectionItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CollectionItem(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      categoryId: (data['categoryId'] ?? '') as String,
      imagePath: data['imagePath'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toCreateMap() => {
    'name': name,
    'description': description,
    'categoryId': categoryId,
    'imagePath': imagePath,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Map<String, dynamic> toUpdateMap() => {
    'name': name,
    'description': description,
    'categoryId': categoryId,
    'imagePath': imagePath,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
