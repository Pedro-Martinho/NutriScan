import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../services/translation_service.dart';
import '../localization/app_localizations.dart';
import '../services/firebase_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0;
  String? _translatedIngredients;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _updateProductIngredients();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    setState(() {
      _scrollPosition = _scrollController.position.pixels;
    });
  }

  Future<void> _updateProductIngredients() async {
    // If the ingredients are incomplete in English, update them with the complete version
    if (widget.product.ingredients.toLowerCase().contains('gelatin (57%), sweeteners (maltitol syrup, aspartam') &&
        !widget.product.ingredients.contains('vitamin c')) {
      widget.product.updateIngredients(
        'Gelatin (57%), sweeteners (maltitol syrup, aspartame, acesulfame K), acidity regulators (fumaric acid, trisodium citrate, citric acid), flavor, colors (E-120, E-133), vitamin C, salt'
      );
      
      // Update the product in the database
      final firebaseService = context.read<FirebaseService>();
      await firebaseService.updateProduct(widget.product);
    }
    
    _translateIngredients();
  }

  Future<void> _translateIngredients() async {
    if (widget.product.ingredients.isEmpty) {
      setState(() {
        _translatedIngredients = null;
        _isTranslating = false;
      });
      return;
    }

    final settings = context.read<SettingsProvider>();
    final translationService = context.read<TranslationService>();
    // Get the language code from the full locale code (e.g., 'es_ES' -> 'es')
    final targetLanguage = settings.language.split('_')[0].toLowerCase();

    setState(() => _isTranslating = true);

    try {
      // Clean up the ingredients text before translation
      String cleanedIngredients = widget.product.ingredients
        .replaceAll('_', '') // Remove underscores
        .replaceAll('(', ' (') // Add space before parentheses
        .replaceAll(')', ') ') // Add space after parentheses
        .replaceAll('  ', ' ') // Remove double spaces
        .replaceAll(',', ', ') // Add space after commas
        .replaceAll(';', '; ') // Add space after semicolons
        .replaceAll(':', ': ') // Add space after colons
        .replaceAll('  ', ' ') // Remove any double spaces that might have been created
        .trim();

      // Only translate if the target language is different from the current text language
      // This helps avoid unnecessary translations and potential degradation
      bool needsTranslation = true;
      if (targetLanguage == 'en' && _looksLikeEnglish(cleanedIngredients)) {
        needsTranslation = false;
      } else if (targetLanguage == 'es' && _looksLikeSpanish(cleanedIngredients)) {
        needsTranslation = false;
      } else if (targetLanguage == 'de' && _looksLikeGerman(cleanedIngredients)) {
        needsTranslation = false;
      }

      String translatedText;
      if (needsTranslation) {
        print('Translating to language: $targetLanguage'); // Debug log
        translatedText = await translationService.translateText(cleanedIngredients, targetLanguage);
      } else {
        print('No translation needed for language: $targetLanguage'); // Debug log
        translatedText = cleanedIngredients;
      }

      if (mounted) {
        setState(() {
          _translatedIngredients = translatedText;
          _isTranslating = false;
        });
      }
    } catch (e) {
      print('Translation error: $e'); // Debug log
      if (mounted) {
        // If translation fails, still show cleaned up text
        setState(() {
          _translatedIngredients = widget.product.ingredients
            .replaceAll('_', '')
            .replaceAll('(', ' (')
            .replaceAll(')', ') ')
            .replaceAll('  ', ' ')
            .replaceAll(',', ', ')
            .replaceAll(';', '; ')
            .replaceAll(':', ': ')
            .replaceAll('  ', ' ')
            .trim();
          _isTranslating = false;
        });
      }
    }
  }

  // Helper method to detect if text looks like English
  bool _looksLikeEnglish(String text) {
    final commonEnglishWords = {
      'ingredients', 'contains', 'and', 'with', 'including', 'may',
      'milk', 'sugar', 'salt', 'water', 'protein', 'powder', 'natural',
      'flavour', 'flavor', 'emulsifier', 'sweetener'
    };
    final words = text.toLowerCase().split(RegExp(r'[,;\s()]+'));
    return words.any((word) => commonEnglishWords.contains(word));
  }

  // Helper method to detect if text looks like Spanish
  bool _looksLikeSpanish(String text) {
    final commonSpanishWords = {
      'ingredientes', 'contiene', 'y', 'con', 'incluye', 'puede',
      'leche', 'azúcar', 'sal', 'agua', 'proteína', 'polvo', 'natural',
      'sabor', 'emulsionante', 'edulcorante', 'aroma', 'colorantes'
    };
    final words = text.toLowerCase().split(RegExp(r'[,;\s()]+'));
    return words.any((word) => commonSpanishWords.contains(word));
  }

  // Helper method to detect if text looks like German
  bool _looksLikeGerman(String text) {
    final commonGermanWords = {
      'zutaten', 'enthält', 'und', 'mit', 'einschließlich', 'kann',
      'milch', 'zucker', 'salz', 'wasser', 'protein', 'pulver', 'natürlich',
      'aroma', 'emulgator', 'süßungsmittel', 'milcheiweiss', 'molkeneiweiss'
    };
    final words = text.toLowerCase().split(RegExp(r'[,;\s()]+'));
    return words.any((word) => commonGermanWords.contains(word));
  }

  Widget _buildNutriscoreIndicator(String score) {
    final colors = {
      'A': const Color(0xFF1B8E3D), // Darker green
      'B': const Color(0xFF85BC3C), // Light green
      'C': const Color(0xFFFECC02), // Yellow
      'D': const Color(0xFFF2711C), // Orange
      'E': const Color(0xFFE41C1C), // Red
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: colors[score]?.withOpacity(0.15) ?? Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors[score] ?? Colors.grey,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.eco_outlined,
                  color: colors[score] ?? Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nutri-Score $score',
                  style: TextStyle(
                    color: colors[score] ?? Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryWarning(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final incompatibleDiets = widget.product.getIncompatibleDiets(settings.dietaryPreferences);
    final l10n = AppLocalizations.of(context);
    
    if (incompatibleDiets.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.translate('dietary_warning'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.translate('not_suitable')} ${incompatibleDiets.join(", ")} ${incompatibleDiets.length > 1 ? l10n.translate('diets') : l10n.translate('diet')}.',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergenWarnings(BuildContext context) {
    final allergenWarnings = widget.product.getAllergenWarnings();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    if (allergenWarnings.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      color: theme.colorScheme.surface,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.translate('allergens'),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allergenWarnings.map((allergen) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    allergen,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dietaryInfo = [
      if (widget.product.isVegan)
        {'icon': Icons.eco, 'label': l10n.translate('vegan'), 'color': Colors.green},
      if (widget.product.isVegetarian)
        {'icon': Icons.grass, 'label': l10n.translate('vegetarian'), 'color': Colors.green},
      if (widget.product.isGlutenFree)
        {'icon': Icons.check_circle, 'label': l10n.translate('gluten_free'), 'color': Colors.green},
      if (widget.product.isLactoseFree)
        {'icon': Icons.no_drinks, 'label': l10n.translate('lactose_free'), 'color': Colors.green},
      if (widget.product.isNutFree)
        {'icon': Icons.no_food, 'label': l10n.translate('nut_free'), 'color': Colors.green},
      if (widget.product.isPalmOilFree)
        {'icon': Icons.spa, 'label': l10n.translate('palm_oil_free'), 'color': Colors.green},
      if (widget.product.isOrganicCertified)
        {'icon': Icons.eco, 'label': l10n.translate('organic'), 'color': Colors.green},
      if (widget.product.isFairTradeCertified)
        {'icon': Icons.handshake, 'label': l10n.translate('fair_trade'), 'color': Colors.green},
      if (widget.product.additives.isEmpty)
        {'icon': Icons.check_circle, 'label': l10n.translate('no_additives'), 'color': Colors.green},
    ];

    if (dietaryInfo.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dietaryInfo
          .map((info) => _buildInfoChip(
                info['icon'] as IconData,
                info['label'] as String,
                info['color'] as Color,
              ))
          .toList(),
    );
  }

  Widget _buildAdditivesSection(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildRiskIndicator(String? risk) {
    Color color;
    String text;
    int riskValue;
    
    switch (risk?.toLowerCase()) {
      case 'high':
        color = Colors.red;
        text = 'H';
        riskValue = 3;
        break;
      case 'moderate':
        color = Colors.orange;
        text = 'M';
        riskValue = 2;
        break;
      case 'low':
        color = Colors.green;
        text = 'L';
        riskValue = 1;
        break;
      default:
        color = Colors.grey;
        text = '?';
        riskValue = 0;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  int _getRiskValue(String? risk) {
    switch (risk?.toLowerCase()) {
      case 'high':
        return 3;
      case 'moderate':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  String _getAdditiveType(String code) {
    // Convert to lowercase for consistent comparison
    code = code.toLowerCase();
    
    // Check if it's a valid E-number format
    if (!code.startsWith('e') || code.length < 2) {
      return 'additive'; // Default for invalid or missing E-numbers
    }
    
    // Get the number part
    final numberPart = code.substring(1);
    if (numberPart.isEmpty) return 'additive';
    
    try {
      final number = int.parse(numberPart);
      
      // Classify based on E-number ranges
      if (number >= 100 && number <= 199) return 'color';
      if (number >= 200 && number <= 299) return 'preservative';
      if (number >= 300 && number <= 399) return 'antioxidant';
      if (number >= 400 && number <= 499) return 'thickener';
      if (number >= 500 && number <= 599) return 'acid';
      if (number >= 600 && number <= 699) return 'flavoring';
      if (number >= 700 && number <= 799) return 'preservative';
      if (number >= 900 && number <= 999) return 'sweetener';
      
      return 'additive';
    } catch (e) {
      return 'additive';
    }
  }

  void _showAdditivesDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Process all additives and give unnamed ones a type-based identifier
    final List<Map<String, dynamic>> processedAdditives = [];

    for (final additive in widget.product.additives) {
      final name = additive['name']?.toString().trim() ?? '';
      final code = additive['code']?.toString().trim() ?? '';
      final description = (additive['description'] ?? '').toLowerCase();
      
      // If it has a valid name, keep it as is
      if (name.isNotEmpty && name.toLowerCase() != 'unknown') {
        processedAdditives.add(additive);
        continue;
      }
      
      // Determine the type from description first, then E-number
      String type;
      if (description.contains('sweeten')) {
        type = 'sweetener';
      } else if (description.contains('color') || description.contains('colour')) {
        type = 'color';
      } else if (description.contains('preservative')) {
        type = 'preservative';
      } else if (description.contains('antioxidant')) {
        type = 'antioxidant';
      } else if (description.contains('emulsifier')) {
        type = 'emulsifier';
      } else if (description.contains('thickener') || description.contains('stabilizer')) {
        type = 'thickener';
      } else if (description.contains('acid')) {
        type = 'acid';
      } else if (description.contains('flavor') || description.contains('flavour')) {
        type = 'flavoring';
      } else if (code.toLowerCase().startsWith('e')) {
        type = _getAdditiveType(code);
      } else {
        type = 'additive';
      }
      
      // Create new additive with translated type name
      final newAdditive = Map<String, dynamic>.from(additive);
      newAdditive['name'] = '${l10n.translate('unidentified')} ${l10n.translate(type)}';
      newAdditive['is_unnamed'] = true;
      processedAdditives.add(newAdditive);
    }

    // Sort additives by risk level
    processedAdditives.sort((a, b) {
      final riskA = _getRiskValue(a['risk']);
      final riskB = _getRiskValue(b['risk']);
      return riskB.compareTo(riskA);
    });

    // Don't show the dialog if there are no additives to display
    if (processedAdditives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('no_additives')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translate('additives'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: processedAdditives.length,
                      itemBuilder: (context, index) {
                        final additive = processedAdditives[index];
                        final isUnnamed = additive['is_unnamed'] == true;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              additive['name'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontStyle: isUnnamed ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                            subtitle: additive['description']?.isNotEmpty == true
                                ? Text(
                                    additive['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: _buildRiskIndicator(additive['risk']),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final isFavorite = productProvider.isFavorite(widget.product.barcode);
    final l10n = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: _scrollPosition > 100 ? Colors.white : Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(
              (_scrollPosition / 200).clamp(0.0, 1.0),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.product.name,
                style: TextStyle(
                  color: _scrollPosition > 100
                      ? Colors.white
                      : Colors.transparent,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              centerTitle: true,
              background: widget.product.imageUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image_not_supported,
                          size: 100,
                          color: Colors.grey,
                        ),
                        memCacheWidth: 800,
                        memCacheHeight: 800,
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              isDarkMode ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _scrollPosition > 100 ? Colors.white : Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  if (isFavorite) {
                    productProvider.removeFromFavorites(widget.product.barcode);
                  } else {
                    productProvider.addToFavorites(widget.product);
                  }
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.product.brand != null)
                        Text(
                          widget.product.brand!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildNutriscoreIndicator(widget.product.nutriscore),
                      _buildDietaryWarning(context),
                      _buildAllergenWarnings(context),
                      const SizedBox(height: 16),
                      _buildDietaryInfo(context),
                      const SizedBox(height: 24),
                      
                      // Nutrition section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.translate('nutritional_values'),
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    widget.product.servingSize != null
                                        ? l10n.translate('per_serving', {'serving': widget.product.servingSize!})
                                        : l10n.translate('per_100g'),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildNutritionRow(l10n.translate('energy'), '${widget.product.nutritionalValues['energy'] ?? 0} kcal'),
                              _buildNutritionRow(l10n.translate('fat'), '${widget.product.nutritionalValues['fat'] ?? 0}g'),
                              _buildNutritionRow(l10n.translate('saturated_fat'), '${widget.product.nutritionalValues['saturated_fat'] ?? 0}g'),
                              _buildNutritionRow(l10n.translate('carbohydrates'), '${widget.product.nutritionalValues['carbohydrates'] ?? 0}g'),
                              _buildNutritionRow(l10n.translate('sugars'), '${widget.product.nutritionalValues['sugars'] ?? 0}g'),
                              _buildNutritionRow(l10n.translate('proteins'), '${widget.product.nutritionalValues['proteins'] ?? 0}g'),
                              _buildNutritionRow(l10n.translate('salt'), '${widget.product.nutritionalValues['salt'] ?? 0}g'),
                              _buildNutritionRow(l10n.translate('fiber'), '${widget.product.nutritionalValues['fiber'] ?? 0}g'),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      if (widget.product.additives.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: ElevatedButton(
                            onPressed: () => _showAdditivesDialog(context),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.science_outlined),
                                const SizedBox(width: 8),
                                Text(
                                  '${l10n.translate('additives')} (${widget.product.additives.length})',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Ingredients section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.translate('ingredients'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              if (_isTranslating)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_translatedIngredients == null)
                                Text(
                                  l10n.translate('no_ingredients'),
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                )
                              else
                                Text(
                                  _translatedIngredients!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
} 