import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import '../localization/app_localizations.dart';
import '../widgets/app_bar_with_profile.dart';
import 'product_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  Product? _product1;
  Product? _product2;
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Ensure products are loaded when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.loadProducts();
    });
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<ProductProvider>();
    
    // Clear selected products if they're no longer in the provider's data
    if (_product1 != null && !_isProductAvailable(_product1!, provider)) {
      setState(() => _product1 = null);
    }
    if (_product2 != null && !_isProductAvailable(_product2!, provider)) {
      setState(() => _product2 = null);
    }
  }

  bool _isProductAvailable(Product product, ProductProvider provider) {
    return provider.scannedProducts.any((p) => p.barcode == product.barcode) ||
           provider.favorites.any((p) => p.barcode == product.barcode);
  }

  Widget _buildProductSelector(Product? selectedProduct, bool isFirst) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          margin: const EdgeInsets.all(8),
          child: InkWell(
            onTap: () => _selectProduct(isFirst),
            child: Container(
              width: double.infinity,
              height: 280, // Fixed height for consistency
              padding: const EdgeInsets.all(16),
              child: selectedProduct == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)?.translate('select_product') ?? '',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        if (selectedProduct.imageUrl != null)
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 180, // Maximum width for the image
                                  maxHeight: 200, // Maximum height for the image
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: selectedProduct.imageUrl!,
                                  fit: BoxFit.contain,
                                  memCacheWidth: 360, // 2x for high DPI
                                  memCacheHeight: 400,
                                  fadeInDuration: const Duration(milliseconds: 300),
                                  placeholder: (context, url) => const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          selectedProduct.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          selectedProduct.brand ?? '',
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (selectedProduct != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: () {
                setState(() {
                  if (isFirst) {
                    _product1 = null;
                  } else {
                    _product2 = null;
                  }
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.remove_circle_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)?.translate('remove') ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _selectProduct(bool isFirst) async {
    final provider = context.read<ProductProvider>();
    
    // Create a map using barcode as key to remove duplicates
    final productsMap = <String, Product>{};
    
    // Add scanned products
    for (final product in provider.scannedProducts) {
      productsMap[product.barcode] = product;
    }
    
    // Add favorites (will overwrite scanned products if they exist)
    for (final product in provider.favorites) {
      productsMap[product.barcode] = product;
    }
    
    final products = productsMap.values.toList();
    
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('no_products_to_compare')),
        ),
      );
      return;
    }

    // Filter out the already selected product from the other side
    final availableProducts = products.where((product) {
      if (isFirst) {
        return product.barcode != _product2?.barcode;
      } else {
        return product.barcode != _product1?.barcode;
      }
    }).toList();

    if (availableProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('no_other_products_to_compare')),
        ),
      );
      return;
    }

    final selectedProduct = await showDialog<Product>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('select_product')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableProducts.length,
            itemBuilder: (context, index) {
              final product = availableProducts[index];
              return ListTile(
                leading: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.image_not_supported),
                      )
                    : const Icon(Icons.image_not_supported),
                title: Text(product.name),
                subtitle: Text(product.brand ?? ''),
                onTap: () => Navigator.pop(context, product),
              );
            },
          ),
        ),
      ),
    );

    if (selectedProduct != null) {
      setState(() {
        if (isFirst) {
          _product1 = selectedProduct;
        } else {
          _product2 = selectedProduct;
        }
      });
    }
  }

  String _formatNutritionalValue(Map<String, double> values, String key) {
    final value = values[key];
    if (value == null) return '0';
    return value.toStringAsFixed(1);
  }

  Widget _buildComparisonTable(BuildContext context, List<Product> products) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    final nutritionItems = [
      {'key': 'energy', 'label': l10n.translate('energy'), 'unit': 'kcal'},
      {'key': 'fat', 'label': l10n.translate('fat'), 'unit': 'g'},
      {'key': 'saturated_fat', 'label': l10n.translate('saturated_fat'), 'unit': 'g'},
      {'key': 'carbohydrates', 'label': l10n.translate('carbohydrates'), 'unit': 'g'},
      {'key': 'sugars', 'label': l10n.translate('sugars'), 'unit': 'g'},
      {'key': 'proteins', 'label': l10n.translate('proteins'), 'unit': 'g'},
      {'key': 'salt', 'label': l10n.translate('salt'), 'unit': 'g'},
      {'key': 'fiber', 'label': l10n.translate('fiber'), 'unit': 'g'},
    ];

    return Column(
      children: [
        if (_product1 != null && _product2 != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.translate('per_100g'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ...nutritionItems.map((item) {
          final value1 = _product1?.nutritionalValues[item['key']]?.toStringAsFixed(1) ?? '-';
          final value2 = _product2?.nutritionalValues[item['key']]?.toStringAsFixed(1) ?? '-';
          final unit1 = _product1 != null ? item['unit'] : '';
          final unit2 = _product2 != null ? item['unit'] : '';

          return RepaintBoundary(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      item['label'] ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$value1 $unit1',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Container(
                              width: 2,
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$value2 $unit2',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _handleDetailsPress() {
    if (_product1 == null && _product2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('select_product_for_details')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_product1 != null && _product2 == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(product: _product1!),
        ),
      );
      return;
    }

    if (_product1 == null && _product2 != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(product: _product2!),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(_product1!.name),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(product: _product1!),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(_product2!.name),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailsScreen(product: _product2!),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBarWithProfile(
        title: l10n?.translate('compare') ?? '',
        scrollPosition: _scrollPosition,
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, child) {
          if (provider.scannedProducts.isEmpty && provider.favorites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n?.translate('no_products_to_compare') ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            );
          }

          return SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n?.translate('comparison_instructions') ?? '',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Row(
                  children: [
                    Expanded(child: _buildProductSelector(_product1, true)),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_forward,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                      ],
                    ),
                    Expanded(child: _buildProductSelector(_product2, false)),
                  ],
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: _handleDetailsPress,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      l10n?.translate(
                        (_product1 != null && _product2 != null)
                            ? 'product_details_plural'
                            : 'product_details_singular'
                      ) ?? '',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildComparisonTable(context, [if (_product1 != null) _product1!, if (_product2 != null) _product2!]),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
} 