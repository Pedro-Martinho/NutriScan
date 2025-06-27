import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  Future<Product> getProductByBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/product/$barcode?fields=code,product_name,brands,image_url,nutriscore_grade,ingredients_text,nutriments,allergens_tags,ingredients_analysis_tags,additives_tags,additives_original_tags,additives_debug_tags,serving_size,categories_tags'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] != 1 || data['product'] == null) {
          throw Exception('Product not found');
        }

        final product = data['product'] as Map<String, dynamic>;
        
        // Check if it's a food product by examining categories
        final categories = (product['categories_tags'] as List<dynamic>?)?.cast<String>() ?? [];
        final isFoodProduct = categories.any((category) => 
          category.contains('food') || 
          category.contains('beverage') || 
          category.contains('meal') ||
          category.contains('snack') ||
          category.contains('drink'));
          
        if (!isFoodProduct) {
          throw Exception('This barcode belongs to a non-food product. Please scan food items only.');
        }

        return Product(
          barcode: barcode,
          name: product['product_name'] ?? 'Unknown',
          brand: product['brands'],
          imageUrl: product['image_url'],
          nutriscore: (product['nutriscore_grade'] as String?)?.toUpperCase() ?? 'N/A',
          ingredients: product['ingredients_text'] ?? '',
          nutritionalValues: _extractNutritionalValues(product['nutriments']),
          allergens: _extractAllergens(product),
          additives: _extractAdditives(product),
          isVegan: _isVegan(product),
          isVegetarian: _isVegetarian(product),
          isPalmOilFree: _isPalmOilFree(product),
          servingSize: product['serving_size']?.toString(),
        );
      }
      throw Exception('Failed to load product');
    } catch (e) {
      print('Error fetching product: $e');
      if (e.toString().contains('non-food product')) {
        rethrow; // Keep the custom error message
      }
      throw Exception('Unable to load product information. Please try again.');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      // Clean and prepare the search query
      final cleanQuery = query.trim();
      final encodedQuery = Uri.encodeComponent(cleanQuery);
      
      // Search with better language and region filtering
      final response = await http.get(
        Uri.parse('$_baseUrl/search?search_terms=$encodedQuery&fields=code,product_name,brands,image_url,nutriscore_grade,ingredients_text,nutriments,allergens_tags,ingredients_analysis_tags,lang,product_name_en,countries_tags&page_size=50&sort_by=unique_scans_n&lc=en&countries=en:united-kingdom,en:united-states,en:canada,en:ireland,en:australia&json=true'),
      );

      final data = jsonDecode(response.body);
      final products = data['products'] as List<dynamic>? ?? [];
      
      print('Found ${products.length} products before filtering'); // Debug log

      return products.where((product) {
        if (product == null) return false;
        final productMap = product as Map<String, dynamic>;
        
        // Get product name (prefer English name if available)
        final productNameEn = (productMap['product_name_en'] as String?)?.toLowerCase();
        final productName = (productMap['product_name'] as String?)?.toLowerCase();
        final brand = (productMap['brands'] as String?)?.toLowerCase();
        final searchTerms = cleanQuery.toLowerCase();
        
        // Check if the product has valid data
        if (productMap['code'] == null || (productName == null && productNameEn == null)) {
          return false;
        }

        // Check if product name or brand contains search terms
        final nameMatch = (productNameEn?.contains(searchTerms) ?? false) ||
                        (productName?.contains(searchTerms) ?? false);
        final brandMatch = brand?.contains(searchTerms) ?? false;

        // For debugging
        if (nameMatch || brandMatch) {
          print('Match found - Name: ${productMap['product_name']}, Brand: ${productMap['brands']}');
        }

        return nameMatch || brandMatch;
      }).map((product) {
        final productMap = product as Map<String, dynamic>;
        try {
          // Prefer English product name if available
          final name = productMap['product_name_en'] ?? productMap['product_name'] ?? 'Unknown';
          
          return Product(
            barcode: productMap['code'] ?? '',
            name: name,
            brand: productMap['brands'] ?? 'Unknown',
            imageUrl: productMap['image_url'],
            ingredients: productMap['ingredients_text'] ?? '',
            nutritionalValues: _extractNutritionalValues(productMap['nutriments'] ?? {}),
            allergens: _extractAllergens(productMap),
            additives: _extractAdditives(productMap),
            nutriscore: (productMap['nutriscore_grade'] as String?)?.toUpperCase() ?? 'N/A',
            isVegan: _isVegan(productMap),
            isVegetarian: _isVegetarian(productMap),
            isPalmOilFree: _isPalmOilFree(productMap),
          );
        } catch (e) {
          print('Error processing product ${productMap['code']}: $e');
          return null;
        }
      }).whereType<Product>().toList();
    } catch (e) {
      print('Error searching products: $e');
      rethrow;
    }
  }

  Map<String, double> _extractNutritionalValues(dynamic nutriments) {
    final values = <String, double>{};
    
    if (nutriments == null) {
      return values;
    }

    try {
      values['energy'] = (nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal'] ?? 0).toDouble();
      values['fat'] = (nutriments['fat_100g'] ?? 0).toDouble();
      values['saturated_fat'] = (nutriments['saturated-fat_100g'] ?? 0).toDouble();
      values['carbohydrates'] = (nutriments['carbohydrates_100g'] ?? 0).toDouble();
      values['sugars'] = (nutriments['sugars_100g'] ?? 0).toDouble();
      values['proteins'] = (nutriments['proteins_100g'] ?? 0).toDouble();
      values['salt'] = (nutriments['salt_100g'] ?? 0).toDouble();
      values['fiber'] = (nutriments['fiber_100g'] ?? 0).toDouble();
    } catch (e) {
      print('Error extracting nutritional values: $e');
    }
    
    return values;
  }

  List<String> _extractAllergens(Map<String, dynamic> product) {
    try {
      final allergens = product['allergens_tags'] as List<dynamic>? ?? [];
      return allergens
          .where((allergen) => allergen != null)
          .map((allergen) => allergen.toString().replaceAll('en:', ''))
          .toList();
    } catch (e) {
      print('Error extracting allergens: $e');
      return [];
    }
  }

  bool _isVegan(Map<String, dynamic> product) {
    try {
      final tags = product['ingredients_analysis_tags'] as List<dynamic>? ?? [];
      return tags.any((tag) => tag != null && tag.toString().contains('vegan'));
    } catch (e) {
      print('Error checking vegan status: $e');
      return false;
    }
  }

  bool _isVegetarian(Map<String, dynamic> product) {
    try {
      final tags = product['ingredients_analysis_tags'] as List<dynamic>? ?? [];
      return tags.any((tag) => tag != null && tag.toString().contains('vegetarian'));
    } catch (e) {
      print('Error checking vegetarian status: $e');
      return false;
    }
  }

  bool _isPalmOilFree(Map<String, dynamic> product) {
    try {
      final tags = product['ingredients_analysis_tags'] as List<dynamic>? ?? [];
      return tags.any((tag) => tag != null && tag.toString().contains('palm-oil-free'));
    } catch (e) {
      print('Error checking palm oil free status: $e');
      return false;
    }
  }

  List<Map<String, String>> _extractAdditives(Map<String, dynamic> product) {
    try {
      final additivesTags = product['additives_tags'] as List<dynamic>? ?? [];
      final additivesOriginalTags = product['additives_original_tags'] as List<dynamic>? ?? [];
      final additivesDebugTags = product['additives_debug_tags'] as List<dynamic>? ?? [];
      
      final additives = <Map<String, String>>[];
      
      for (var i = 0; i < additivesTags.length; i++) {
        final code = additivesTags[i].toString().replaceAll('en:', '');
        String name = '';
        String risk = 'unknown';
        String description = '';
        
        // Get the original name if available
        if (i < additivesOriginalTags.length) {
          name = additivesOriginalTags[i].toString().replaceAll('en:', '');
        }
        
        // Determine risk level based on E-number ranges
        if (code.startsWith('e1')) {
          description = 'Color additive';
          risk = 'moderate';
        } else if (code.startsWith('e2')) {
          description = 'Preservative';
          risk = 'moderate';
        } else if (code.startsWith('e3')) {
          description = 'Antioxidant';
          risk = 'low';
        } else if (code.startsWith('e4')) {
          description = 'Thickener/Emulsifier';
          risk = 'low';
        } else if (code.startsWith('e5')) {
          description = 'Acidity regulator';
          risk = 'low';
        } else if (code.startsWith('e6')) {
          description = 'Flavor enhancer';
          risk = 'moderate';
        } else if (code.startsWith('e9')) {
          description = 'Sweetener';
          risk = 'high';
        }
        
        additives.add({
          'code': code,
          'name': name,
          'risk': risk,
          'description': description,
        });
      }
      
      return additives;
    } catch (e) {
      print('Error extracting additives: $e');
      return [];
    }
  }
} 