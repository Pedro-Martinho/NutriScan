import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';
import 'dart:async';

class ProductProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Product> _scannedProducts = [];
  List<Product> _favorites = [];
  bool _isLoading = false;
  Timer? _saveDebouncer;
  
  ProductProvider(this._prefs) {
    _loadData();
  }

  bool get isLoading => _isLoading;
  List<Product> get scannedProducts => List.unmodifiable(_scannedProducts);
  List<Product> get favorites {
    if (_favorites.isEmpty) return const [];
    final sorted = List<Product>.from(_favorites);
    sorted.sort((a, b) => 
    (b.favoriteTimestamp ?? DateTime(0)).compareTo(a.favoriteTimestamp ?? DateTime(0))
    );
    return List.unmodifiable(sorted);
  }

  Future<void> _loadData() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      if (_firebaseService.currentUserId != null) {
        // User is logged in, load from Firebase
        final firebaseData = await _firebaseService.getUserData();
        if (firebaseData != null) {
          _scannedProducts = _parseProducts(firebaseData['scannedProducts'] ?? []);
          _favorites = _parseProducts(firebaseData['favorites'] ?? []);
        }
      } else {
        // For guest users, clear any existing data
        _scannedProducts = [];
        _favorites = [];
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Product> _parseProducts(List<dynamic> data) {
    return data.map((item) => Product.fromJson(item)).toList();
  }

  Future<void> _saveData() async {
    // Skip saving data for guest users
    if (_firebaseService.currentUserId == null) {
      return;
    }

    _saveDebouncer?.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 500), () async {
      try {
        // Save to Firebase for logged-in user
        await _firebaseService.saveUserData({
          'scannedProducts': _scannedProducts.map((p) => p.toJson()).toList(),
          'favorites': _favorites.map((p) => p.toJson()).toList(),
        });
      } catch (e) {
        print('Error saving data: $e');
      }
    });
  }

  Future<void> addToScanned(Product product) async {
    // Skip saving history for guest users
    if (_firebaseService.currentUserId == null) {
      return;
    }

    if (!_scannedProducts.any((p) => p.barcode == product.barcode)) {
      _scannedProducts.insert(0, product);
      notifyListeners();
      // Save to Firebase for logged-in user
      await _firebaseService.addToHistory(product);
      await _saveData();
    }
  }

  Future<void> addToFavorites(Product product) async {
    if (!_favorites.any((p) => p.barcode == product.barcode)) {
      final productWithTimestamp = product.copyWith(favoriteTimestamp: DateTime.now());
      _favorites.add(productWithTimestamp);
      notifyListeners();
      if (_firebaseService.currentUserId != null) {
        // Save to Firebase for logged-in user
        await _firebaseService.addToFavorites(productWithTimestamp);
      }
      await _saveData();
    }
  }

  Future<void> removeFromFavorites(String barcode) async {
    final index = _favorites.indexWhere((p) => p.barcode == barcode);
    if (index != -1) {
      _favorites.removeAt(index);
      notifyListeners();
    if (_firebaseService.currentUserId != null) {
      // Remove from Firebase for logged-in user
        await _firebaseService.removeFromFavorites(barcode);
    }
      await _saveData();
  }
  }

  bool isFavorite(String barcode) {
    return _favorites.any((p) => p.barcode == barcode);
  }

  Future<void> clearHistory() async {
    _scannedProducts.clear();
    notifyListeners();
    if (_firebaseService.currentUserId != null) {
      // Clear Firebase history for logged-in user
      await _firebaseService.clearHistory();
    }
    await _saveData();
  }

  @override
  void dispose() {
    _saveDebouncer?.cancel();
    super.dispose();
  }

  // Call this when user signs in to load their data from Firebase
  Future<void> loadUserData() async {
    try {
      print('Loading user data from Firebase...'); // Debug log
      // Clear any existing local data first
      await clearLocalData();
      
      final firebaseData = await _firebaseService.getUserData();
      if (firebaseData != null) {
        print('Found user data in Firebase: $firebaseData'); // Debug log
        _scannedProducts = _parseProducts(firebaseData['scannedProducts'] ?? []);
        _favorites = _parseProducts(firebaseData['favorites'] ?? []);
        notifyListeners();
      } else {
        print('No user data found in Firebase'); // Debug log
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Call this when user signs out to clear all data
  Future<void> clearUserData() async {
    try {
      print('Clearing all data...'); // Debug log
      await clearLocalData();
      _scannedProducts.clear();
      _favorites.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  // Helper method to clear local storage data
  Future<void> clearLocalData() async {
    await _prefs.remove('scannedProducts');
    await _prefs.remove('guest_scannedProducts');
    await _prefs.remove('favorites');
    await _prefs.remove('guest_favorites');
  }

  // Public method to reload products
  Future<void> loadProducts() async {
    await _loadData();
  }
} 