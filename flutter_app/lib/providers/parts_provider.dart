import 'package:flutter/material.dart';
import '../models/spare_part.dart';
import '../services/firebase_service.dart';

class PartsProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  String _selectedCategory = 'All';
  String _selectedBrand = 'All';
  List<String> _wishlistPartIds = [];
  bool _isLoading = false;

  String get selectedCategory => _selectedCategory;
  String get selectedBrand => _selectedBrand;
  List<String> get wishlistPartIds => _wishlistPartIds;
  List<String> get favorites => _wishlistPartIds;
  int get favoritesCount => _wishlistPartIds.length;
  bool get isLoading => _isLoading;

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void selectBrand(String brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  void toggleWishlist(String partId) {
    if (_wishlistPartIds.contains(partId)) {
      _wishlistPartIds.remove(partId);
    } else {
      _wishlistPartIds.add(partId);
    }
    notifyListeners();
  }

  bool isFavorite(String partId) => _wishlistPartIds.contains(partId);

  Future<void> fetchParts() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 300));
    _isLoading = false;
    notifyListeners();
  }

  Stream<List<SparePart>> get partsStream {
    return _firebaseService.getSparePartsStream(
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      brand: _selectedBrand == 'All' ? null : _selectedBrand,
    );
  }
}
