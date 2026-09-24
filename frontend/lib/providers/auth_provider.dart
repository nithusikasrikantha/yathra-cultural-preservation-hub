import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  // Sprint 0: Placeholder for authentication logic
  void setUser(User? user) {
    _user = user;
    _isAuthenticated = user != null;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
