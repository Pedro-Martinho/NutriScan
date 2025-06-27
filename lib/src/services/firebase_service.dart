import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class FirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseService() : _firestore = FirebaseFirestore.instance {
    // Enable offline persistence for mobile
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Settings methods
  Future<Map<String, dynamic>?> getUserSettings() async {
    if (currentUserId == null) {
      print('getUserSettings: No user logged in'); // Debug log
      return null;
    }

    try {
      print('getUserSettings: Fetching settings for user $currentUserId'); // Debug log
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('settings')
          .doc('user_settings')
          .get();

      if (!doc.exists) {
        print('getUserSettings: No settings document exists, creating default settings'); // Debug log
        final defaultSettings = {
          'isDarkMode': false,
          'notificationsEnabled': true,
          'language': 'en_US',
          'dietaryPreferences': <String>[],
        };
        
        // Save default settings for new user
        await saveUserSettings(defaultSettings);
        return defaultSettings;
      }
      
      final data = doc.data();
      if (data == null) {
        print('getUserSettings: Settings document exists but data is null'); // Debug log
        return null;
      }
      
      final settings = {
        'isDarkMode': data['isDarkMode'] as bool? ?? false,
        'notificationsEnabled': data['notificationsEnabled'] as bool? ?? true,
        'language': data['language'] as String? ?? 'en_US',
        'dietaryPreferences': (data['dietaryPreferences'] as List?)?.cast<String>() ?? <String>[],
      };
      print('getUserSettings: Successfully retrieved settings: $settings'); // Debug log
      return settings;
    } catch (e) {
      print('Error getting user settings: $e');
      return null;
    }
  }

  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    if (currentUserId == null) {
      print('saveUserSettings: No user logged in'); // Debug log
      return;
    }

    try {
      print('saveUserSettings: Saving settings for user $currentUserId: $settings'); // Debug log
      
      // Ensure we have all required fields
      final completeSettings = {
        'isDarkMode': settings['isDarkMode'] ?? false,
        'notificationsEnabled': settings['notificationsEnabled'] ?? true,
        'language': settings['language'] ?? 'en_US',
        'dietaryPreferences': settings['dietaryPreferences'] ?? <String>[],
      };
      
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('settings')
          .doc('user_settings')
          .set(completeSettings); // Remove merge option to ensure complete settings
      
      print('Settings saved successfully for user: $currentUserId'); // Debug log
    } catch (e) {
      print('Error saving user settings: $e');
      rethrow;
    }
  }

  // Scanned Products History
  Future<void> addToHistory(Product product) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('history')
        .add({
          ...product.toJson(),
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<List<Product>> getHistory() async {
    if (currentUserId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Product.fromJson(doc.data()))
        .toList();
  }

  Future<void> clearHistory() async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('history')
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Favorite Products
  Future<void> addToFavorites(Product product) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc(product.barcode)
        .set(product.toJson());
  }

  Future<void> removeFromFavorites(String barcode) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc(barcode)
        .delete();
  }

  Future<List<Product>> getFavorites() async {
    if (currentUserId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .get();

    return snapshot.docs
        .map((doc) => Product.fromJson(doc.data()))
        .toList();
  }

  Future<bool> isFavorite(String barcode) async {
    if (currentUserId == null) return false;

    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .doc(barcode)
        .get();

    return doc.exists;
  }

  // Product data methods
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUserId == null) return null;

    try {
      final historyDocs = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      final favoritesDocs = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .get();

      return {
        'scannedProducts': historyDocs.docs.map((doc) => doc.data()).toList(),
        'favorites': favoritesDocs.docs.map((doc) => doc.data()).toList(),
      };
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> saveUserData(Map<String, dynamic> data) async {
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(currentUserId);

      // Clear existing collections
      final historyDocs = await userRef.collection('history').get();
      for (var doc in historyDocs.docs) {
        batch.delete(doc.reference);
      }

      final favoritesDocs = await userRef.collection('favorites').get();
      for (var doc in favoritesDocs.docs) {
        batch.delete(doc.reference);
      }

      // Add new data
      for (var product in data['scannedProducts'] ?? []) {
        batch.set(
          userRef.collection('history').doc(),
          {...product, 'timestamp': FieldValue.serverTimestamp()},
        );
      }

      for (var product in data['favorites'] ?? []) {
        batch.set(
          userRef.collection('favorites').doc(product['barcode']),
          product,
        );
      }

      await batch.commit();
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  // Clear all user data (useful when signing out)
  Future<void> clearUserData() async {
    if (currentUserId == null) return;

    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(currentUserId);

      // Delete all subcollections
      final collections = ['history', 'favorites'];
      for (var collectionName in collections) {
        final querySnapshot = await userRef.collection(collectionName).get();
        for (var doc in querySnapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      // Clear settings
      await userRef.collection('settings').doc('user_settings').delete();

      await batch.commit();
    } catch (e) {
      print('Error clearing user data: $e');
      rethrow;
    }
  }

  // Update a product in the database
  Future<void> updateProduct(Product product) async {
    if (currentUserId == null) return;

    try {
      print('Updating product ${product.barcode} in database'); // Debug log
      
      // Update in history
      final historyDocs = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('history')
          .where('barcode', isEqualTo: product.barcode)
          .get();
      
      for (var doc in historyDocs.docs) {
        await doc.reference.update(product.toJson());
      }
      
      // Update in favorites if exists
      final favoriteDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(product.barcode)
          .get();
      
      if (favoriteDoc.exists) {
        await favoriteDoc.reference.update(product.toJson());
      }
      
      print('Product updated successfully in database'); // Debug log
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }
} 