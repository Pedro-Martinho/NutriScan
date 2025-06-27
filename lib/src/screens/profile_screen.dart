import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/product_provider.dart';
import '../localization/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _buildDietaryPreferencesDialog(BuildContext context, SettingsProvider settingsProvider) {
    final l10n = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Text(l10n.translate('dietary_preferences')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: SettingsProvider.availableDiets.map((diet) {
            return CheckboxListTile(
              title: Text(l10n.translate(diet.replaceAll('-', '_'))),
              value: settingsProvider.hasDietaryPreference(diet),
              onChanged: (value) {
                settingsProvider.toggleDietaryPreference(diet);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.translate('done')),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final productProvider = context.watch<ProductProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('profile')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (authProvider.isAuthenticated && authProvider.user != null) ...[
                // User Profile Section
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: authProvider.user?.photoURL != null
                            ? NetworkImage(authProvider.user!.photoURL!)
                            : null,
                        child: authProvider.user?.photoURL == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        authProvider.user?.displayName ?? l10n.translate('anonymous'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        authProvider.user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Settings Section
              Text(
                l10n.translate('settings'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Dark Mode Toggle
              SwitchListTile(
                title: Text(l10n.translate('dark_mode')),
                value: settingsProvider.isDarkMode,
                onChanged: (value) => settingsProvider.setDarkMode(value),
              ),

              // Notifications Toggle
              SwitchListTile(
                title: Text(l10n.translate('notifications')),
                value: settingsProvider.notificationsEnabled,
                onChanged: (value) => settingsProvider.setNotificationsEnabled(value),
              ),

              // Language Selection
              ListTile(
                title: Text(l10n.translate('language')),
                subtitle: Text(settingsProvider.getLanguageName(settingsProvider.language)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Show language selection dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.translate('select_language')),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var entry in SettingsProvider.languageNames.entries)
                            ListTile(
                              title: Text(entry.value),
                              onTap: () {
                                settingsProvider.setLanguage(entry.key);
                                Navigator.pop(context);
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Theme Selection
              ListTile(
                title: Text(l10n.translate('themes')),
                subtitle: Text(l10n.translate(settingsProvider.themeColor)),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.translate('select_theme')),
                      content: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (var entry in SettingsProvider.availableThemes.entries)
                            InkWell(
                              onTap: () {
                                settingsProvider.setThemeColor(entry.key);
                                Navigator.pop(context);
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: entry.value,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: settingsProvider.themeColor == entry.key
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.translate(entry.key),
                                    style: TextStyle(
                                      fontWeight: settingsProvider.themeColor == entry.key
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Dietary Preferences
              ListTile(
                title: Text(l10n.translate('dietary_preferences')),
                subtitle: Text(
                  settingsProvider.dietaryPreferences.isEmpty
                      ? l10n.translate('none_selected')
                      : settingsProvider.dietaryPreferences
                          .map((diet) => l10n.translate(diet.replaceAll('-', '_')))
                          .join(', '),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => _buildDietaryPreferencesDialog(context, settingsProvider),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Authentication Section
              if (!authProvider.isAuthenticated)
                Center(
                  child: Column(
                    children: [
                      Text(
                        l10n.translate('sign_in_message'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: Text(l10n.translate('sign_in_with_google')),
                        onPressed: authProvider.isLoading
                            ? null
                            : () => authProvider.signInWithGoogle(
                                  settingsProvider,
                                  productProvider,
                                ),
                      ),
                    ],
                  ),
                )
              else
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.translate('sign_out')),
                    onPressed: authProvider.isLoading
                        ? null
                        : () => authProvider.signOut(
                              settingsProvider,
                              productProvider,
                            ),
                  ),
                ),

              if (authProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),

              if (authProvider.error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      authProvider.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 