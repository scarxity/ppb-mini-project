import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/category.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection('users').doc(_uid).collection('categories');

  Stream<List<Category>> watchAll() {
    return _ref.orderBy('createdAt', descending: true).snapshots().map(
      (snap) => snap.docs.map(Category.fromDoc).toList(),
    );
  }

  Future<Category?> getById(String id) async {
    final doc = await _ref.doc(id).get();
    if (!doc.exists) return null;
    return Category.fromDoc(doc);
  }

  Future<String> create({required String name, required String description}) async {
    final docRef = await _ref.add({
      'name': name,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> update({
    required String id,
    required String name,
    required String description,
  }) async {
    await _ref.doc(id).update({
      'name': name,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> countCollectionsUsingCategory(String categoryId) async {
    final snap = await _db
        .collection('users')
        .doc(_uid)
        .collection('collections')
        .where('categoryId', isEqualTo: categoryId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<void> delete(String id) async {
    await _ref.doc(id).delete();
  }
}
