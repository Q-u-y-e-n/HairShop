import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  User? get user => _user;

  void setUser(Map<String, dynamic> data) {
    _user = User.fromJson(data);
    notifyListeners();
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
