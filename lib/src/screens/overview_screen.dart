import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../localization/app_localizations.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../widgets/app_bar_with_profile.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

  Map<String, double> _calculateNutriscoreDistribution(List<Product> products) {
    if (products.isEmpty) return {};
    
    // Create a map to store unique products by barcode
    final uniqueProducts = <String, Product>{};
    for (final product in products) {
      uniqueProducts[product.barcode] = product;
    }
    
    final counts = {
      'A': 0.0, 'B': 0.0, 'C': 0.0, 'D': 0.0, 'E': 0.0,
    };
    
    for (final product in uniqueProducts.values) {
      if (counts.containsKey(product.nutriscore)) {
        counts[product.nutriscore] = (counts[product.nutriscore] ?? 0) + 1;
      }
    }
    
    final total = counts.values.reduce((a, b) => a + b);
    return counts.map((key, value) => MapEntry(key, total > 0 ? value / total : 0));
  }

  int _countEcoFriendlyProducts(List<Product> products) {
    // Create a map to store unique products by barcode
    final uniqueProducts = <String, Product>{};
    for (final product in products) {
      uniqueProducts[product.barcode] = product;
    }
    
    return uniqueProducts.values.where((p) => 
      p.isVegan || p.isVegetarian || p.isPalmOilFree
    ).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBarWithProfile(
        title: l10n.translate('overview'),
        scrollPosition: _scrollPosition,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          // Combine scanned products and favorites
          final allProducts = [...provider.scannedProducts, ...provider.favorites];
          final nutriscoreDistribution = _calculateNutriscoreDistribution(allProducts);
          final ecoFriendlyCount = _countEcoFriendlyProducts(allProducts);

          // Count unique products
          final uniqueScanned = provider.scannedProducts.map((p) => p.barcode).toSet().length;
          final uniqueFavorites = provider.favorites.map((p) => p.barcode).toSet().length;

          return ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              RepaintBoundary(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('scan_statistics'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildStatItem(Icons.qr_code_scanner, uniqueScanned.toString(), l10n.translate('total_scans')),
                        _buildStatItem(Icons.favorite, uniqueFavorites.toString(), l10n.translate('total_favorites')),
                        _buildStatItem(Icons.eco, ecoFriendlyCount.toString(), l10n.translate('eco_friendly_products')),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('nutrition_overview'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildNutritionBar('A', nutriscoreDistribution['A'] ?? 0, Colors.green),
                        _buildNutritionBar('B', nutriscoreDistribution['B'] ?? 0, Colors.lightGreen),
                        _buildNutritionBar('C', nutriscoreDistribution['C'] ?? 0, Colors.yellow),
                        _buildNutritionBar('D', nutriscoreDistribution['D'] ?? 0, Colors.orange),
                        _buildNutritionBar('E', nutriscoreDistribution['E'] ?? 0, Colors.red),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.grey[600]),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionBar(String grade, double percentage, Color color) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                grade,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${(percentage * 100).toInt()}%'),
          ],
        ),
      ),
    );
  }
} 