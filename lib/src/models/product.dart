import 'package:flutter/foundation.dart';

class Product {
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final String nutriscore;
  String ingredients;
  final Map<String, double> nutritionalValues;
  final List<String> allergens;
  final List<Map<String, String>> additives;
  final bool isVegan;
  final bool isVegetarian;
  final bool isPalmOilFree;
  final bool isGlutenFree;
  final bool isLactoseFree;
  final bool isNutFree;
  final bool isOrganicCertified;
  final bool isFairTradeCertified;
  final DateTime? favoriteTimestamp;
  final String? servingSize;

  Product({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.nutriscore,
    required this.ingredients,
    required this.nutritionalValues,
    required this.allergens,
    required this.additives,
    required this.isVegan,
    required this.isVegetarian,
    required this.isPalmOilFree,
    this.isGlutenFree = false,
    this.isLactoseFree = false,
    this.isNutFree = false,
    this.isOrganicCertified = false,
    this.isFairTradeCertified = false,
    this.favoriteTimestamp,
    this.servingSize,
  });

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'imageUrl': imageUrl,
      'nutriscore': nutriscore,
      'ingredients': ingredients,
      'nutritionalValues': nutritionalValues,
      'allergens': allergens,
      'additives': additives.map((additive) => Map<String, dynamic>.from(additive)).toList(),
      'isVegan': isVegan,
      'isVegetarian': isVegetarian,
      'isPalmOilFree': isPalmOilFree,
      'isGlutenFree': isGlutenFree,
      'isLactoseFree': isLactoseFree,
      'isNutFree': isNutFree,
      'isOrganicCertified': isOrganicCertified,
      'isFairTradeCertified': isFairTradeCertified,
      'favoriteTimestamp': favoriteTimestamp?.toIso8601String(),
      'servingSize': servingSize,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        barcode: json['barcode']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown',
        brand: json['brand']?.toString(),
        imageUrl: json['imageUrl']?.toString(),
        nutriscore: json['nutriscore']?.toString() ?? 'Unknown',
        ingredients: json['ingredients']?.toString() ?? '',
        nutritionalValues: (json['nutritionalValues'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ) ?? {},
        allergens: (json['allergens'] as List<dynamic>?)
            ?.map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList() ?? [],
        additives: (json['additives'] as List<dynamic>?)?.map((e) {
          final map = e as Map<String, dynamic>;
          return {
            'code': map['code']?.toString() ?? '',
            'name': map['name']?.toString() ?? '',
            'risk': map['risk']?.toString() ?? 'unknown',
            'description': map['description']?.toString() ?? '',
          };
        }).toList() ?? [],
        isVegan: json['isVegan'] as bool? ?? false,
        isVegetarian: json['isVegetarian'] as bool? ?? false,
        isPalmOilFree: json['isPalmOilFree'] as bool? ?? false,
        isGlutenFree: json['isGlutenFree'] as bool? ?? false,
        isLactoseFree: json['isLactoseFree'] as bool? ?? false,
        isNutFree: json['isNutFree'] as bool? ?? false,
        isOrganicCertified: json['isOrganicCertified'] as bool? ?? false,
        isFairTradeCertified: json['isFairTradeCertified'] as bool? ?? false,
        favoriteTimestamp: json['favoriteTimestamp'] != null 
            ? DateTime.parse(json['favoriteTimestamp']) 
            : null,
        servingSize: json['servingSize']?.toString(),
      );
    } catch (e) {
      print('Error creating Product from JSON: $e');
      rethrow;
    }
  }

  List<String> getIncompatibleDiets(List<String> userDiets) {
    final incompatibleDiets = <String>[];
    
    for (final diet in userDiets) {
      if (!isCompatibleWithDiet(diet)) {
        incompatibleDiets.add(diet);
      }
    }
    
    return incompatibleDiets;
  }

  bool isCompatibleWithDiet(String diet) {
    switch (diet.toLowerCase()) {
      case 'vegetarian':
        return isVegetarian;
      case 'vegan':
        return isVegan;
      case 'gluten-free':
        return isGlutenFree;
      case 'lactose-free':
        return isLactoseFree;
      case 'nut-free':
        return isNutFree;
      case 'palm-oil-free':
        return isPalmOilFree;
      case 'organic':
        return isOrganicCertified;
      case 'fair-trade':
        return isFairTradeCertified;
      default:
        return true;
    }
  }

  // Common allergen variations and their standard forms
  static const Map<String, String> _allergenVariations = {
    // Dairy/Milk variations
    'milk': 'milk',
    'dairy': 'milk',
    'lactose': 'milk',
    'whey': 'milk',
    'molkeneiweißisolat': 'milk',  // German whey protein isolate
    'molkeneiweiss': 'milk',       // German whey protein
    'milcheiweiss': 'milk',        // German milk protein
    'lait': 'milk',                // French
    'leche': 'milk',               // Spanish
    'milch': 'milk',               // German
    'leite': 'milk',               // Portuguese
    'casein': 'milk',
    'butter': 'milk',
    'cream': 'milk',
    'yogurt': 'milk',
    'cheese': 'milk',

    // Gluten/Wheat variations
    'gluten': 'gluten',
    'wheat': 'gluten',
    'barley': 'gluten',
    'rye': 'gluten',
    'oats': 'gluten',
    'weizen': 'gluten',            // German
    'blé': 'gluten',               // French
    'trigo': 'gluten',             // Spanish/Portuguese
    'gerste': 'gluten',            // German barley
    'roggen': 'gluten',            // German rye
    'hafer': 'gluten',             // German oats

    // Soy variations
    'soy': 'soy',
    'soya': 'soy',
    'soja': 'soy',                 // German/Spanish/Portuguese
    'soja-': 'soy',                // With hyphen
    'soybeans': 'soy',
    'soybean': 'soy',

    // Nut variations
    'nuts': 'nuts',
    'tree nuts': 'nuts',
    'treenuts': 'nuts',
    'peanuts': 'peanuts',          // Separate from tree nuts
    'almond': 'nuts',
    'hazelnut': 'nuts',
    'walnut': 'nuts',
    'cashew': 'nuts',
    'pistachio': 'nuts',
    'macadamia': 'nuts',
    'pecan': 'nuts',
    'mandeln': 'nuts',             // German almonds
    'haselnüsse': 'nuts',          // German hazelnuts
    'nüsse': 'nuts',               // German nuts
    'noix': 'nuts',                // French
    'nueces': 'nuts',              // Spanish
    'nozes': 'nuts',               // Portuguese

    // Egg variations
    'egg': 'eggs',
    'eggs': 'eggs',
    'ei': 'eggs',                  // German
    'eier': 'eggs',                // German plural
    'oeuf': 'eggs',                // French
    'huevo': 'eggs',               // Spanish
    'ovo': 'eggs',                 // Portuguese

    // Fish variations
    'fish': 'fish',
    'salmon': 'fish',
    'tuna': 'fish',
    'cod': 'fish',
    'fisch': 'fish',               // German
    'poisson': 'fish',             // French
    'pescado': 'fish',             // Spanish
    'peixe': 'fish',               // Portuguese

    // Shellfish variations
    'shellfish': 'shellfish',
    'shrimp': 'shellfish',
    'crab': 'shellfish',
    'lobster': 'shellfish',
    'prawn': 'shellfish',
    'schalentiere': 'shellfish',   // German
    'crustacés': 'shellfish',      // French
    'mariscos': 'shellfish',       // Spanish/Portuguese

    // Sesame variations
    'sesame': 'sesame',
    'sesam': 'sesame',             // German
    'sésame': 'sesame',            // French
    'sésamo': 'sesame',            // Spanish/Portuguese

    // Mustard variations
    'mustard': 'mustard',
    'senf': 'mustard',             // German
    'moutarde': 'mustard',         // French
    'mostaza': 'mustard',          // Spanish
    'mostarda': 'mustard',         // Portuguese

    // Celery variations
    'celery': 'celery',
    'sellerie': 'celery',          // German
    'céleri': 'celery',            // French
    'apio': 'celery',              // Spanish
    'aipo': 'celery',              // Portuguese

    // Lupin variations
    'lupine': 'lupin',
    'lupinen': 'lupin',            // German
    'lupin_fr': 'lupin',           // French
    'altramuz': 'lupin',           // Spanish
    'tremoço': 'lupin',            // Portuguese

    // Sulphites variations
    'sulphites': 'sulphites',
    'sulfites': 'sulphites',
    'sulphur dioxide': 'sulphites',
    'sulfur dioxide': 'sulphites',
    'so2': 'sulphites',
    'sulfite': 'sulphites',
    'sulfit': 'sulphites',         // German
    'sulfitos': 'sulphites',       // Spanish/Portuguese
  };

  List<String> getAllergenWarnings() {
    final warnings = <String>[];
    final processedAllergens = <String>{};  // Track processed allergens to avoid duplicates
    
    // Process declared allergens first
    for (String allergen in allergens) {
      // Remove language prefix if present (e.g., "de:", "en:", etc.)
      final cleanAllergen = allergen.replaceAll(RegExp(r'^[a-z]{2}:'), '').trim().toLowerCase();
      
      // Skip if we've already processed this allergen
      if (processedAllergens.contains(cleanAllergen)) continue;
      processedAllergens.add(cleanAllergen);
      
      // Find the standardized form of the allergen
      String? standardAllergen = _allergenVariations[cleanAllergen];
      
      // If no direct match, try to find a partial match
      if (standardAllergen == null) {
        for (var entry in _allergenVariations.entries) {
          // Use word boundary for more precise matching
          final pattern = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b');
          if (pattern.hasMatch(cleanAllergen)) {
            standardAllergen = entry.value;
            processedAllergens.add(entry.key);
            break;
          }
        }
      }
      
      if (standardAllergen != null && !warnings.contains(standardAllergen)) {
        warnings.add(standardAllergen);
      }
    }

    // Check ingredients for potential allergens, but only if they're not already found
    // Split ingredients into words for more precise matching
    final words = ingredients.toLowerCase().split(RegExp(r'[,;\s]+'));
    for (final word in words) {
      final cleanWord = word.trim();
      if (cleanWord.isEmpty || processedAllergens.contains(cleanWord)) continue;

      // Check for exact matches first
      if (_allergenVariations.containsKey(cleanWord)) {
        final standardAllergen = _allergenVariations[cleanWord]!;
        if (!warnings.contains(standardAllergen)) {
          warnings.add(standardAllergen);
          processedAllergens.add(cleanWord);
        }
        continue;
      }

      // Then check for partial matches with word boundaries
      for (final entry in _allergenVariations.entries) {
        if (processedAllergens.contains(entry.key)) continue;
        
        final pattern = RegExp(r'\b' + RegExp.escape(entry.key) + r'\b');
        if (pattern.hasMatch(cleanWord)) {
          if (!warnings.contains(entry.value)) {
            warnings.add(entry.value);
            processedAllergens.add(entry.key);
          }
          break;
        }
      }
    }

    return warnings.toSet().toList()..sort(); // Remove any remaining duplicates and sort alphabetically
  }

  Product copyWith({
    DateTime? favoriteTimestamp,
    String? servingSize,
  }) {
    return Product(
      barcode: barcode,
      name: name,
      brand: brand,
      imageUrl: imageUrl,
      nutriscore: nutriscore,
      ingredients: ingredients,
      nutritionalValues: nutritionalValues,
      allergens: allergens,
      additives: additives,
      isVegan: isVegan,
      isVegetarian: isVegetarian,
      isPalmOilFree: isPalmOilFree,
      isGlutenFree: isGlutenFree,
      isLactoseFree: isLactoseFree,
      isNutFree: isNutFree,
      isOrganicCertified: isOrganicCertified,
      isFairTradeCertified: isFairTradeCertified,
      favoriteTimestamp: favoriteTimestamp ?? this.favoriteTimestamp,
      servingSize: servingSize ?? this.servingSize,
    );
  }

  // Update the ingredients text
  void updateIngredients(String newIngredients) {
    ingredients = newIngredients;
  }
} 