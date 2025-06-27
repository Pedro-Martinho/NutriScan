import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../widgets/app_bar_with_profile.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  _EducationScreenState createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
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

  void _showEducationalContent(BuildContext context, String titleKey, String contentKey) {
    final l10n = AppLocalizations.of(context);
    final content = _getContentForKey(l10n, contentKey);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
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
                      Expanded(
                        child: Text(
                          l10n.translate(titleKey),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                      itemCount: content.length,
                      itemBuilder: (context, index) {
                        final item = content[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.translate(item['subtitle']!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.translate(item['content']!),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
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

  List<Map<String, String>> _getContentForKey(AppLocalizations l10n, String contentKey) {
    switch (contentKey) {
      case 'daily_nutrition':
        return [
          {
            'subtitle': 'daily_intake_title',
            'content': 'daily_intake_content',
          },
          {
            'subtitle': 'macronutrients_title',
            'content': 'macronutrients_content',
          },
          {
            'subtitle': 'vitamins_minerals_title',
            'content': 'vitamins_minerals_content',
          },
          {
            'subtitle': 'hydration_title',
            'content': 'hydration_content',
          },
        ];
      case 'ingredients':
        return [
          {
            'subtitle': 'additives_title',
            'content': 'additives_content',
          },
          {
            'subtitle': 'natural_artificial_title',
            'content': 'natural_artificial_content',
          },
          {
            'subtitle': 'hidden_sugars_title',
            'content': 'hidden_sugars_content',
          },
          {
            'subtitle': 'preservatives_title',
            'content': 'preservatives_content',
          },
        ];
      case 'labels':
        return [
          {
            'subtitle': 'nutrition_panel_title',
            'content': 'nutrition_panel_content',
          },
          {
            'subtitle': 'ingredient_list_title',
            'content': 'ingredient_list_content',
          },
          {
            'subtitle': 'health_claims_title',
            'content': 'health_claims_content',
          },
          {
            'subtitle': 'allergen_info_title',
            'content': 'allergen_info_content',
          },
        ];
      case 'tips':
        return [
          {
            'subtitle': 'balanced_plate_title',
            'content': 'balanced_plate_content',
          },
          {
            'subtitle': 'smart_shopping_title',
            'content': 'smart_shopping_content',
          },
          {
            'subtitle': 'meal_prep_title',
            'content': 'meal_prep_content',
          },
          {
            'subtitle': 'mindful_eating_title',
            'content': 'mindful_eating_content',
          },
        ];
      case 'seasonal':
        return [
          {
            'subtitle': 'spring_title',
            'content': 'spring_content',
          },
          {
            'subtitle': 'summer_title',
            'content': 'summer_content',
          },
          {
            'subtitle': 'fall_title',
            'content': 'fall_content',
          },
          {
            'subtitle': 'winter_title',
            'content': 'winter_content',
          },
        ];
      case 'packaging':
        return [
          {
            'subtitle': 'packaging_symbols_title',
            'content': 'packaging_symbols_content',
          },
          {
            'subtitle': 'sustainable_materials_title',
            'content': 'sustainable_materials_content',
          },
          {
            'subtitle': 'reducing_waste_title',
            'content': 'reducing_waste_content',
          },
          {
            'subtitle': 'proper_disposal_title',
            'content': 'proper_disposal_content',
          },
        ];
      default:
        return [];
    }
  }

  Widget _buildEducationCard({
    required BuildContext context,
    required IconData icon,
    required String titleKey,
    required String descriptionKey,
    required String contentKey,
  }) {
    final l10n = AppLocalizations.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showEducationalContent(context, titleKey, contentKey),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate(titleKey),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate(descriptionKey),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBarWithProfile(
        title: l10n.translate('education'),
        scrollPosition: _scrollPosition,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.translate('education_intro'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            _buildEducationCard(
              context: context,
              icon: Icons.calendar_today,
              titleKey: 'daily_nutrition_facts',
              descriptionKey: 'daily_nutrition_facts_desc',
              contentKey: 'daily_nutrition',
            ),
            _buildEducationCard(
              context: context,
              icon: Icons.menu_book,
              titleKey: 'ingredient_encyclopedia',
              descriptionKey: 'ingredient_encyclopedia_desc',
              contentKey: 'ingredients',
            ),
            _buildEducationCard(
              context: context,
              icon: Icons.label,
              titleKey: 'understanding_labels',
              descriptionKey: 'understanding_labels_desc',
              contentKey: 'labels',
            ),
            _buildEducationCard(
              context: context,
              icon: Icons.tips_and_updates,
              titleKey: 'healthy_tips',
              descriptionKey: 'healthy_tips_desc',
              contentKey: 'tips',
            ),
            _buildEducationCard(
              context: context,
              icon: Icons.eco,
              titleKey: 'seasonal_guide',
              descriptionKey: 'seasonal_guide_desc',
              contentKey: 'seasonal',
            ),
            _buildEducationCard(
              context: context,
              icon: Icons.recycling,
              titleKey: 'eco_packaging',
              descriptionKey: 'eco_packaging_desc',
              contentKey: 'packaging',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 