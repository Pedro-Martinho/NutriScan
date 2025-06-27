import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../screens/profile_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class AppBarWithProfile extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? additionalActions;
  final Widget? leading;
  final double? scrollPosition;
  final bool isTransparent;

  const AppBarWithProfile({
    super.key,
    required this.title,
    this.additionalActions,
    this.leading,
    this.scrollPosition,
    this.isTransparent = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeColor = settings.primaryColor;
    
    // Calculate the opacity based on scroll position
    final opacity = scrollPosition != null 
        ? (scrollPosition! / 100).clamp(0.0, 1.0)
        : 1.0;
    
    // Calculate the background color
    final backgroundColor = isTransparent
        ? Colors.transparent
        : isDarkMode
            ? Color.lerp(
                Colors.transparent,
                themeColor.withOpacity(0.8),
                opacity,
              )
            : Color.lerp(
                Colors.transparent,
                themeColor.withOpacity(0.1),
                opacity,
              );

    return AppBar(
      title: Text(title),
      leading: leading,
      backgroundColor: backgroundColor,
      elevation: opacity * 2,
      actions: [
        if (additionalActions != null) ...additionalActions!,
        Consumer<AuthProvider>(
          builder: (context, auth, child) {
            final photoUrl = auth.user?.photoURL;
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: photoUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: photoUrl,
                          width: 32,
                          height: 32,
                          memCacheWidth: 64,
                          memCacheHeight: 64,
                          placeholder: (context, url) => const SizedBox(
                            width: 32,
                            height: 32,
                            child: Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.account_circle),
                        ),
                      )
                    : const Icon(Icons.account_circle),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
} 