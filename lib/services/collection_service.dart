import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/collection_item.dart';
import 'storage_service.dart';

class CollectionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StorageService _storage = StorageService();

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection('users').doc(_uid).collection('collections');

  Stream<List<CollectionItem>> watchAll({String? categoryId}) {
    Query<Map<String, dynamic>> q = _ref.orderBy('createdAt', descending: true);
    if (categoryId != null) {
      q = _ref.where('categoryId', isEqualTo: categoryId);
    }
    return q.snapshots().map(
      (snap) => snap.docs.map(CollectionItem.fromDoc).toList(),
    );
  }

  Future<CollectionItem?> getById(String id) async {
    final doc = await _ref.doc(id).get();
    if (!doc.exists) return null;
    return CollectionItem.fromDoc(doc);
  }

  Future<String> create({
    required String name,
    required String description,
    required String categoryId,
    File? image,
  }) async {
    final docRef = _ref.doc();
    String? path;
    if (image != null) {
      path = await _storage.saveCollectionImage(
        collectionId: docRef.id,
        source: image,
      );
    }
    await docRef.set({
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'imagePath': path,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> update({
    required String id,
    required String name,
    required String description,
    required String categoryId,
    File? newImage,
    required String? existingImagePath,
  }) async {
    String? path = existingImagePath;

    if (newImage != null) {
      if (existingImagePath != null && existingImagePath.isNotEmpty) {
        await _storage.deleteByPath(existingImagePath);
      }
      path = await _storage.saveCollectionImage(
        collectionId: id,
        source: newImage,
      );
    }

    await _ref.doc(id).update({
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'imagePath': path,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(CollectionItem item) async {
    if (item.imagePath != null && item.imagePath!.isNotEmpty) {
      await _storage.deleteByPath(item.imagePath!);
    }
    await _ref.doc(item.id).delete();
  }
}
