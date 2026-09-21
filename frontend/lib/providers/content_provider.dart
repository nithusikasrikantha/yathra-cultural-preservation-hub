import 'package:flutter/material.dart';
import '../models/cultural_content_model.dart';

class ContentProvider with ChangeNotifier {
  List<CulturalContent> _contents = [];
  bool _isLoading = false;

  List<CulturalContent> get contents => _contents;
  bool get isLoading => _isLoading;

  // Sprint 0: Placeholder for content management logic
  void setContents(List<CulturalContent> contents) {
    _contents = contents;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
