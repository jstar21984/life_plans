import 'package:flutter/foundation.dart';
import '../models/category.dart' as models;
import '../services/database_service.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<models.Category> _categories = [];
  bool _isLoading = false;

  List<models.Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _db.getCategories();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(models.Category category) async {
    await _db.insertCategory(category);
    _categories.add(category);
    notifyListeners();
  }

  Future<void> updateCategory(models.Category category) async {
    await _db.updateCategory(category);
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    await _db.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  models.Category? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
