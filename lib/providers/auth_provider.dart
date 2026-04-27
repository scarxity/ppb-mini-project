import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  User? _user;
  bool _initialized = false;

  AppAuthProvider() {
    _service.authStateChanges().listen((u) {
      _user = u;
      _initialized = true;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get initialized => _initialized;

  Future<void> signIn(String email, String password) async {
    await _service.signIn(email, password);
  }

  Future<void> register(String email, String password) async {
    await _service.register(email, password);
  }

  Future<void> signOut() => _service.signOut();
}
