import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/product_service.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../localization/app_localizations.dart';
import '../widgets/app_bar_with_profile.dart';
import 'product_details_screen.dart';
import 'dart:async';
import 'dart:developer' as developer;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _searchResults = [];
  bool _isSearching = false;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _debounceTimer;
  bool _isLocalSearch = true;  // Track if we're showing local results

  @override
  void initState() {
    super.initState();
    developer.log('SearchScreen initialized');
  }

  @override
  void dispose() {
    developer.log('Disposing SearchScreen');
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  List<Product> _searchLocalProducts(String query, BuildContext context) {
    final productProvider = context.read<ProductProvider>();
    final searchTerms = query.toLowerCase();
    
    // Create a map using barcode as key to remove duplicates
    final productsMap = <String, Product>{};
    
    // Add scanned products
    for (final product in productProvider.scannedProducts) {
      productsMap[product.barcode] = product;
    }
    
    // Add favorites (will overwrite scanned products if they exist)
    for (final product in productProvider.favorites) {
      productsMap[product.barcode] = product;
    }
    
    // Filter the unique products
    return productsMap.values.where((product) {
      final name = product.name.toLowerCase();
      final brand = product.brand?.toLowerCase() ?? '';
      final barcode = product.barcode.toLowerCase();
      
      return name.contains(searchTerms) || 
             brand.contains(searchTerms) || 
             barcode.contains(searchTerms);
    }).toList();
  }

  Future<void> _onSearch(String query) async {
    developer.log('Search query: "$query"');
    _debounceTimer?.cancel();
    
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasError = false;
        _isLocalSearch = true;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      
      setState(() {
        _isSearching = true;
        _hasError = false;
        _errorMessage = '';
      });

      try {
        // First search in local products
        final localResults = _searchLocalProducts(query, context);
        
        if (localResults.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _searchResults = localResults;
            _isSearching = false;
            _isLocalSearch = true;
          });
          return;
        }

        // If no local results, try OpenFoodFacts
        developer.log('No local results, searching OpenFoodFacts');
        final productService = context.read<ProductService>();
        final results = await productService.searchProducts(query);
        developer.log('Search completed. Found ${results.length} results');

        if (!mounted) return;

        setState(() {
          _searchResults = results;
          _isSearching = false;
          _isLocalSearch = false;
        });
      } catch (e, stackTrace) {
        developer.log('Search error: $e\n$stackTrace');
        if (!mounted) return;

        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    developer.log('Building SearchScreen');
    
    return Scaffold(
      appBar: AppBarWithProfile(
        title: l10n.translate('search_products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('search_hint'),
                    helperText: l10n.translate('search_helper_text'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: _onSearch,
                  textInputAction: TextInputAction.search,
                ),
                if (_searchResults.isNotEmpty && _isLocalSearch)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.translate('showing_local_results'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                if (_searchResults.isEmpty && !_isSearching && _searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.translate('no_local_results'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    developer.log('Building content. isSearching: $_isSearching, hasError: $_hasError, resultsCount: ${_searchResults.length}');

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('search_error'),
              style: const TextStyle(fontSize: 16),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            TextButton(
              onPressed: () => _onSearch(_searchController.text),
              child: Text(l10n.translate('try_again')),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      if (_searchController.text.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.translate('start_searching'),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sentiment_dissatisfied,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.translate('no_results'),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        developer.log('Building product item: ${product.name}');
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(product.brand ?? l10n.translate('unknown_brand')),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(
                      product: product,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
} 